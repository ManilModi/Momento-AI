from fastapi import FastAPI, File, UploadFile, Form, HTTPException
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

app = FastAPI()
face_app = FaceAnalysis(name='buffalo_l', providers=['CPUExecutionProvider'])
face_app.prepare(ctx_id=0)

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

        filename = f"{uuid.uuid4()}.jpg"
        image_url = await upload_image_to_supabase(filename, content)

        img = cv2.imdecode(np.frombuffer(content, np.uint8), cv2.IMREAD_COLOR)
        faces = face_app.get(img)

        if not faces:
            return {"message": "No face detected."}

        results = []
        for idx, face in enumerate(faces):
            embedding = face.embedding.tolist()
            success = await insert_face_record(image_url, embedding, event_id, business_id)
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
