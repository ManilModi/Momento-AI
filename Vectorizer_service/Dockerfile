FROM python:3.10-slim-bullseye AS builder

ENV DEBIAN_FRONTEND=noninteractive
ENV TRANSFORMERS_CACHE=/root/.cache/huggingface
ENV SENTENCE_TRANSFORMERS_HOME=/root/.cache/sentence-transformers
ENV HF_HOME=/root/.cache/huggingface

WORKDIR /app

RUN apt-get update && apt-get install -y \
    build-essential git curl unzip && \
    rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

RUN python -m pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

COPY . .

RUN set -eux; \
    mkdir -p /root/.insightface/models && \
    curl -L -o /root/.insightface/models/buffalo_l.zip \
        https://github.com/deepinsight/insightface/releases/download/v0.7/buffalo_l.zip && \
    unzip /root/.insightface/models/buffalo_l.zip -d /root/.insightface/models/ && \
    rm /root/.insightface/models/buffalo_l.zip; \
    \
    python -c "from sentence_transformers import SentenceTransformer; SentenceTransformer('clip-ViT-B-32')"; \
    \
    python -c "import clip; clip.load('ViT-B/32', device='cpu')"; \
    \
    python -c "from clip_interrogator import Config, Interrogator; Interrogator(Config(clip_model_name='ViT-L-14/openai'))"


FROM python:3.10-slim-bullseye

ENV TRANSFORMERS_CACHE=/root/.cache/huggingface
ENV SENTENCE_TRANSFORMERS_HOME=/root/.cache/sentence-transformers
ENV HF_HOME=/root/.cache/huggingface

WORKDIR /app

COPY --from=builder /usr/local /usr/local

COPY --from=builder /app /app

COPY --from=builder /root/.insightface /root/.insightface
COPY --from=builder /root/.cache /root/.cache

EXPOSE 8080

CMD ["sh", "-c", "uvicorn app:app --host 0.0.0.0 --port ${PORT:-8080}"]
