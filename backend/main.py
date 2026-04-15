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
            # 1. ALWAYS CREATE TABLES SAFELY First
            await db_pool.execute("""
                CREATE EXTENSION IF NOT EXISTS vector;
                CREATE TABLE IF NOT EXISTS genres (id SERIAL PRIMARY KEY, name VARCHAR(100) NOT NULL UNIQUE);
                CREATE TABLE IF NOT EXISTS tags (id SERIAL PRIMARY KEY, name VARCHAR(100) NOT NULL UNIQUE);
                CREATE TABLE IF NOT EXISTS games (
                    id SERIAL PRIMARY KEY, title VARCHAR(200) NOT NULL UNIQUE,
                    developer VARCHAR(200), publisher VARCHAR(200), release_year INT,
                    platform VARCHAR(100), rating NUMERIC(3,1), price_usd NUMERIC(6,2),
                    description TEXT, embedding VECTOR(1024)
                );
                CREATE TABLE IF NOT EXISTS game_genres (
                    game_id INT REFERENCES games(id) ON DELETE CASCADE,
                    genre_id INT REFERENCES genres(id) ON DELETE CASCADE,
                    PRIMARY KEY (game_id, genre_id)
                );
                CREATE TABLE IF NOT EXISTS game_tags (
                    game_id INT REFERENCES games(id) ON DELETE CASCADE,
                    tag_id INT REFERENCES tags(id) ON DELETE CASCADE,
                    PRIMARY KEY (game_id, tag_id)
                );
                CREATE TABLE IF NOT EXISTS search_log (
                    id SERIAL PRIMARY KEY, query TEXT NOT NULL, result_titles TEXT[],
                    searched_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                );
                CREATE OR REPLACE VIEW v_games_full AS
                SELECT g.id, g.title, g.developer, g.publisher, g.release_year, g.platform, g.rating, g.price_usd, g.description,
                    STRING_AGG(DISTINCT gn.name, ', ' ORDER BY gn.name) AS genres,
                    STRING_AGG(DISTINCT t.name,  ', ' ORDER BY t.name)  AS tags
                FROM games g
                LEFT JOIN game_genres gg ON g.id = gg.game_id
                LEFT JOIN genres gn ON gg.genre_id = gn.id
                LEFT JOIN game_tags gt ON g.id = gt.game_id
                LEFT JOIN tags t ON gt.tag_id = t.id
                GROUP BY g.id ORDER BY g.rating DESC, g.title;
            """)

            # 2. SEED FROM JSON IF EMPTY OR NEW GAMES FOUND
            json_file = "db/games.json" if os.path.exists("db/games.json") else "../db/games.json"
            if os.path.exists(json_file):
                with open(json_file, "r", encoding="utf-8") as f:
                    games_data = json.load(f)
                    
                for g in games_data:
                    # Insert game
                    await db_pool.execute('''
                        INSERT INTO games (title, developer, publisher, release_year, platform, rating, price_usd, description)
                        VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
                        ON CONFLICT (title) DO NOTHING
                    ''', g["title"], g["developer"], g["publisher"], g["release_year"], g["platform"], float(g["rating"]), float(g["price_usd"]), g["description"])
                    
                    # Insert genres
                    for genre in g.get("genres", []):
                        await db_pool.execute("INSERT INTO genres (name) VALUES ($1) ON CONFLICT (name) DO NOTHING", genre)
                        await db_pool.execute('''
                            INSERT INTO game_genres (game_id, genre_id)
                            SELECT games.id, genres.id FROM games, genres
                            WHERE games.title = $1 AND genres.name = $2
                            ON CONFLICT DO NOTHING
                        ''', g["title"], genre)
                        
                    # Insert tags
                    for tag in g.get("tags", []):
                        await db_pool.execute("INSERT INTO tags (name) VALUES ($1) ON CONFLICT (name) DO NOTHING", tag)
                        await db_pool.execute('''
                            INSERT INTO game_tags (game_id, tag_id)
                            SELECT games.id, tags.id FROM games, tags
                            WHERE games.title = $1 AND tags.name = $2
                            ON CONFLICT DO NOTHING
                        ''', g["title"], tag)
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
    model = os.getenv("EMBEDDING_MODEL", "text-embedding-3-small" if API_KEY else "nomic-embed-text")
    payload = {"model": model, "input": text}
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
        WHERE g.embedding IS NOT NULL
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
    try:
        if not req.description.strip():
            raise HTTPException(status_code=400, detail="Description cannot be empty")

        query_emb = []
        try:
            query_emb = await get_embedding(req.description)
        except Exception as e:
            print(f"Failed to match embeddings, using catalog fallback: {e}")

        games_db = []
        if query_emb:
            games_db = await fetch_similar_games(query_emb, limit=15)
            
        # Robust Hybrid Fallback: If embeddings are missing/broken, backfill with text search
        if len(games_db) < 15 and db_pool is not None:
            words = [w for w in req.description.replace(',', ' ').split() if len(w) > 3][:6]
            where_clauses = " OR ".join([f"v.description ILIKE '%{w}%' OR v.genres ILIKE '%{w}%' OR v.tags ILIKE '%{w}%'" for w in words])
            
            query = """
                SELECT v.id, v.title, v.genres AS genre, v.platform,
                       v.release_year, v.description,
                       COALESCE(string_to_array(v.tags, ', '), '{}') AS tags
                FROM v_games_full v 
            """
            if where_clauses:
                query += f"WHERE {where_clauses} "
            query += "ORDER BY RANDOM() LIMIT 20"
            
            try:
                rows = await db_pool.fetch(query)
                existing_ids = {g['id'] for g in games_db}
                for r in rows:
                    if r['id'] not in existing_ids:
                        games_db.append(dict(r))
                        existing_ids.add(r['id'])
            except Exception as search_err:
                print(f"Keyword search fallback failed: {search_err}")

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

        json_match = re.search(r'\{.*\}', raw_text, re.DOTALL)
        if not json_match:
            raise HTTPException(status_code=500, detail=f"Could not parse model response: {raw_text[:200]}")

        parsed = json.loads(json_match.group())
        ai_games = parsed.get("games", [])
        games_out = []
        for g in ai_games:
            title = g.get('title', '')
            db_game = next((db_g for db_g in games_db if db_g['title'].lower() == title.lower()), None)
            if db_game:
                games_out.append(Game(
                    title=db_game['title'],
                    genre=db_game['genre'] or g.get('genre', ''),
                    why=g.get('why', ''),
                    platform=db_game['platform'] or g.get('platform', '')
                ))

        try:
            await log_search(req.description, [g.title for g in games_out])
        except Exception as log_err:
            print(f"Search log error: {log_err}")

        return GameResponse(games=games_out, raw=raw_text)

    except HTTPException:
        raise
    except Exception as general_err:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Server completely crashed: {str(general_err)}")
