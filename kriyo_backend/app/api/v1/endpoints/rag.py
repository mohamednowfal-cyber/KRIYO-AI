"""
RAG & Knowledge Assistance Endpoints for KRIYO Backend.
Integrates directly with the KRIYO RAG Knowledge Service.
"""

import httpx
from typing import Optional, Dict, Any
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

router = APIRouter(prefix="/rag", tags=["RAG Knowledge Assistant"])

# RAG microservice URL
RAG_SERVICE_URL = "http://localhost:8001/api/v1/rag"


class BackendRagQueryRequest(BaseModel):
    query: str = Field(..., description="Query about Indian crafts, artisans, or techniques")
    top_k: Optional[int] = Field(8, description="Number of evidence chunks")


class BackendRagQueryResponse(BaseModel):
    query: str
    answer: str
    intent: str
    language: str
    citations_count: int = 0


@router.post("/query", response_model=BackendRagQueryResponse)
async def query_knowledge_base(req: BackendRagQueryRequest):
    """
    Routes query to KRIYO RAG microservice, with graceful fallback.
    """
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.post(
                f"{RAG_SERVICE_URL}/query",
                json={"query": req.query, "top_k": req.top_k}
            )
            if resp.status_code == 200:
                data = resp.json()
                return BackendRagQueryResponse(
                    query=data["query"],
                    answer=data["answer"],
                    intent=data.get("intent", "attribute_lookup"),
                    language=data.get("language", "en"),
                    citations_count=data.get("citations_count", 0)
                )
    except Exception:
        # Fallback to local import if running in monorepo environment
        try:
            from kriyo_rag.engine.pipeline.rag_pipeline import RAGPipeline
            pipeline = RAGPipeline()
            res = pipeline.run(req.query, top_k=req.top_k)
            return BackendRagQueryResponse(
                query=req.query,
                answer=res["answer"],
                intent=res["query_analysis"].get("intent", "attribute_lookup"),
                language=res["query_analysis"].get("language", "en"),
                citations_count=len(res.get("retrieved_chunks", []))
            )
        except Exception as local_err:
            raise HTTPException(
                status_code=503,
                detail=f"KRIYO RAG service unavailable: {local_err}"
            )
