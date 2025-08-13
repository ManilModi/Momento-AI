import os
from clip_interrogator import Config, Interrogator
from supabase import create_client, Client

# Load environment variables for Supabase
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")

# Initialize Supabase client
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# Initialize CLIP Interrogator
ci = Interrogator(Config(clip_model_name="ViT-L-14/openai"))
device = ci.device
preprocess = ci.clip_preprocess
