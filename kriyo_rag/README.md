# KRIYO Grounded RAG & AI Knowledge Service

The **KRIYO RAG Knowledge Service** is a standalone, microservice-ready Retrieval-Augmented Generation system powering intelligent craft verification, artisan intelligence, and cultural heritage querying across the KRIYO ecosystem.

> **SYNTHETIC DEMO NOTICE**
> All documents, facts, metrics, and responses handled by this engine are strictly `synthetic_demo` data. They do NOT represent real individuals, verified historical accounts, official government schemes, or live market statistics.

---

## Directory Architecture

```
kriyo_rag/
│
├── data/                                 # Ingested datasets
│   ├── 01_structured/                    # 12 Structured Excel workbooks (Crafts, Products, Artisans)
│   ├── 02_knowledge_documents/           # 50 Detailed Markdown domain documents
│   ├── 03_evidence/                      # Verified claim-level evidence registry (EV00001 - EV00500)
│   ├── 03_metadata/                      # Corpus metadata & integrity reports
│   └── 05_manifest/                      # Manifest schemas
│
├── storage/
│   └── index/                            # Persistent ChromaDB vector store + build_stats.json
│
├── config/                               # Dynamic path resolution & Pydantic settings
│   ├── __init__.py
│   └── settings.py
│
├── engine/                               # Modular RAG core
│   ├── ingestion/                        # Document loaders & hierarchical markdown chunker
│   ├── retrieval/                        # Hybrid retriever (Dense + BM25 + Structured + Evidence + Reranker)
│   ├── understanding/                    # Language detector, intent classifier & entity resolver
│   ├── answering/                        # Grounded answer generator, citation validator & refusal policy
│   ├── embeddings/                       # SentenceTransformer wrapper & configuration
│   ├── knowledge/                        # Entity registry, relationship resolver & knowledge graph
│   └── pipeline/                         # End-to-end RAG orchestrator & context builder
│
├── api/                                  # FastAPI microservice
│   ├── main.py                           # App entry point & CORS configuration
│   ├── routes.py                         # /query, /health, /stats endpoints
│   └── schemas.py                        # Pydantic request/response models
│
├── scripts/                              # Developer CLI tools
│   ├── build_rag.py                      # Rebuilds persistent vector index
│   ├── query_rag.py                      # Terminal CLI interactive & argument query runner
│   └── run_test_queries.py               # Test query suite
│
├── evaluation/                           # Golden evaluations & benchmark results
├── tests/                                # Pytest test suite
├── requirements.txt
├── .env
├── .env.example
├── Dockerfile
└── README.md
```

---

## Quick Start

### 1. Install Dependencies
```bash
pip install -r requirements.txt
```

### 2. Run Terminal CLI Query
```bash
python scripts/query_rag.py "What are the traditional crafts in Tamil Nadu?"
```

### 3. Run Interactive Query Mode
```bash
python scripts/query_rag.py --interactive
```

### 4. Start the FastAPI Service
```bash
uvicorn api.main:app --host 0.0.0.0 --port 8001 --reload
```
Interactive Swagger documentation will be available at `http://localhost:8001/docs`.
