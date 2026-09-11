"""
KRIYO RAG Engine — Pure-Python Okapi BM25 Lexical Retriever
Implements deterministic, dependency-free Okapi BM25 scoring over ingested text chunks.
Used for exact keyword matching in hybrid retrieval.
"""

import math
import re
from collections import Counter


class BM25Retriever:
    def __init__(self, k1: float = 1.5, b: float = 0.75):
        self.k1 = k1
        self.b = b
        self.doc_chunks = []
        self.doc_terms = []
        self.doc_len = []
        self.avgdl = 0.0
        self.doc_freqs = Counter()
        self.idf = {}
        self.num_docs = 0

    def tokenize(self, text: str) -> list[str]:
        """Normalizes and tokenizes text into word tokens."""
        return re.findall(r"\w+", text.lower())

    def fit(self, chunks: list[dict]):
        """Builds Okapi BM25 inverted index from ingested chunks."""
        self.doc_chunks = chunks
        self.num_docs = len(chunks)
        if self.num_docs == 0:
            return

        self.doc_terms = []
        self.doc_len = []
        self.doc_freqs = Counter()

        total_len = 0
        for chunk in chunks:
            text = f"{chunk.get('title', '')} {chunk.get('section_name', '')} {chunk.get('text', '')}"
            tokens = self.tokenize(text)
            self.doc_terms.append(Counter(tokens))
            self.doc_len.append(len(tokens))
            total_len += len(tokens)

            unique_tokens = set(tokens)
            for t in unique_tokens:
                self.doc_freqs[t] += 1

        self.avgdl = total_len / float(self.num_docs) if self.num_docs > 0 else 1.0

        # Compute IDF for all vocabulary terms
        self.idf = {}
        for term, freq in self.doc_freqs.items():
            # Standard Okapi BM25 IDF formula
            idf_val = math.log((self.num_docs - freq + 0.5) / (freq + 0.5) + 1.0)
            self.idf[term] = max(0.0, idf_val)

    def search(self, query: str, top_k: int = 10) -> list[dict]:
        """Performs lexical BM25 search over indexed chunks."""
        if self.num_docs == 0:
            return []

        q_tokens = self.tokenize(query)
        if not q_tokens:
            return []

        scores = [0.0] * self.num_docs

        for idx in range(self.num_docs):
            doc_tf = self.doc_terms[idx]
            d_len = self.doc_len[idx]

            score = 0.0
            for t in q_tokens:
                if t in doc_tf:
                    freq = doc_tf[t]
                    idf_term = self.idf.get(t, 0.0)
                    numerator = freq * (self.k1 + 1.0)
                    denominator = freq + self.k1 * (1.0 - self.b + self.b * (d_len / self.avgdl))
                    score += idf_term * (numerator / denominator)

            scores[idx] = score

        # Normalization to [0, 1] range for score merging
        max_score = max(scores) if scores else 1.0
        if max_score <= 0.0:
            max_score = 1.0

        results = []
        ranked_indices = sorted(range(len(scores)), key=lambda i: scores[i], reverse=True)

        for i in ranked_indices[:top_k]:
            if scores[i] <= 0.0:
                continue
            chunk_copy = dict(self.doc_chunks[i])
            chunk_copy["bm25_score"] = round(scores[i] / max_score, 4)
            results.append(chunk_copy)

        return results
