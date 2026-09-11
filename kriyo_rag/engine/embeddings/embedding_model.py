"""
SentenceTransformer Embedding Model Wrapper.
"""

from typing import List, Union, Optional, Any
from .model_config import EmbeddingConfig


class EmbeddingModel:
    _instance = None
    _model: Any = None

    def __init__(self, config: Optional[EmbeddingConfig] = None):
        self.config = config or EmbeddingConfig()
        self._load_model()

    def _load_model(self):
        if EmbeddingModel._model is None:
            try:
                from sentence_transformers import SentenceTransformer  # type: ignore
                print(f"[*] Initializing Embedding Model: {self.config.model_name}")
                EmbeddingModel._model = SentenceTransformer(
                    self.config.model_name,
                    device=self.config.device
                )
            except ImportError:
                EmbeddingModel._model = None

    @property
    def model(self) -> Any:
        if EmbeddingModel._model is None:
            self._load_model()
        if EmbeddingModel._model is None:
            raise RuntimeError("sentence-transformers package is required to generate embeddings.")
        return EmbeddingModel._model

    def encode(self, texts: Union[str, List[str]], show_progress_bar: bool = False) -> List[List[float]]:
        """
        Generates normalized embedding vectors.
        """
        is_single = isinstance(texts, str)
        inp = [texts] if is_single else texts
        embeddings = self.model.encode(
            inp,
            batch_size=self.config.batch_size,
            show_progress_bar=show_progress_bar,
            normalize_embeddings=self.config.normalize_embeddings
        )
        return embeddings.tolist()

    def encode_query(self, query: str) -> List[float]:
        return self.encode(query)[0]
