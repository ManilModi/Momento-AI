from fastapi import FastAPI, File, UploadFile, Form, HTTPException, Query
from insightface.app import FaceAnalysis
import numpy as np
import cv2
import uuid
import traceback
from supabase_client import (
    insert_face_record,
    search_similar_embeddings
)
# from s3_client import upload_image_to_s3
from supabase_client import upload_image_to_supabase
import torch
from open_clip import tokenize
from clip_interrogator import Config, Interrogator
from supabase import create_client
import os
from sentence_transformers import SentenceTransformer
import clip
from PIL import Image
import io

app = FastAPI()
face_app = FaceAnalysis(name='buffalo_l', providers=['CPUExecutionProvider'])
face_app.prepare(ctx_id=0)

# Initialize CLIP Interrogator for text-to-image search
ci = Interrogator(Config(clip_model_name="ViT-L-14/openai"))
device = ci.device

embedding_model = SentenceTransformer("clip-ViT-B-32")

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_KEY")
SUPABASE_TABLE = os.getenv("SUPABASE_BUCKET", "face-images")
supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

from typing import Tuple, List
import numpy as np
from fastapi import HTTPException

import json

def fetch_all_embeddings_from_supabase() -> Tuple[np.ndarray, List[str]]:
    """
    Fetch embeddings and URLs from Supabase
    """
    response = supabase.table(SUPABASE_TABLE).select("embedding, image_url").execute()

    data = response.data
    if not data or len(data) == 0:
        raise HTTPException(status_code=404, detail="No embeddings found in Supabase")

    embeddings = []
    urls = []
    for row in data:
        embedding_raw = row["embedding"]

        # Ensure the embedding is a list of floats
        if isinstance(embedding_raw, str):
            embedding_list = json.loads(embedding_raw)
        else:
            embedding_list = embedding_raw

        embeddings.append(np.array(embedding_list, dtype=np.float32))
        urls.append(row["image_url"])

    return np.vstack(embeddings), urls


clip_device = "cuda" if torch.cuda.is_available() else "cpu"
clip_model, clip_preprocess = clip.load("ViT-B/32", device=clip_device)

def generate_clip_embedding(image_bytes: bytes):
    """Generate normalized CLIP embedding for an image."""
    image = clip_preprocess(Image.open(io.BytesIO(image_bytes))).unsqueeze(0).to(clip_device)
    with torch.no_grad():
        embedding = clip_model.encode_image(image)
    embedding /= embedding.norm(dim=-1, keepdim=True)  # Normalize
    return embedding.cpu().numpy().flatten().tolist()

def cosine_similarity(a: np.ndarray, b: np.ndarray) -> float:
    return np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b))


@app.post("/vectorize")
async def vectorize_image(
        file: UploadFile = File(...),
        event_id: str = Form(...),
        business_id: str = Form(...)
):
    try:
        content = await file.read()
        if not isinstance(content, (bytes, bytearray)):
            raise ValueError("File content is not bytes")

        # Upload image to Supabase storage
        filename = f"{uuid.uuid4()}.jpg"
        image_url = await upload_image_to_supabase(filename, content)

        # Get InsightFace embeddings
        img = cv2.imdecode(np.frombuffer(content, np.uint8), cv2.IMREAD_COLOR)
        faces = face_app.get(img)

        if not faces:
            return {"message": "No face detected."}

        # Generate CLIP embedding for the image
        clip_embedding = generate_clip_embedding(content)
        if not isinstance(clip_embedding, list):
            clip_embedding = clip_embedding.tolist()

        results = []
        for idx, face in enumerate(faces):
            face_embedding = face.embedding.tolist()

            # Insert record into Supabase with both embeddings
            success = await insert_face_record(
                image_url=image_url,
                embedding=face_embedding,
                event_id=event_id,
                business_id=business_id,
                clip_embedding=clip_embedding  # NEW FIELD
            )

            results.append({
                "face_index": idx,
                "embedding_saved": success,
                "image_url": image_url
            })

        return {
            "status": "completed",
            "total_faces": len(faces),
            "results": results
        }

    except Exception as e:
        print("🔥 Exception occurred:", str(e))
        traceback.print_exc()
        return {"error": "Internal Server Error", "detail": str(e)}


@app.post("/find-face")
async def find_matching_group_image(
        file: UploadFile = File(...),
        event_id: str = Form(...),
        business_id: str = Form(...)
):
    try:
        content = await file.read()
        img = cv2.imdecode(np.frombuffer(content, np.uint8), cv2.IMREAD_COLOR)

        faces = face_app.get(img)
        if not faces:
            raise HTTPException(status_code=404, detail="No face detected")

        embedding = faces[0].embedding.tolist()
        filename = f"{uuid.uuid4()}.jpg"
        uploaded_url =  await upload_image_to_supabase(filename, content)

        matches = await search_similar_embeddings(
            embedding, event_id, business_id, threshold=0.6
        )

        return {
            "uploaded_image_url": uploaded_url,
            "matched_images": matches
        }

    except Exception as e:
        print("🔥 Exception occurred:", str(e))
        traceback.print_exc()
        return {"error": "Internal Server Error", "detail": str(e)}

@app.get("/search")
def search_images(prompt: str = Query(...), top_k: int = Query(5)):
    try:
        # Encode text with the SAME model used for images
        text_tokens = clip.tokenize([prompt]).to(device)
        with torch.no_grad():
            prompt_embedding = clip_model.encode_text(text_tokens).cpu().numpy().flatten()

        # Fetch CLIP embeddings
        response = supabase.table(SUPABASE_TABLE).select("clip_embedding, image_url").execute()
        data = response.data
        if not data:
            raise HTTPException(status_code=404, detail="No embeddings found")

        embeddings = []
        urls = []
        for row in data:
            emb_raw = row["clip_embedding"]  # <-- match column name here
            if isinstance(emb_raw, str):
                emb_list = json.loads(emb_raw)
            else:
                emb_list = emb_raw
            arr = np.array(emb_list, dtype=np.float32).flatten()
            if arr.shape == (512,):  # ensure correct size
                embeddings.append(arr)
                urls.append(row["image_url"])

        if not embeddings:
            raise HTTPException(status_code=500, detail="No valid embeddings found")

        embeddings = np.vstack(embeddings)
        sims = [cosine_similarity(prompt_embedding, e) for e in embeddings]
        top_indices = np.argsort(sims)[::-1][:top_k]
        results = [{"url": urls[i], "score": float(sims[i])} for i in top_indices]

        return {"results": results}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/event-images")
async def get_event_images(event_id: str = Query(...), business_id: str = Query(...)):
    """
    Fetch all images for a specific event and business.
    """
    try:
        response = supabase.table(SUPABASE_TABLE) \
            .select("image_url") \
            .eq("event_id", event_id) \
            .eq("business_id", business_id) \
            .execute()

        data = response.data
        if not data:
            raise HTTPException(status_code=404, detail="No images found for this event")

        image_urls = [row["image_url"] for row in data]

        return {"event_id": event_id, "business_id": business_id, "images": image_urls}

    except Exception as e:
        print("🔥 Exception occurred:", str(e))
        traceback.print_exc()
        raise HTTPException(status_code=500, detail="Internal Server Error")
