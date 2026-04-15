from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from pydantic import BaseModel
from contextlib import asynccontextmanager
import httpx
import asyncpg
import os
import json
import re

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://gamepicker:gamepicker@db:5432/gamepicker")
OLLAMA_URL = os.getenv("OPENAI_BASE_URL", os.getenv("OLLAMA_URL", "http://ollama:11434"))
OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "gemma3:27b")

db_pool = None

@asynccontextmanager
async def lifespan(app):
    global db_pool
    try:
        db_pool = await asyncpg.create_pool(DATABASE_URL, min_size=2, max_size=10, timeout=5)
        try:
            init_file = "db/init.sql" if os.path.exists("db/init.sql") else "../db/init.sql"
            if os.path.exists(init_file):
                with open(init_file, "r", encoding="utf-8") as f:
                    await db_pool.execute(f.read())
        except Exception as seeder_err:
            print(f"Error seeding DB: {seeder_err}")
            
        import asyncio
        asyncio.create_task(generate_missing_embeddings())
            
    except Exception as e:
        print(f"Warning: Could not connect to DB. Running without database. Error: {e}")
        db_pool = None
    yield
    if db_pool:
        await db_pool.close()

async def get_embedding(text: str) -> list[float]:
    API_KEY = os.getenv("OPENAI_API_KEY", os.getenv("TEACHER_API_KEY", ""))
    headers = {"Authorization": f"Bearer {API_KEY}"} if API_KEY else {}
    url = f"{OLLAMA_URL}/v1/embeddings"
    payload = {"model": "bge-m3", "input": text}
    async with httpx.AsyncClient(timeout=30) as client:
        r = await client.post(url, json=payload, headers=headers)
        r.raise_for_status()
        return r.json()["data"][0]["embedding"]

async def generate_missing_embeddings():
    if not db_pool:
        return
    try:
        missing_embeds = await db_pool.fetch("SELECT id, title, description FROM games WHERE embedding IS NULL")
        if missing_embeds:
            print(f"Generating embeddings for {len(missing_embeds)} games using bge-m3...")
            for row in missing_embeds:
                text_to_embed = f"Title: {row['title']}. Description: {row['description'] or ''}"
                try:
                    emb = await get_embedding(text_to_embed)
                    await db_pool.execute("UPDATE games SET embedding = $1::vector WHERE id = $2", str(emb), row['id'])
                except Exception as emb_inner_err:
                    print(f"Failed embedding for game {row['id']}: {emb_inner_err}")
            print("Embeddings generation complete.")
    except Exception as emb_err:
        print(f"Error generating embeddings: {emb_err}")

