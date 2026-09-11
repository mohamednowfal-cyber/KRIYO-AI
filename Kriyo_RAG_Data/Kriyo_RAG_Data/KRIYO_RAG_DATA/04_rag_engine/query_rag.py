"""
CLI entry point to query the KRIYO Synthetic Demo Grounded RAG System.
Usage:
    python query_rag.py "Which crafts are associated with Thanjavur?"
"""

import os
import sys
import argparse

current_dir = os.path.dirname(os.path.abspath(__file__))
if current_dir not in sys.path:
    sys.path.insert(0, current_dir)

from src.retrieve import CorpusRetriever
from src.answer import GroundedAnswerGenerator


def run_query(question: str, top_k: int = 8):
    index_dir = r"D:\Kriyo_RAG_Data\KRIYO_RAG_DATA\04_rag_engine\index"
    retriever = CorpusRetriever(index_dir=index_dir)
    generator = GroundedAnswerGenerator()

    print("==================================================")
    print(f" QUESTION: {question}")
    print("==================================================")

    ret_output = retriever.retrieve(query=question, top_k=top_k)
    chunks = ret_output.get("retrieved_chunks", [])
    analysis = ret_output.get("query_analysis", {})
    resolved = ret_output.get("resolved_entity", {})

    print(f"[*] Intent Classification: {analysis.get('intent', 'unknown')}")
    if resolved:
        print(f"[*] Entity Resolved: {resolved.get('craft_name')} ({resolved.get('craft_id')})")

    print("\n--- RETRIEVED SOURCES ---")
    if not chunks:
        print(" [No matching chunks retrieved]")
    else:
        for idx, chunk in enumerate(chunks, 1):
            score = chunk.get("reranker_score", chunk.get("score", 0.0))
            print(f"[{idx}] Document: {chunk.get('document_id')} | Section: {chunk.get('section_name')} | Score: {score}")
            print(f"    Folder: {chunk.get('folder_type')} | Path: {chunk.get('filepath', '')}")
            text_preview = chunk.get('text', '').replace('\n', ' ')[:120]
            print(f"    Snippet: {text_preview}...")
            print()

    print("--- GROUNDED ANSWER ---")
    answer = generator.generate_answer(question, ret_output)
    print(answer)
    print("==================================================\n")
    return answer, ret_output


def main():
    parser = argparse.ArgumentParser(description="Query KRIYO Synthetic Demo Grounded RAG Pipeline")
    parser.add_argument("question", type=str, nargs="?", help="Question string to query the RAG system")
    parser.add_argument("--top_k", type=int, default=8, help="Number of chunks to retrieve")

    args = parser.parse_args()

    if args.question:
        run_query(args.question, top_k=args.top_k)
    else:
        print("Interactive Mode. Type your question or 'exit' to quit.\n")
        while True:
            try:
                q = input("Ask RAG> ").strip()
                if not q or q.lower() in ["exit", "quit"]:
                    break
                run_query(q, top_k=args.top_k)
            except (KeyboardInterrupt, EOFError):
                break


if __name__ == "__main__":
    main()
