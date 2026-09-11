"""
Score Fusion & Attribute-Aware Reranker.
Merges dense vector and lexical BM25 scores, applies attribute keyword boosts,
and reorders candidates for final context generation.
"""

from typing import List, Dict, Any, Optional


class Reranker:
    def __init__(self, dense_weight: float = 0.65, bm25_weight: float = 0.35):
        self.dense_weight = dense_weight
        self.bm25_weight = bm25_weight

    def rerank(
        self,
        candidates: List[Dict[str, Any]],
        target_attribute: Optional[str] = None,
        canonical_craft_ids: Optional[List[str]] = None,
        top_k: int = 8
    ) -> List[Dict[str, Any]]:
        """
        Calculates unified score with attribute and entity affinity boosting.
        """
        canonical_set = set(cid.upper() for cid in (canonical_craft_ids or []))

        for cand in candidates:
            dense_score = cand.get("dense_score", cand.get("score", 0.0))
            bm25_score = cand.get("bm25_score", 0.0)

            base_score = (self.dense_weight * dense_score) + (self.bm25_weight * bm25_score)

            # Entity affinity boost
            cand_cid = str(cand.get("craft_id", "")).upper()
            cand_doc_id = str(cand.get("document_id", "")).upper()
            if cand_cid in canonical_set or any(cid in cand_doc_id for cid in canonical_set):
                base_score += 0.25

            # Attribute match boost
            if target_attribute:
                sec_name = str(cand.get("section_name", "")).lower()
                text = str(cand.get("text", "")).lower()
                if target_attribute.lower() in sec_name:
                    base_score += 0.20
                elif target_attribute.lower() in text:
                    base_score += 0.10

            cand["reranker_score"] = round(base_score, 4)

        candidates.sort(key=lambda x: x.get("reranker_score", 0.0), reverse=True)
        return candidates[:top_k]
