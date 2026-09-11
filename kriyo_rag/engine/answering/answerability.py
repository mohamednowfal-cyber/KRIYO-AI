"""
Evidence Gating and Answerability Calculator.
Enforces answerability thresholding and abstention on unsupported queries.
"""

from typing import Dict, Any
from .refusal_policy import (
    INSUFFICIENT_EVIDENCE_MSG,
    OUT_OF_DOMAIN_MSG,
    RefusalPolicy
)


class AnswerabilityGate:
    def __init__(
        self,
        min_retrieval_confidence: float = 0.20,
        min_evidence_coverage: float = 0.20
    ):
        self.min_retrieval_confidence = min_retrieval_confidence
        self.min_evidence_coverage = min_evidence_coverage

    def evaluate_answerability(self, retrieval_output: Dict[str, Any]) -> Dict[str, Any]:
        """
        Evaluates whether query can be answered reliably based on retrieved evidence.
        """
        analysis = retrieval_output.get("query_analysis", {})
        chunks = retrieval_output.get("retrieved_chunks", [])
        intent = analysis.get("intent", "attribute_lookup")

        # 1. Unanswerable intent
        if intent == "unanswerable":
            if analysis.get("is_out_of_domain"):
                return {
                    "is_answerable": False,
                    "refusal_reason": "out_of_domain",
                    "refusal_msg": OUT_OF_DOMAIN_MSG,
                    "retrieval_confidence": 0.0,
                    "evidence_coverage": 0.0,
                    "answerability": 0.0
                }
            else:
                return {
                    "is_answerable": False,
                    "refusal_reason": "private_or_ungrounded_projection",
                    "refusal_msg": INSUFFICIENT_EVIDENCE_MSG,
                    "retrieval_confidence": 0.0,
                    "evidence_coverage": 0.0,
                    "answerability": 0.0
                }

        # 2. Check if retrieved chunks are empty
        if not chunks:
            return {
                "is_answerable": False,
                "refusal_reason": "no_chunks_retrieved",
                "refusal_msg": INSUFFICIENT_EVIDENCE_MSG,
                "retrieval_confidence": 0.0,
                "evidence_coverage": 0.0,
                "answerability": 0.0
            }

        # 3. Calculate internal confidence scores
        top_score = max(c.get("reranker_score", c.get("score", 0.0)) for c in chunks)
        retrieval_confidence = round(top_score, 4)

        keywords = analysis.get("keywords", [])
        stop_words = {"what", "which", "are", "the", "for", "with", "does", "face", "this", "that", "how", "who", "won", "is", "a", "an", "of", "in", "to", "on"}
        content_keywords = [w for w in keywords if len(w) > 2 and w not in stop_words]

        if not content_keywords:
            evidence_coverage = 0.5
        else:
            matched_keywords = set()
            for chunk in chunks:
                text_lower = chunk.get("text", "").lower()
                for kw in content_keywords:
                    if kw in text_lower:
                        matched_keywords.add(kw)
            evidence_coverage = round(len(matched_keywords) / float(len(content_keywords)), 4)

        answerability = round(0.6 * retrieval_confidence + 0.4 * evidence_coverage, 4)

        # 4. Gating check
        if retrieval_confidence < self.min_retrieval_confidence or evidence_coverage < self.min_evidence_coverage:
            return {
                "is_answerable": False,
                "refusal_reason": "low_confidence_or_coverage",
                "refusal_msg": INSUFFICIENT_EVIDENCE_MSG,
                "retrieval_confidence": retrieval_confidence,
                "evidence_coverage": evidence_coverage,
                "answerability": answerability
            }

        return {
            "is_answerable": True,
            "refusal_reason": None,
            "refusal_msg": None,
            "retrieval_confidence": retrieval_confidence,
            "evidence_coverage": evidence_coverage,
            "answerability": answerability
        }
