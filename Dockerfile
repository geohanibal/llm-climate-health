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
RUN flutter build web --release

FROM python:3.12-slim AS backend
WORKDIR /app

COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY backend/ .
COPY --from=frontend-builder /frontend/build/web ./static

ENV PORT=8000
EXPOSE 8000
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT}"]
