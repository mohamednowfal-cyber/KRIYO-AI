"""
API Schemas for KRIYO RAG Service.
"""

from typing import List, Dict, Any, Optional
from pydantic import BaseModel, Field


class QueryRequest(BaseModel):
    query: str = Field(..., description="Natural language question or search phrase")
    top_k: Optional[int] = Field(8, description="Number of evidence chunks to retrieve")
    state_filter: Optional[str] = Field(None, description="Optional filter by Indian State")


class QueryResponse(BaseModel):
    query: str
    answer: str
    intent: str
    language: str
    target_attribute: Optional[str] = None
    entities: List[Dict[str, Any]] = []
    citations_count: int = 0
    retrieved_chunks_count: int = 0


class HealthResponse(BaseModel):
    status: str
    service: str
    version: str
    index_loaded: bool
    total_chunks: int


class BuildStatsResponse(BaseModel):
    files_ingested: int
    chunks_created: int
    embedding_model: str
    build_timestamp: Optional[str] = None
