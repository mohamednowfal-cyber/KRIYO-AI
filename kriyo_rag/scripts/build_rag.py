"""
Build Vector Index CLI Script.
Ingests all knowledge documents from data/02_knowledge_documents, embeds chunks,
and persists them into storage/index/chroma_db.
"""

import os
import sys
import json
import datetime
from pathlib import Path

# Add project root to sys.path
ROOT = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(ROOT))

import chromadb  # type: ignore
from kriyo_rag.config.settings import settings
from kriyo_rag.engine.ingestion.markdown_loader import MarkdownLoader
from kriyo_rag.engine.ingestion.chunker import MarkdownChunker
from kriyo_rag.engine.embeddings.embedding_model import EmbeddingModel


def build_index():
    print(f"[*] Starting KRIYO RAG index build...")
    print(f"[*] Docs directory: {settings.DOCS_DIR}")
    print(f"[*] Target Index directory: {settings.INDEX_DIR}")

    loader = MarkdownLoader(docs_dir=str(settings.DOCS_DIR))
    documents = loader.load_documents()
    print(f"[*] Loaded {len(documents)} raw markdown documents.")

    chunker = MarkdownChunker()
    chunks = chunker.chunk_all(documents)
    print(f"[*] Created {len(chunks)} section chunks.")

    embedder = EmbeddingModel()

    os.makedirs(settings.INDEX_DIR, exist_ok=True)
    chroma_client = chromadb.PersistentClient(path=str(settings.CHROMA_DB_DIR))

    try:
        chroma_client.delete_collection(name=settings.COLLECTION_NAME)
    except Exception:
        pass

    collection = chroma_client.create_collection(
        name=settings.COLLECTION_NAME,
        metadata={"hnsw:space": "cosine"}
    )

    texts = [c["text"] for c in chunks]
    ids = [c["chunk_id"] for c in chunks]
    metadatas = [
        {
            "chunk_id": c["chunk_id"],
            "document_id": c["document_id"],
            "title": c["title"],
            "section_name": c["section_name"],
            "filepath": c["filepath"],
            "craft_id": c["craft_id"],
            "craft_name": c["craft_name"],
            "data_status": c["data_status"],
            "folder_type": c["folder_type"],
        }
        for c in chunks
    ]

    print(f"[*] Embedding {len(chunks)} chunks with {settings.EMBEDDING_MODEL_NAME}...")
    embeddings = embedder.encode(texts, show_progress_bar=True)

    batch_size = 100
    for i in range(0, len(chunks), batch_size):
        end_idx = min(i + batch_size, len(chunks))
        collection.add(
            ids=ids[i:end_idx],
            documents=texts[i:end_idx],
            metadatas=metadatas[i:end_idx],
            embeddings=embeddings[i:end_idx]
        )

    print(f"[+] Successfully indexed {len(chunks)} chunks into ChromaDB.")

    build_stats = {
        "files_ingested": len(documents),
        "chunks_created": len(chunks),
        "embedding_model": settings.EMBEDDING_MODEL_NAME,
        "build_timestamp": datetime.datetime.now(datetime.timezone.utc).isoformat()
    }
    stats_file = settings.INDEX_DIR / "build_stats.json"
    with open(stats_file, "w", encoding="utf-8") as f:
        json.dump(build_stats, f, indent=2)

    print(f"[+] Saved build statistics to {stats_file}")
    return build_stats


if __name__ == "__main__":
    build_index()
