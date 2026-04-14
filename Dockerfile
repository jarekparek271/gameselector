FROM python:3.11-slim
WORKDIR /app

# Install dependencies
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy backend logic and frontend static files
COPY backend/ backend/
COPY frontend/ frontend/
COPY db/ db/

# Expose port (PaaS environments typically use 80, 8080 or pass PORT env var)
EXPOSE 8080

# Start backend (which now also serves the frontend on the root path)
CMD sh -c "uvicorn backend.main:app --host 0.0.0.0 --port ${PORT:-8080}"
