# KRIYO Platform Monorepo

KRIYO is an end-to-end artisan heritage empowerment platform connecting traditional Indian artisans with conscious global buyers through authentic storytelling, AI craft intelligence, and verified provenance.

---

## Repository Structure

```
KRIYO/
│
├── kriyo_artisan_app/                    # Flutter Mobile Application (Artisan & Customer dual-experience)
│   ├── android/
│   ├── assets/
│   ├── lib/
│   ├── test/
│   └── pubspec.yaml
│
├── kriyo_backend/                         # FastAPI Application Backend
│   ├── app/
│   │   ├── main.py
│   │   ├── config/
│   │   ├── api/v1/
│   │   │   └── endpoints/ (auth, customer_auth, profiles, users, rag)
│   │   ├── models/
│   │   ├── schemas/
│   │   └── services/
│   ├── requirements.txt
│   ├── .env
│   └── Dockerfile
│
├── kriyo_rag/                             # Grounded RAG & AI Knowledge Microservice
│   ├── data/                              # Structured registries, markdown docs & evidence
│   ├── engine/                            # Ingestion, retrieval, understanding, answering, pipeline
│   ├── api/                               # FastAPI endpoints (/query, /health, /stats)
│   ├── config/                            # Dynamic configuration & settings
│   ├── storage/                           # Persistent ChromaDB vector store
│   ├── scripts/                           # Developer CLI utilities (build, query, test)
│   ├── evaluation/                        # Benchmark golden evaluations
│   └── requirements.txt
│
├── infrastructure/                        # Deployment & Orchestration Infrastructure
│   ├── docker/                            # Service Dockerfiles
│   ├── nginx/                             # Reverse proxy configuration
│   ├── postgres/                          # SQL schemas & database initialization
│   ├── redis/                             # Redis caching & rate-limiting configuration
│   └── monitoring/                        # Prometheus monitoring configurations
│
├── docker-compose.yml                     # Unified multi-container orchestration
└── README.md
```

---

## Getting Started

### 1. Run via Docker Compose
```bash
docker-compose up --build
```

### 2. Run Services Locally

#### Backend:
```bash
cd kriyo_backend
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

#### RAG Knowledge Service:
```bash
cd kriyo_rag
pip install -r requirements.txt
python scripts/query_rag.py "What are the traditional crafts in Tamil Nadu?"
uvicorn api.main:app --host 0.0.0.0 --port 8001 --reload
```

#### Flutter App:
```bash
cd kriyo_artisan_app
flutter pub get
flutter run
```
