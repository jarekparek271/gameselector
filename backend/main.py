from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from pydantic import BaseModel
import httpx
import os
import json
import re

app = FastAPI(title="Game Picker API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

OLLAMA_URL = os.getenv("OLLAMA_URL", "http://ollama:11434")
OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "llama3.2")


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


SYSTEM_PROMPT = """You are a game recommendation expert. When given a description of what a player wants from a game (mood, genre, mechanics, themes, etc.), you recommend exactly 5 games that fit.

You MUST respond ONLY with a valid JSON object in this exact format, no other text:
{
  "games": [
    {
      "title": "Game Title",
      "genre": "Genre",
      "why": "One sentence explaining why this fits the request.",
      "platform": "PC / Console / Both"
    }
  ]
}"""


@app.get("/")
async def serve_index():
    import os
    # Serve from the unified Docker container structure if it exists, otherwise local DEV structure
    path = "frontend/index.html" if os.path.exists("frontend/index.html") else "../frontend/index.html"
    return FileResponse(path)

@app.get("/health")
async def health():
    try:
        async with httpx.AsyncClient(timeout=5) as client:
            r = await client.get(f"{OLLAMA_URL}/api/tags")
            return {"status": "ok", "ollama": r.status_code == 200}
    except Exception:
        return {"status": "ok", "ollama": False}


@app.post("/recommend", response_model=GameResponse)
async def recommend(req: GameRequest):
    if not req.description.strip():
        raise HTTPException(status_code=400, detail="Description cannot be empty")

    payload = {
        "model": OLLAMA_MODEL,
        "messages": [
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": req.description},
        ],
        "stream": False,
        "format": "json",
    }

    try:
        async with httpx.AsyncClient(timeout=120) as client:
            r = await client.post(f"{OLLAMA_URL}/api/chat", json=payload)
            r.raise_for_status()
    except httpx.ConnectError:
        raise HTTPException(status_code=503, detail="Cannot connect to Ollama. Make sure it is running.")
    except httpx.TimeoutException:
        raise HTTPException(status_code=504, detail="Ollama timed out. The model may still be loading.")

    data = r.json()
    raw_text = data.get("message", {}).get("content", "")

    # Try to extract JSON even if there's surrounding text
    json_match = re.search(r'\{.*\}', raw_text, re.DOTALL)
    if not json_match:
        raise HTTPException(status_code=500, detail=f"Could not parse model response: {raw_text[:200]}")

    try:
        parsed = json.loads(json_match.group())
        games = [Game(**g) for g in parsed.get("games", [])]
        return GameResponse(games=games, raw=raw_text)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to parse game list: {str(e)}")
