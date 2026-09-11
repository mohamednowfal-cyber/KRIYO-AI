"""
CLI entry point to build the KRIYO Synthetic Demo RAG Index.
Usage:
    python build_rag.py
"""

import os
import sys

# Ensure src is in python path
current_dir = os.path.dirname(os.path.abspath(__file__))
if current_dir not in sys.path:
    sys.path.insert(0, current_dir)

from src.build_index import build_vector_index

def main():
    corpus_root = r"D:\Kriyo_RAG_Data\KRIYO_RAG_DATA\02_knowledge_documents"
    index_dir = r"D:\Kriyo_RAG_Data\KRIYO_RAG_DATA\04_rag_engine\index"

    print("==================================================")
    print(" KRIYO RAG Engine — Vector Index Builder")
    print(" Corpus Root: ", corpus_root)
    print(" Index Dir:   ", index_dir)
    print("==================================================")

    stats = build_vector_index(
        docs_root=corpus_root,
        index_dir=index_dir,
        model_name="sentence-transformers/all-MiniLM-L6-v2"
    )

    print("\n[+] Index Build Complete!")
    print(f"    - Files Ingested:  {stats['files_ingested']}")
    print(f"    - Chunks Created:  {stats['chunks_created']}")
    print(f"    - Embedding Model: {stats['embedding_model']}")
    print(f"    - Build Timestamp: {stats['build_timestamp']}")

if __name__ == "__main__":
    main()
