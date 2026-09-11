"""
Terminal CLI Query Interface for KRIYO RAG Engine.
Usage:
    python query_rag.py "What are the crafts of Tamil Nadu?"
    python query_rag.py --interactive
"""

import sys
from pathlib import Path

# Add project root to sys.path
ROOT = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(ROOT))

from kriyo_rag.engine.pipeline.rag_pipeline import RAGPipeline


def run_cli():
    print("=" * 70)
    print(" KRIYO GROUNDED RAG KNOWLEDGE SERVICE — TERMINAL INTERACTION")
    print("=" * 70)

    pipeline = RAGPipeline()

    if len(sys.argv) > 1 and sys.argv[1] != "--interactive":
        query = " ".join(sys.argv[1:])
        print(f"\n[?] Query: {query}\n")
        res = pipeline.run(query)
        print("-" * 70)
        print(res["answer"])
        print("-" * 70)
        return

    print("\nEnter questions below (Type 'exit' or 'quit' to end):\n")
    while True:
        try:
            q = input("KRIYO-RAG > ").strip()
            if not q:
                continue
            if q.lower() in ["exit", "quit", "q"]:
                print("Exiting KRIYO RAG...")
                break
            res = pipeline.run(q)
            print("-" * 70)
            print(res["answer"])
            print("-" * 70)
            print()
        except KeyboardInterrupt:
            print("\nExiting KRIYO RAG...")
            break


if __name__ == "__main__":
    run_cli()
