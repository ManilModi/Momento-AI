import torch
import numpy as np
from open_clip import tokenize
from clip_interrogator import Config, Interrogator
from supabase import create_client

# Initialize CLIP
ci = Interrogator(Config(clip_model_name="ViT-L-14/openai"))
device = ci.device

# Initialize Supabase client
SUPABASE_URL = "your-supabase-url"
SUPABASE_KEY = "your-supabase-key"
supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

def fetch_all_embeddings_from_supabase():
    response = supabase.table("images").select("id, embedding, image_url").execute()
    if response.error:
        raise Exception("Failed to fetch embeddings from Supabase")

    records = response.data
    if not records:
        return np.array([]), []

    embeddings = [np.array(rec["embedding"], dtype=np.float32) for rec in records]
    urls = [rec["image_url"] for rec in records]
    embeddings_np = np.vstack(embeddings)
    return embeddings_np, urls

def search_images(prompt, top_k=5):
    text_tokens = tokenize([prompt]).to(device)
    with torch.no_grad():
        text_features = ci.clip_model.encode_text(text_tokens)
        text_features /= text_features.norm(dim=-1, keepdim=True)
        text_features = text_features.cpu().numpy().astype("float32")

    embeddings, urls = fetch_all_embeddings_from_supabase()

    if embeddings.size == 0:
        print("No embeddings found in Supabase.")
        return []

    # Normalize embeddings
    norms = np.linalg.norm(embeddings, axis=1, keepdims=True)
    embeddings_normalized = embeddings / norms

    similarities = np.dot(text_features, embeddings_normalized.T)  # (1, n)
    top_indices = similarities[0].argsort()[-top_k:][::-1]

    results = []
    for idx in top_indices:
        results.append({
            "image_url": urls[idx],
            "score": float(similarities[0][idx])
        })

    return results

if __name__ == "__main__":
    prompt = input("Enter your search prompt: ")
    results = search_images(prompt)
    print("\nSearch Results:")
    for res in results:
        print(f"URL: {res['image_url']}  Score: {res['score']}")
