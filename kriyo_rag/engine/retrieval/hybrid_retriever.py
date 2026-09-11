"""
Hybrid Retriever.
Coordinates Dense Vector Search, BM25 Lexical Search, Structured Registry Lookups,
and Evidence Registry Traversal with Attribute-Aware Reranking.
"""

import os
import glob
from typing import List, Dict, Any, Optional

from .vector_retriever import VectorRetriever
from .bm25_retriever import BM25Retriever
from .structured_retriever import StructuredRetriever
from .evidence_retriever import EvidenceRetriever
from .reranker import Reranker
from ..understanding.query_analyzer import QueryAnalyzer
from ...config.settings import settings


class HybridRetriever:
    def __init__(
        self,
        index_dir: Optional[str] = None,
        docs_dir: Optional[str] = None,
        structured_dir: Optional[str] = None,
        evidence_path: Optional[str] = None,
    ):
        self.docs_dir = str(docs_dir or settings.DOCS_DIR)
        self.vector_retriever = VectorRetriever(index_dir=index_dir)
        self.structured_retriever = StructuredRetriever(structured_dir=structured_dir)
        self.evidence_retriever = EvidenceRetriever(evidence_path=evidence_path)
        self.query_analyzer = QueryAnalyzer(structured_dir=structured_dir)
        self.reranker = Reranker()

        self.bm25_retriever = BM25Retriever()
        self._init_bm25()

    def _init_bm25(self):
        chunks = []
        md_files = glob.glob(os.path.join(self.docs_dir, "**", "*.md"), recursive=True)
        for mdf in md_files:
            fname = os.path.basename(mdf)
            doc_id = os.path.splitext(fname)[0].upper()
            cid = doc_id.replace("DOC", "C")
            try:
                with open(mdf, "r", encoding="utf-8", errors="ignore") as f:
                    content = f.read()

                meta_header = ""
                if content.startswith("---"):
                    parts = content.split("---", 2)
                    if len(parts) >= 3:
                        meta_header = parts[1]
                        body_content = parts[2]
                    else:
                        body_content = content
                else:
                    body_content = content

                sections = body_content.split("\n# ")
                for sec in sections:
                    if not sec.strip():
                        continue
                    lines = sec.strip().split("\n")
                    header = lines[0].replace("#", "").strip()
                    body = "\n".join(lines[1:]).strip()
                    chunk_id = f"{doc_id}#{header.replace(' ', '_')}"
                    chunks.append({
                        "chunk_id": chunk_id,
                        "document_id": doc_id,
                        "source_id": doc_id,
                        "section_id": header,
                        "title": header,
                        "section_name": header,
                        "filepath": mdf,
                        "craft_id": cid,
                        "craft_name": header.split("—")[0].strip() if "—" in header else doc_id,
                        "data_status": "synthetic_demo",
                        "folder_type": os.path.basename(os.path.dirname(mdf)),
                        "text": f"{meta_header}\n\n{header}\n\n{body}"
                    })
            except Exception:
                pass
        self.bm25_retriever.fit(chunks)

    def retrieve(self, query: str, top_k: int = 8) -> Dict[str, Any]:
        """
        Executes complete hybrid retrieval flow:
        Analysis -> Dense Search + BM25 Search + Structured Query + Evidence -> Reranking
        """
        analysis = self.query_analyzer.analyze_query(query)

        # 1. Unanswerable fast-path
        if analysis["intent"] == "unanswerable":
            return {
                "query": query,
                "query_analysis": analysis,
                "retrieved_chunks": [],
                "structured_data": {},
                "evidence_claims": []
            }

        canonical_cids = [e["canonical_craft_id"] for e in analysis.get("entities", [])]

        # 2. Dense Vector Search
        dense_results = self.vector_retriever.search(query, top_k=top_k * 2)

        # 3. Lexical BM25 Search
        bm25_results = self.bm25_retriever.search(query, top_k=top_k * 2)

        # 4. Merge candidates by chunk_id
        candidate_map = {}
        for d in dense_results:
            candidate_map[d["chunk_id"]] = dict(d)

        for b in bm25_results:
            cid = b["chunk_id"]
            if cid in candidate_map:
                candidate_map[cid]["bm25_score"] = b["bm25_score"]
            else:
                candidate_map[cid] = dict(b)

        candidates = list(candidate_map.values())

        # 5. Rerank
        ranked_chunks = self.reranker.rerank(
            candidates,
            target_attribute=analysis.get("target_attribute"),
            canonical_craft_ids=canonical_cids,
            top_k=top_k
        )

        # 6. Structured Lookups
        structured_data: Dict[str, Any] = {}
        target_cid = canonical_cids[0] if canonical_cids else None
        if target_cid:
            structured_data["craft"] = self.structured_retriever.search_craft_by_id(target_cid)
            structured_data["artisans"] = self.structured_retriever.search_artisans(craft_id=target_cid)
            structured_data["products"] = self.structured_retriever.search_products(query, craft_id=target_cid)
            structured_data["techniques"] = self.structured_retriever.search_techniques(craft_id=target_cid)

        # 7. Evidence Registry Claims
        evidence_claims = self.evidence_retriever.search_evidence(query, craft_id=target_cid, max_results=5)

        return {
            "query": query,
            "query_analysis": analysis,
            "retrieved_chunks": ranked_chunks,
            "structured_data": structured_data,
            "evidence_claims": evidence_claims
        }