app = FastAPI(title="Game Picker API", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

class GameRequest(BaseModel):
    description: str

class Game(BaseModel):
    title: str
    genre: str
    why: str
    platform: str

class GameResponse(BaseModel):
    games: list[Game]
    raw: str

class DBGame(BaseModel):
    id: int
    title: str
    genre: str
    platform: str
    release_year: int | None
    description: str | None
    tags: list[str]

async def fetch_similar_games(embedding: list[float], limit: int = 15):
    if not db_pool:
        return []
    rows = await db_pool.fetch("""
        SELECT v.id, v.title, v.genres AS genre, v.platform,
               v.release_year, v.description,
               COALESCE(string_to_array(v.tags, ', '), '{}') AS tags
        FROM v_games_full v
        JOIN games g ON g.id = v.id
        ORDER BY g.embedding <=> $1::vector
        LIMIT $2
    """, str(embedding), limit)
    return [dict(r) for r in rows]

async def log_search(description: str, results: list):
    if not db_pool:
        return
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


SYSTEM_PROMPT = """You are a game recommendation expert. When given a description of what a player wants from a game (mood, genre, mechanics, themes, etc.), you recommend exactly 5 games that fit.

You MUST only recommend games from the catalog below — do not invent titles.
Pick exactly 5 games from the list that best match what the player describes.

GAME CATALOG:
{catalog}

You MUST respond ONLY with a valid JSON object in this exact format, no other text:
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

@app.get("/")
async def serve_index():
    import os
    path = "frontend/index.html" if os.path.exists("frontend/index.html") else "../frontend/index.html"
    return FileResponse(path)

@app.get("/health")
async def health():
    db_ok = False
    if db_pool:
        try:
            await db_pool.fetchval("SELECT 1")
            db_ok = True
        except Exception:
            pass

    API_KEY = os.getenv("OPENAI_API_KEY", os.getenv("TEACHER_API_KEY", ""))
    headers = {"Authorization": f"Bearer {API_KEY}"} if API_KEY else {}
    endpoint = f"{OLLAMA_URL}/models" if API_KEY else f"{OLLAMA_URL}/api/tags"
    try:
        async with httpx.AsyncClient(timeout=5) as client:
            r = await client.get(endpoint, headers=headers)
            ollama_ok = r.status_code == 200
    except Exception:
        ollama_ok = False
        
    return {"status": "ok", "ollama": ollama_ok, "db": db_ok}

@app.get("/games", response_model=list[DBGame])
async def list_games(genre: str | None = None, tag: str | None = None):
    if not db_pool:
        return []
    rows = await db_pool.fetch("""
        SELECT v.id, v.title, v.genres AS genre, v.platform,
               v.release_year, v.description,
               COALESCE(string_to_array(v.tags, ', '), '{}') AS tags
        FROM v_games_full v
        WHERE ($1::text IS NULL OR lower(v.genres) LIKE '%' || lower($1) || '%')
          AND ($2::text IS NULL OR lower(v.tags) LIKE '%' || lower($2) || '%')
        ORDER BY v.title
    """, genre, tag)
    return [DBGame(**dict(r)) for r in rows]

@app.get("/genres")
async def list_genres():
    if not db_pool:
        return []
    rows = await db_pool.fetch("SELECT name FROM genres ORDER BY name")
    return [r["name"] for r in rows]

@app.get("/tags")
async def list_tags():
    if not db_pool:
        return []
    rows = await db_pool.fetch("SELECT name FROM tags ORDER BY name")
    return [r["name"] for r in rows]

@app.get("/history")
async def search_history(limit: int = 20):
    if not db_pool:
        return []
    rows = await db_pool.fetch(
        "SELECT query, result_titles, searched_at FROM search_log ORDER BY searched_at DESC LIMIT $1",
        limit
    )
    return [dict(r) for r in rows]

@app.post("/recommend", response_model=GameResponse)
async def recommend(req: GameRequest):
    if not req.description.strip():
        raise HTTPException(status_code=400, detail="Description cannot be empty")

    query_emb = []
    try:
        query_emb = await get_embedding(req.description)
    except Exception as e:
        print(f"Failed to match embeddings, using catalog fallback: {e}")

    if query_emb:
        games_db = await fetch_similar_games(query_emb, limit=15)
    else:
        # Fallback if embeddings somehow fail
        if not db_pool:
            raise HTTPException(status_code=503, detail="Database not connected.")
        rows = await db_pool.fetch("SELECT v.id, v.title, v.genres AS genre, v.platform, v.release_year, v.description, COALESCE(string_to_array(v.tags, ', '), '{}') AS tags FROM v_games_full v LIMIT 15")
        games_db = [dict(r) for r in rows]

    if not games_db and db_pool is not None:
        raise HTTPException(status_code=503, detail="Game catalog is empty — DB may not be seeded yet.")

    catalog_text = build_catalog_text(games_db) if games_db else "No catalog provided. Rely on your general knowledge to suggest games."
    system_prompt = SYSTEM_PROMPT.format(catalog=catalog_text)

    API_KEY = os.getenv("OPENAI_API_KEY", os.getenv("TEACHER_API_KEY", ""))
    headers = {"Authorization": f"Bearer {API_KEY}"} if API_KEY else {}

    payload = {
        "model": OLLAMA_MODEL,
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": req.description},
        ],
        "stream": False,
    }

    if API_KEY:
        payload["response_format"] = {"type": "json_object"}
        url = f"{OLLAMA_URL}/chat/completions"
    else:
        payload["format"] = "json"
        url = f"{OLLAMA_URL}/api/chat"

    try:
        async with httpx.AsyncClient(timeout=120) as client:
            r = await client.post(url, json=payload, headers=headers)
            r.raise_for_status()
    except httpx.HTTPStatusError as e:
        raise HTTPException(status_code=e.response.status_code, detail=f"AI API Error: {e.response.text}")
    except httpx.ConnectError:
        raise HTTPException(status_code=503, detail="Cannot connect to AI. Make sure it is running.")
    except httpx.TimeoutException:
        raise HTTPException(status_code=504, detail="AI timed out. The model may still be loading.")

    data = r.json()
    if API_KEY:
        raw_text = data.get("choices", [{}])[0].get("message", {}).get("content", "")
    else:
        raw_text = data.get("message", {}).get("content", "")

    # Try to extract JSON even if there's surrounding text
    json_match = re.search(r'\{.*\}', raw_text, re.DOTALL)
    if not json_match:
        raise HTTPException(status_code=500, detail=f"Could not parse model response: {raw_text[:200]}")

    try:
        parsed = json.loads(json_match.group())
        games_out = [Game(**g) for g in parsed.get("games", [])]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to parse game list: {str(e)}")

    try:
        await log_search(req.description, [g.title for g in games_out])
    except Exception:
        pass

    return GameResponse(games=games_out, raw=raw_text)
