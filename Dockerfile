# LLM-Climate-Health — single-container deployment.
# Builds the Flutter web frontend, then serves it together with the FastAPI
# backend from one Python process, so the whole platform lives behind one
# public URL.
#
# Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)

FROM ghcr.io/cirruslabs/flutter:stable AS frontend-builder
WORKDIR /frontend
COPY frontend/pubspec.yaml ./
RUN flutter pub get
COPY frontend/ .
# Empty BACKEND_URL makes the app call same-origin relative paths
# (e.g. /api/options) instead of the local-dev default of
# http://127.0.0.1:8000 — the frontend and backend are served from the
# same container/domain in production, so this is always correct there.
# --wasm is required by the flutter_earth_globe package's shaders (the 3D
# region-picker globe) — confirmed building cleanly on Flutter stable with
# this project's other dependencies before adopting it.
RUN flutter build web --release --wasm --dart-define=BACKEND_URL=

FROM python:3.12-slim AS backend
WORKDIR /app

COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY backend/ .
COPY --from=frontend-builder /frontend/build/web ./static

ENV PORT=8000
EXPOSE 8000
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT}"]
