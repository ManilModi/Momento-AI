# clip_text_features.py
import torch
from clip_interrogator import Config, Interrogator

# Set device
device = "cuda" if torch.cuda.is_available() else "cpu"

# Initialize CLIP Interrogator
config = Config(clip_model_name="ViT-L-14/openai")
ci = Interrogator(config)


def get_text_features(text: str) -> torch.Tensor:
    """
    Extract normalized CLIP text features from a given text prompt.

    Args:
        text (str): The text prompt or query.

    Returns:
        torch.Tensor: A normalized CLIP text embedding vector.
    """
    # Tokenize text
    tokens = ci.tokenize([text]).to(device)

    # Encode and normalize
    with torch.no_grad():
        text_features = ci.clip_model.encode_text(tokens)
        text_features /= text_features.norm(dim=-1, keepdim=True)

    return text_features.squeeze(0)  # shape: (embedding_dim,)


# if __name__ == "__main__":
#     # Example usage
#     prompt = "a red sports car on a sunny road"
#     features = get_text_features(prompt)
#     print(f"Prompt features shape: {features.shape}")
#     print(features[:10])  # preview first 10 values
