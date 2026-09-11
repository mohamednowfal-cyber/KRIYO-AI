"""
KRIYO Synthetic Demo RAG Index Builder
Embeds chunks using sentence-transformers and persists them in a ChromaDB vector store.
Saves build stats to index/build_stats.json.
"""

import os
import json
import datetime
from sentence_transformers import SentenceTransformer
import chromadb
from chromadb.config import Settings

from src.ingest import ingest_corpus


def build_vector_index(
    docs_root: str,
    index_dir: str,
    model_name: str = "sentence-transformers/all-MiniLM-L6-v2"
):
    """
    Ingests corpus, embeds chunks using local sentence-transformers,
    stores vectors in ChromaDB, and writes build stats.
    """
    os.makedirs(index_dir, exist_ok=True)
    chroma_db_dir = os.path.join(index_dir, "chroma_db")

    print(f"[*] Starting ingestion from {docs_root}...")
    chunks = ingest_corpus(docs_root)

    # Count unique files ingested
    unique_files = set(c["filepath"] for c in chunks)
    files_ingested_count = len(unique_files)

    print(f"[*] Loading embedding model: {model_name}...")
    model = SentenceTransformer(model_name)

    print(f"[*] Initializing ChromaDB persistent client at {chroma_db_dir}...")
    chroma_client = chromadb.PersistentClient(path=chroma_db_dir)

    collection_name = "kriyo_synthetic_corpus"
    # Reset/recreate collection if exists
    try:
        chroma_client.delete_collection(name=collection_name)
    except Exception:
        pass

    collection = chroma_client.create_collection(
        name=collection_name,
        metadata={"hnsw:space": "cosine"}
    )

    print(f"[*] Embedding {len(chunks)} chunks...")
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

    embeddings = model.encode(texts, show_progress_bar=True, normalize_embeddings=True)
    embeddings_list = embeddings.tolist()

    # Batch add into ChromaDB
    batch_size = 100
    for i in range(0, len(chunks), batch_size):
        end_idx = min(i + batch_size, len(chunks))
        collection.add(
            ids=ids[i:end_idx],
            documents=texts[i:end_idx],
            metadatas=metadatas[i:end_idx],
            embeddings=embeddings_list[i:end_idx]
        )

    print(f"[+] Successfully indexed {len(chunks)} chunks into ChromaDB.")

    # Save Build Stats JSON
    build_stats = {
        "files_ingested": files_ingested_count,
        "chunks_created": len(chunks),
        "embedding_model": model_name,
        "build_timestamp": datetime.datetime.now(datetime.timezone.utc).isoformat()
    }
    stats_file = os.path.join(index_dir, "build_stats.json")
    with open(stats_file, "w", encoding="utf-8") as f:
        json.dump(build_stats, f, indent=2)

    print(f"[+] Saved build stats to {stats_file}")
    return build_stats


if __name__ == "__main__":
    docs_dir = r"D:\Kriyo_RAG_Data\KRIYO_RAG_DATA\02_knowledge_documents"
    idx_dir = r"D:\Kriyo_RAG_Data\KRIYO_RAG_DATA\04_rag_engine\index"
    build_vector_index(docs_dir, idx_dir)
