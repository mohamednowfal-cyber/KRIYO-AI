"""
Runs the 7 mandatory evaluation queries for the KRIYO Synthetic Demo RAG System
and writes full output to logs/sample_queries.txt.
"""

import os
import sys
import io
from contextlib import redirect_stdout

# Ensure src is in python path
current_dir = os.path.dirname(os.path.abspath(__file__))
if current_dir not in sys.path:
    sys.path.insert(0, current_dir)

from src.retrieve import CorpusRetriever
from src.answer import generate_answer

TEST_QUERIES = [
    "What are the crafts available?",
    "Which crafts are associated with Thanjavur?",
    "What traditional techniques are associated with Thanjavur bronze casting?",
    "What digital barriers do traditional artisans face?",
    "Which products are suitable for B2B buyers?",
    "What is the exact annual income of Artisan A001?",
    "Who won the cricket world cup?"
]

def main():
    logs_dir = r"D:\Kriyo_RAG_Data\KRIYO_RAG_DATA\04_rag_engine\logs"
    os.makedirs(logs_dir, exist_ok=True)
    log_filepath = os.path.join(logs_dir, "sample_queries.txt")

    print("[*] Initializing retriever once for test queries...")
    index_dir = r"D:\Kriyo_RAG_Data\KRIYO_RAG_DATA\04_rag_engine\index"
    retriever = CorpusRetriever(index_dir=index_dir)

    output_lines = []
    output_lines.append("==================================================")
    output_lines.append(" KRIYO RAG ENGINE — EVALUATION TEST QUERY RESULTS")
    output_lines.append(" Corpus Status: synthetic_demo")
    output_lines.append("==================================================\n")

    for idx, q in enumerate(TEST_QUERIES, 1):
        print(f"[{idx}/7] Querying: '{q}'...")
        output_lines.append(f"QUERY #{idx}: {q}")
        output_lines.append("=" * 60)

        chunks = retriever.retrieve(query=q, top_k=8)
        output_lines.append("\n--- RETRIEVED SOURCES ---")
        if not chunks:
            output_lines.append(" [No matching chunks retrieved]")
        else:
            for c_idx, chunk in enumerate(chunks, 1):
                output_lines.append(f"[{c_idx}] Document: {chunk['document_id']} | Section: {chunk['section_name']} | Score: {chunk['score']}")
                output_lines.append(f"    Folder: {chunk['folder_type']} | Path: {chunk['filepath']}")
                snippet = chunk['text'].replace('\n', ' ')[:120]
                output_lines.append(f"    Snippet: {snippet}...")
                output_lines.append("")

        output_lines.append("--- GROUNDED ANSWER ---")
        ans = generate_answer(q, chunks)
        output_lines.append(ans)
        output_lines.append("\n" + ("-" * 60) + "\n")

    full_log = "\n".join(output_lines)
    with open(log_filepath, "w", encoding="utf-8") as f:
        f.write(full_log)

    print(f"[+] Saved evaluation results to {log_filepath}")

if __name__ == "__main__":
    main()

