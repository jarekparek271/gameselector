# 🎮 Game Picker AI

An AI-powered game recommendation app using Ollama (local LLM), FastAPI, and a retro-styled frontend — fully containerized with Docker.

## Architecture

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Frontend   │────▶│   Backend   │────▶│   Ollama    │
│ nginx:3000  │     │ FastAPI:8000│     │  LLM:11434  │
└─────────────┘     └─────────────┘     └─────────────┘
```

## Quick Start

### 1. Start all services

```bash
docker compose up -d --build
```

### 2. Pull the AI model (first time only)

```bash
docker exec game-picker-ollama ollama pull llama3.2
```

> This downloads ~2GB. Wait for it to complete before using the app.

### 3. Open the app

```
http://localhost:3000
```

---

## Changing the Model

Edit `docker-compose.yml` and change `OLLAMA_MODEL`:

```yaml
environment:
  OLLAMA_MODEL: llama3.2        # default, fast
  # OLLAMA_MODEL: mistral       # good alternative
  # OLLAMA_MODEL: gemma2        # Google's model
  # OLLAMA_MODEL: llama3.1:8b  # larger, slower but better
```

Then pull the new model:
```bash
docker exec game-picker-ollama ollama pull <model-name>
docker compose restart backend
```

## GPU Acceleration (NVIDIA)

1. Install [nvidia-container-toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html)
2. Uncomment the `deploy` block in `docker-compose.yml` under the `ollama` service
3. `docker compose up -d --build`

## Useful Commands

```bash
# View logs
docker compose logs -f

# Check Ollama models available
docker exec game-picker-ollama ollama list

# Stop everything
docker compose down

# Stop and remove volumes (deletes downloaded models!)
docker compose down -v
```

## API

The backend exposes:

- `GET /health` — check connectivity to Ollama
- `POST /recommend` — get game recommendations
  ```json
  { "description": "relaxing open world with a great story" }
  ```
