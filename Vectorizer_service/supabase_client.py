import httpx
import os
import json
import numpy as np
import ast

SUPABASE_URL = os.getenv("SUPABASE_URL")
SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY")
BUCKET = os.getenv("SUPABASE_BUCKET", "face-images")

headers = {
    "apikey": SERVICE_KEY,
    "Authorization": f"Bearer {SERVICE_KEY}"
}

print("🔗 Supabase URL:", SUPABASE_URL)

async def upload_image_to_supabase(filename: str, content: bytes) -> str:
    async with httpx.AsyncClient() as client:
        upload_url = f"{SUPABASE_URL}/storage/v1/object/{BUCKET}/{filename}?upsert=true"

        res = await client.post(
            upload_url,
            headers={
                **headers,
                "Content-Type": "application/octet-stream"
            },
            content=content
        )

        print("📦 Upload status:", res.status_code)
        print("📦 Upload response:", res.text)

        if res.status_code not in [200, 201]:
            raise Exception("Upload failed")

        return f"{SUPABASE_URL}/storage/v1/object/public/{BUCKET}/{filename}"


async def insert_face_record(image_url, embedding, event_id, business_id):
    async with httpx.AsyncClient() as client:
        payload = {
            "image_url": image_url,
            "embedding": embedding,
            "event_id": event_id,
            "business_id": business_id
        }

        res = await client.post(
            f"{SUPABASE_URL}/rest/v1/face_images",
            headers={**headers, "Content-Type": "application/json"},
            json=payload
        )

        print("📝 Insert status:", res.status_code)
        print("📝 Insert response:", res.text)

        return res.status_code == 201


def cosine_similarity(a, b):
    a = np.array(a, dtype=np.float32)
    b = np.array(b, dtype=np.float32)
    return np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b) + 1e-10)

async def search_similar_embeddings(embedding, event_id, business_id, threshold=0.9):
    async with httpx.AsyncClient() as client:
        res = await client.get(
            f"{SUPABASE_URL}/rest/v1/face_images?event_id=eq.{event_id}&business_id=eq.{business_id}",
            headers=headers
        )

        if res.status_code != 200:
            raise Exception("Failed to fetch embeddings")

        records = res.json()

        matches = []
        for record in records:
            db_embedding = record.get("embedding")
            if not db_embedding:
                continue
        
            if isinstance(db_embedding, str):
                try:
                    db_embedding = ast.literal_eval(db_embedding)
                except Exception as e:
                    print("⚠️ Failed to parse embedding:", e)
                    continue

            query_emb = np.array(embedding, dtype=np.float32)
            db_emb = np.array(db_embedding, dtype=np.float32)

            similarity = cosine_similarity(query_emb, db_emb)
            if similarity > threshold:
                matches.append({
                    "image_url": record["image_url"],
                    "similarity": round(float(similarity), 4)
                })

        return sorted(matches, key=lambda x: -x["similarity"])
