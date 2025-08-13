from supabase import create_client
import torch
import os
from dotenv import load_dotenv
import json

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_KEY")
SUPABASE_TABLE = os.getenv("SUPABASE_BUCKET", "face_images")

supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

def fetch_all_image_embeddings():
    response = supabase.table(SUPABASE_TABLE).select("*").execute()
    data = response.data
    embeddings = []
    metadata = []

    for item in data:
        # Convert embedding string (JSON array) to list, then to tensor
        embedding_list = json.loads(item["embedding"])
        embeddings.append(torch.tensor(embedding_list))

        # Use image_url as metadata or create a dict of relevant info
        metadata.append({
            "id": item.get("id"),
            "image_url": item.get("image_url"),
            "event_id": item.get("event_id"),
            "business_id": item.get("business_id"),
            "created_at": item.get("created_at"),
        })

    return embeddings, metadata