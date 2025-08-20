FROM python:3.10-slim-bullseye

ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /app

RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    curl \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

# Install PyTorch separately with CPU wheels (avoids build failures)
RUN pip install --upgrade pip && \
    pip install --no-cache-dir torch==2.0.1+cpu torchvision==0.15.2+cpu torchaudio==2.0.2+cpu -f https://download.pytorch.org/whl/cpu && \
    pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000

CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
