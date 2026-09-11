"""
Embedding Model Configuration.
"""

from dataclasses import dataclass


@dataclass
class EmbeddingConfig:
    model_name: str = "sentence-transformers/all-MiniLM-L6-v2"
    dimension: int = 384
    normalize_embeddings: bool = True
    device: str = "cpu"
    batch_size: int = 64
