# 🧠 Momento AI 

## 1. Introduction

### 1.1 Purpose
Momento AI is a smart **event management and photo retrieval system** designed for photographers, clients, and admins.  
It allows photographers to upload event photos, which clients can later access via event IDs, facial recognition, or natural language descriptions.

### 1.2 Scope
- Multi-role system: Photographer, Client, Admin  
- Image upload and retrieval for events  
- Face-based photo retrieval via uploaded selfies  
- Object/text-based photo search using CLIP embeddings and NLP  
- Integration with cloud storage and vector DB  
- Scalable backend for AI services  

### 1.3 Definitions

| Term | Definition |
|------|-------------|
| **AWS S3 Bucket** | Amazon Simple Storage Service for storing images |
| **Pgvector** | PostgreSQL extension for storing and searching vector embeddings |
| **Supabase** | Backend-as-a-service with vector database support |
| **CLIP** | Contrastive Language–Image Pre-training Model |
| **Embedding** | Numerical vector representation of an image or text |

---

## 2. Overall Description

### 2.1 Product Perspective
Momento AI is a **Python-based application** with a FastAPI backend.  
It integrates with Supabase and AI models (InsightFace, CLIP) to provide advanced photo management and retrieval capabilities.

### 2.2 Product Functions
- User authentication and role-based access control  
- Event creation and image upload by photographers  
- Face embedding generation and vector DB insertion  
- Image search using facial similarity  
- Text/NLP-based image search using CLIP embeddings  
- Admin control over users and events  

### 2.3 User Classes and Characteristics

| User Role | Description |
|------------|--------------|
| **Photographer** | Uploads event photos with business ID |
| **Client** | Accesses photos using event ID or AI search |
| **Admin** | Manages users and monitors activity |

### 2.4 Operating Environment
- **Backend**: Python (FastAPI)  
- **Storage**: AWS S3 / Supabase Storage  
- **Database**: Supabase / PostgreSQL with Pgvector  
- **Deployment**: Docker + Cloud Run  

---

## 3. System Features

### 3.1 User Management
- Register/Login (email/password, OTP)  
- Role assignment: Photographer, Client, Admin  
- Profile update  

### 3.2 Event Management
- Photographer creates a new public or private event  
- Assigns clients via event ID  
- Uploads photos to each event  

### 3.3 Photo Upload
- Store photo in Supabase / S3  
- On upload:  
  - Detect and extract face embeddings  
  - Generate object and CLIP embeddings  
  - Save image metadata in Supabase  
  - Insert embeddings into the vector DB  

### 3.4 Face-Based Search
- Client uploads a selfie or image  
- System encodes the image using InsightFace  
- Compares embeddings with database  
- Returns top-matching photos  

### 3.5 NLP-Based Image Retrieval
- Client searches with natural text prompts (e.g., “red dress”, “birthday party”)  
- Query encoded using CLIP text encoder  
- Return top-K similar images based on vector similarity  

### 3.6 Admin Panel
- View/manage all users  
- Moderate events and uploaded media  
- Delete inappropriate content  
- Monitor logs and usage statistics  

---

## 4. External Interfaces

### 4.1 User Interfaces
- FastAPI-based RESTful endpoints  
- Python SDK (`momentoai`) for developer integration  

### 4.2 Hardware Interfaces
- Works on any system capable of running Dockerized FastAPI  

### 4.3 Software Interfaces
- **Supabase/PostgreSQL SDKs** for data and vector storage  
- **Face detection models**: InsightFace  
- **Embedding models**: CLIP (SentenceTransformers / OpenCLIP)  
- **REST API** communication via HTTPS  

### 4.4 Communication Interfaces
- RESTful APIs between backend and SDK  
- JSON-based request and response models  

---

## 5. Non-Functional Requirements

### 5.1 Performance Requirements
- Face search response time < 3 seconds  
- Text-based image retrieval < 4 seconds  
- Upload latency < 1 second per image  

### 5.2 Security Requirements
- JWT authentication  
- RBAC (Role-Based Access Control)  
- Secure Supabase access via signed URLs  
- Embeddings encrypted in transit  

### 5.3 Reliability & Availability
- 99.9% uptime target  
- Daily backups for embeddings and metadata  

### 5.4 Maintainability
- Modular, service-oriented architecture  
- Dockerized backend  
- Supports CI/CD deployment pipelines  

---

## 6. AI Pipelines

### On Upload:
1. Detect faces → extract embeddings → insert into `face_embeddings`  
2. Generate CLIP image embeddings → insert into `clip_embeddings`  
3. Store object labels and metadata  

### On Search:
- **Face Search**: Encode selfie → cosine similarity → return top results  
- **Text Search**: Encode query with CLIP → cosine similarity with stored image embeddings  

---

## 7. Glossary

| Term | Meaning |
|------|----------|
| **Event ID** | Unique identifier for each event |
| **Business ID** | Unique identifier for each photographer |
| **Embedding** | Vector representation of image/text features |
| **Vector Search** | Similarity-based retrieval using embeddings |
| **CLIP** | Model that connects text and visual representations |

---

## 🧩 Momento AI SDK Integration Overview

MomentoAI SDK lets developers integrate these capabilities into their own applications.

### Example:

```python
from MomentoAI import MomentoAIClient

client = MomentoAIClient(
    api_key="public-access",
    api_url="https://momento-ai-1-42230574747.asia-south1.run.app",
    supabase_url="https://yourproject.supabase.co",
    supabase_service_key="YOUR_SUPABASE_SERVICE_KEY",
    supabase_bucket="face-images"
)

# Upload and vectorize
client.vectorize_image("photo.jpg", event_id="event1", business_id="b1")

# Search via text
client.search_images(prompt="bride in red saree", event_id="event1", business_id="b1")

# Find similar faces
client.find_face("selfie.jpg", event_id="event1", business_id="b1")

