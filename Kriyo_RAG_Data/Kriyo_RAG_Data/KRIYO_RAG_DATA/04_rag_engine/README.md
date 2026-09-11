# KRIYO Standalone Hybrid RAG Engine

A fully local, standalone Hybrid Retrieval-Augmented Generation (RAG) engine built for the KRIYO synthetic demo corpus.

> **SYNTHETIC DEMO NOTICE**
> All documents, facts, metrics, and responses handled by this engine are strictly `synthetic_demo` data. They do NOT represent real individuals, verified historical accounts, official government schemes, or live market statistics.

---

## Key Architecture & Features

- **Hybrid Retrieval Engine**:
  - **Vector Similarity Search**: Searches ChromaDB index over 50 Markdown knowledge documents (`02_knowledge_documents/`, 762 chunks) using `sentence-transformers/all-MiniLM-L6-v2`.
  - **Structured Dataset Lookup**: Queries 10 Excel workbooks (`01_structured/`) via `excel_lookup.py` for structured craft, product, artisan, B2B buyer, and government scheme data.
- **Terminal CLI Querying**:
  - Terminal execution via `python query_rag.py "Question"` or interactive prompt mode.
  - Default `top_k=8` chunks with intent expansion and preferred document boosting.
- **Strict Answer Safety & Refusal Policies**:
  - Grounded answers explicitly cite `[document_id: section_name]` and attach synthetic demo notices.
  - Unrelated non-domain questions return:
    `The answer you are looking for is not available in the KRIYO knowledge base.`
  - Missing evidence or private personal data requests return:
    `INSUFFICIENT EVIDENCE: The KRIYO synthetic corpus does not contain enough grounded context to answer this question.`

---

## Folder Layout

```
D:\Kriyo_RAG_Data\KRIYO_RAG_DATA\04_rag_engine\
├── index\                   # Persistent ChromaDB vector index & build_stats.json
├── logs\                    # Sample query logs & evaluation output (sample_queries.txt)
├── src\
│   ├── ingest.py            # Recursive markdown parser & heading chunker
│   ├── build_index.py       # SentenceTransformer embedder & ChromaDB builder
│   ├── excel_lookup.py      # In-memory structured query retriever over 01_structured workbooks
│   ├── retrieve.py          # Hybrid retriever combining ChromaDB & Excel search
│   └── answer.py            # Grounded answer synthesizer & refusal policy engine
├── build_rag.py             # CLI script to build vector index
├── query_rag.py             # Terminal CLI script to execute queries (default top_k=8)
├── run_test_queries.py      # Evaluation query suite
├── requirements.txt         # Dependencies
└── README.md                # Documentation
```

---

## Installation

Ensure Python 3.10+ is installed on Windows, then install dependencies:

```powershell
pip install -r requirements.txt
```

Required packages:
- `chromadb`: Persistent vector store
- `sentence-transformers`: Local embedding model (`sentence-transformers/all-MiniLM-L6-v2`)
- `openpyxl`: Excel workbook processing
- `pyyaml`: YAML front matter parser

---

## Usage

### 1. Build Vector Index

Run the build script to ingest all 50 Markdown documents from `02_knowledge_documents`, parse section headers, create embeddings, and persist the index to `04_rag_engine/index/`:

```powershell
python build_rag.py
```

### 2. Terminal CLI Query

Run queries directly from the command line:

```powershell
python query_rag.py "What are the crafts available?"
python query_rag.py "Which products are suitable for B2B buyers?"
```

Run test suite across evaluation queries:

```powershell
python run_test_queries.py
```

Interactive mode (run without parameters):

```powershell
python query_rag.py
```

---

## Grounded Answer Policy Rules

1. **Synthetic Demo Scope**: Answers cite `[document_id: section_name]` (or `[workbook.xlsx: section_name]`) and state that sources are `synthetic_demo`.
2. **Missing Evidence Fallback**: If retrieved evidence lacks relevant facts, the engine returns:
   `INSUFFICIENT EVIDENCE: The KRIYO synthetic corpus does not contain enough grounded context to answer this question.`
3. **Domain & Private Data Refusal**: Questions outside the domain return `The answer you are looking for is not available in the KRIYO knowledge base.`. Requests for exact artisan incomes, phone numbers, or passwords return `INSUFFICIENT EVIDENCE...`.


