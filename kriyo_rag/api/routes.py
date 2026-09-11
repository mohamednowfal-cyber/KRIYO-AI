"""
FastAPI Routes for KRIYO RAG Service.
"""

import os
import json
from fastapi import APIRouter, HTTPException, Depends
from .schemas import QueryRequest, QueryResponse, HealthResponse, BuildStatsResponse
from ..engine.pipeline.rag_pipeline import RAGPipeline
from ..config.settings import settings

router = APIRouter()

# Global pipeline instance initialized on first call
_pipeline: RAGPipeline = None


def get_pipeline() -> RAGPipeline:
    global _pipeline
    if _pipeline is None:
        _pipeline = RAGPipeline()
    return _pipeline


@router.get("/health", response_model=HealthResponse)
def health_check():
    stats_file = settings.INDEX_DIR / "build_stats.json"
    index_loaded = os.path.exists(settings.CHROMA_DB_DIR)
    chunks_count = 0

    if stats_file.exists():
        try:
            with open(stats_file, "r", encoding="utf-8") as f:
                data = json.load(f)
                chunks_count = data.get("chunks_created", 0)
        except Exception:
            pass

    return HealthResponse(
        status="healthy",
        service=settings.PROJECT_NAME,
        version=settings.VERSION,
        index_loaded=index_loaded,
        total_chunks=chunks_count
    )


@router.get("/stats", response_model=BuildStatsResponse)
def get_stats():
    stats_file = settings.INDEX_DIR / "build_stats.json"
    if not stats_file.exists():
        raise HTTPException(status_code=404, detail="Index build stats not found. Has RAG been built?")

    with open(stats_file, "r", encoding="utf-8") as f:
        data = json.load(f)

    return BuildStatsResponse(
        files_ingested=data.get("files_ingested", 0),
        chunks_created=data.get("chunks_created", 0),
        embedding_model=data.get("embedding_model", settings.EMBEDDING_MODEL_NAME),
        build_timestamp=data.get("build_timestamp")
    )


@router.post("/query", response_model=QueryResponse)
def query_rag(req: QueryRequest, pipeline: RAGPipeline = Depends(get_pipeline)):
    if not req.query.strip():
        raise HTTPException(status_code=400, detail="Query cannot be empty")

    output = pipeline.run(req.query, top_k=req.top_k or settings.TOP_K)
    analysis = output.get("query_analysis", {})
    chunks = output.get("retrieved_chunks", [])

    return QueryResponse(
        query=req.query,
        answer=output["answer"],
        intent=analysis.get("intent", "attribute_lookup"),
        language=analysis.get("language", "en"),
        target_attribute=analysis.get("target_attribute"),
        entities=analysis.get("entities", []),
        citations_count=sum(1 for c in chunks if c.get("document_id")),
        retrieved_chunks_count=len(chunks)
    )
