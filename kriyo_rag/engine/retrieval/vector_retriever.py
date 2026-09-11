"""
Dense Vector Similarity Retriever using ChromaDB.
"""

import os
from typing import List, Dict, Any, Optional
try:
    import chromadb  # type: ignore
except ImportError:
    chromadb = None  # type: ignore

from ..embeddings.embedding_model import EmbeddingModel
from ...config.settings import settings


class VectorRetriever:
    def __init__(
        self,
        index_dir: Optional[str] = None,
        collection_name: Optional[str] = None,
        embedding_model: Optional[EmbeddingModel] = None
    ):
        self.index_dir = str(index_dir or settings.INDEX_DIR)
        self.chroma_db_dir = os.path.join(self.index_dir, "chroma_db")
        self.collection_name = collection_name or settings.COLLECTION_NAME
        self.embedding_model = embedding_model or EmbeddingModel()

        if chromadb is None:
            self.client = None
            self.collection = None
            return

        self.client = chromadb.PersistentClient(path=self.chroma_db_dir)
        try:
            self.collection = self.client.get_collection(name=self.collection_name)
        except Exception:
            self.collection = self.client.get_or_create_collection(
                name=self.collection_name,
                metadata={"hnsw:space": "cosine"}
            )

    def search(self, query: str, top_k: int = 8, where_filter: Optional[Dict[str, Any]] = None) -> List[Dict[str, Any]]:
        if self.collection is None:
            return []
        query_vector = self.embedding_model.encode_query(query)
        kwargs: Dict[str, Any] = {
            "query_embeddings": [query_vector],
            "n_results": top_k,
            "include": ["documents", "metadatas", "distances"]
        }
        if where_filter:
            kwargs["where"] = where_filter

        raw_results = self.collection.query(**kwargs)

        hits = []
        if raw_results and raw_results["ids"] and raw_results["ids"][0]:
            count = len(raw_results["ids"][0])
            for i in range(count):
                cid = raw_results["ids"][0][i]
                doc_text = raw_results["documents"][0][i] if raw_results["documents"] else ""
                meta = raw_results["metadatas"][0][i] if raw_results["metadatas"] else {}
                dist = raw_results["distances"][0][i] if raw_results["distances"] else 1.0
                score = round(max(0.0, 1.0 - dist), 4)

                hit = dict(meta)
                hit["chunk_id"] = cid
                hit["text"] = doc_text
                hit["score"] = score
                hit["dense_score"] = score
                hits.append(hit)

        return hits
