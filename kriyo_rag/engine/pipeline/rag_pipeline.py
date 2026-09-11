"""
Unified RAG Pipeline.
Integrates Query Understanding, Hybrid Retrieval, Context Assembly, and Grounded Answer Generation.
"""

from typing import Dict, Any, Optional
from ..retrieval.hybrid_retriever import HybridRetriever
from ..answering.answer_generator import GroundedAnswerGenerator
from .context_builder import ContextBuilder
from ...config.settings import settings


class RAGPipeline:
    def __init__(
        self,
        index_dir: Optional[str] = None,
        docs_dir: Optional[str] = None,
        structured_dir: Optional[str] = None,
        evidence_path: Optional[str] = None,
    ):
        self.retriever = HybridRetriever(
            index_dir=index_dir,
            docs_dir=docs_dir,
            structured_dir=structured_dir,
            evidence_path=evidence_path
        )
        self.generator = GroundedAnswerGenerator(structured_dir=structured_dir)
        self.context_builder = ContextBuilder()

    def run(self, query: str, top_k: int = 8) -> Dict[str, Any]:
        """
        Executes end-to-end RAG workflow.
        """
        retrieval_output = self.retriever.retrieve(query, top_k=top_k)
        answer = self.generator.generate_answer(query, retrieval_output)
        context_str = self.context_builder.build_context(retrieval_output)

        return {
            "query": query,
            "answer": answer,
            "query_analysis": retrieval_output["query_analysis"],
            "retrieved_chunks": retrieval_output["retrieved_chunks"],
            "structured_data": retrieval_output["structured_data"],
            "evidence_claims": retrieval_output["evidence_claims"],
            "assembled_context": context_str
        }
