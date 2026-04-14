from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from contextlib import asynccontextmanager
import httpx
import asyncpg
import os
import json
import re

# ── Config ────────────────────────────────────────────────────────────────────
OLLAMA_URL   = os.getenv("OLLAMA_URL",   "http://ollama:11434")
OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "llama3.2")
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://gamepicker:gamepicker@db:5432/gamepicker")

# ── DB pool ───────────────────────────────────────────────────────────────────
db_pool = None

@asynccontextmanager
async def lifespan(app):
    global db_pool
    db_pool = await asyncpg.create_pool(DATABASE_URL, min_size=2, max_size=10)
    yield
    await db_pool.close()

app = FastAPI(title="Game Picker API", lifespan=lifespan)
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

# ── Models ────────────────────────────────────────────────────────────────────
class GameRequest(BaseModel):
    description: str

class Game(BaseModel):
    title: str
    genre: str
    why: str
    platform: str

class GameResponse(BaseModel):
    games: list[Game]

class DBGame(BaseModel):
    id: int
    title: str
    genre: str
    platform: str
    release_year: int | None
    description: str | None
    tags: list[str]

# ── DB helpers ────────────────────────────────────────────────────────────────
async def fetch_all_games():
    rows = await db_pool.fetch("""
        SELECT g.id, g.title, gr.name AS genre, g.platform,
               g.release_year, g.description,
               COALESCE(array_agg(t.name ORDER BY t.name)
                        FILTER (WHERE t.name IS NOT NULL), '{}') AS tags
        FROM games g
        JOIN genres gr ON gr.id = g.genre_id
        LEFT JOIN game_tags gt ON gt.game_id = g.id
        LEFT JOIN tags t       ON t.id = gt.tag_id
        GROUP BY g.id, gr.name ORDER BY g.title
    """)
    return [dict(r) for r in rows]

async def log_search(description: str, results: list):
    await db_pool.execute(
        "INSERT INTO search_log (query, result_titles) VALUES ($1, $2)",
        description, results
    )

def build_catalog_text(games: list) -> str:
    lines = []
    for g in games:
        tags = ", ".join(g["tags"]) if g["tags"] else "no tags"
        year = g["release_year"] or "unknown year"
        desc = f' | {g["description"]}' if g["description"] else ""
        lines.append(f'- {g["title"]} ({g["genre"]}, {g["platform"]}, {year}) | tags: {tags}{desc}')
    return "\n".join(lines)

SYSTEM_PROMPT_TEMPLATE = """You are a game recommendation expert.
You MUST only recommend games from the catalog below — do not invent titles.
Pick exactly 5 games from the list that best match what the player describes.

GAME CATALOG:
{catalog}

Respond ONLY with a valid JSON object, no other text:
{{
  "games": [
    {{
      "title": "Exact title from catalog",
      "genre": "Genre from catalog",
      "why": "One sentence why this fits the request.",
      "platform": "Platform from catalog"
    }}
  ]
}}"""

# ── Routes ────────────────────────────────────────────────────────────────────
@app.get("/health")
async def health():
    db_ok = False
    try:
        await db_pool.fetchval("SELECT 1")
        db_ok = True
    except Exception:
        pass
    ollama_ok = False
    try:
        async with httpx.AsyncClient(timeout=5) as client:
            r = await client.get(f"{OLLAMA_URL}/api/tags")
            ollama_ok = r.status_code == 200
    except Exception:
        pass
    return {"status": "ok", "ollama": ollama_ok, "db": db_ok}

@app.get("/games", response_model=list[DBGame])
async def list_games(genre: str | None = None, tag: str | None = None):
    rows = await db_pool.fetch("""
        SELECT g.id, g.title, gr.name AS genre, g.platform,
               g.release_year, g.description,
               COALESCE(array_agg(t.name ORDER BY t.name)
                        FILTER (WHERE t.name IS NOT NULL), '{}') AS tags
        FROM games g
        JOIN genres gr ON gr.id = g.genre_id
        LEFT JOIN game_tags gt ON gt.game_id = g.id
        LEFT JOIN tags t       ON t.id = gt.tag_id
        WHERE ($1::text IS NULL OR lower(gr.name) = lower($1))
          AND ($2::text IS NULL OR g.id IN (
                SELECT gt2.game_id FROM game_tags gt2
                JOIN tags t2 ON t2.id = gt2.tag_id
                WHERE lower(t2.name) = lower($2)))
        GROUP BY g.id, gr.name ORDER BY g.title
    """, genre, tag)
    return [DBGame(**dict(r)) for r in rows]

@app.get("/genres")
async def list_genres():
    rows = await db_pool.fetch("SELECT name FROM genres ORDER BY name")
    return [r["name"] for r in rows]

@app.get("/tags")
async def list_tags():
    rows = await db_pool.fetch("SELECT name FROM tags ORDER BY name")
    return [r["name"] for r in rows]

@app.post("/recommend", response_model=GameResponse)
async def recommend(req: GameRequest):
    if not req.description.strip():
        raise HTTPException(status_code=400, detail="Description cannot be empty")

    games = await fetch_all_games()
    if not games:
        raise HTTPException(status_code=503, detail="Game catalog is empty — DB may not be seeded yet.")

    system_prompt = SYSTEM_PROMPT_TEMPLATE.format(catalog=build_catalog_text(games))
    payload = {
        "model": OLLAMA_MODEL,
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user",   "content": req.description},
        ],
        "stream": False,
        "format": "json",
    }

    try:
        async with httpx.AsyncClient(timeout=120) as client:
            r = await client.post(f"{OLLAMA_URL}/api/chat", json=payload)
            r.raise_for_status()
    except httpx.ConnectError:
        raise HTTPException(status_code=503, detail="Cannot connect to Ollama.")
    except httpx.TimeoutException:
        raise HTTPException(status_code=504, detail="Ollama timed out — model may still be loading.")

    raw_text = r.json().get("message", {}).get("content", "")
    json_match = re.search(r'\{.*\}', raw_text, re.DOTALL)
    if not json_match:
        raise HTTPException(status_code=500, detail=f"Could not parse model response: {raw_text[:200]}")

    try:
        parsed = json.loads(json_match.group())
        games_out = [Game(**g) for g in parsed.get("games", [])]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to parse game list: {e}")

    try:
        await log_search(req.description, [g.title for g in games_out])
    except Exception:
        pass

    return GameResponse(games=games_out)

@app.get("/history")
async def search_history(limit: int = 20):
    rows = await db_pool.fetch(
        "SELECT query, result_titles, searched_at FROM search_log ORDER BY searched_at DESC LIMIT $1",
        limit
    )
    return [dict(r) for r in rows]
