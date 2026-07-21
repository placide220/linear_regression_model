FROM python:3.11-slim

WORKDIR /app

# system deps needed to build any remaining wheels cleanly (kept minimal)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

COPY . .

# Render provides $PORT at runtime; default to 8000 for local `docker run`
ENV PORT=8000
EXPOSE 8000

CMD ["sh", "-c", "uvicorn prediction:app --host 0.0.0.0 --port ${PORT}"]
