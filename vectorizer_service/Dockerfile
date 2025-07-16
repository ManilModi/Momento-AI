FROM python:3.10-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential cmake git curl \
    libgl1-mesa-glx libglib2.0-0 && \
    apt-get clean

# Copy files
COPY requirements.txt .

# Use a compatible numpy
RUN pip install --upgrade pip && pip install --no-cache-dir -r requirements.txt

# Copy code
COPY . .

CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
