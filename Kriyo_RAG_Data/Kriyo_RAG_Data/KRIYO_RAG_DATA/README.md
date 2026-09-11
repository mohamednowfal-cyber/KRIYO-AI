# KRIYO Synthetic Demo Knowledge Base Architecture

A complete, internally consistent synthetic knowledge base designed for building and evaluating Retrieval-Augmented Generation (RAG) applications on Indian traditional crafts, artisans, heritage preservation, market intelligence, B2B matching, and provenance.

> **SYNTHETIC DEMO NOTICE**
> All datasets, documents, facts, metrics, and answers in this knowledge base are strictly `synthetic_demo` data. They do NOT represent verified real-world individuals, official government schemes, live market trading prices, or authoritative academic citations.

---

## 1. Directory Structure

```
KRIYO_RAG_DATA/
├── 01_structured/                           # SQL / Tabular Datasets (.xlsx)
│   ├── KRIYO_Craft_Master.xlsx              # 150 craft records (C001 - C150)
│   ├── KRIYO_Craft_Product_Relationships.xlsx # 300 craft-to-product entity relationships (R00001 - R00300)
│   ├── KRIYO_Artisan_Profiles.xlsx          # 150 synthetic artisan profiles (A001 - A150)
│   ├── KRIYO_Craft_Products.xlsx            # 300 product records (P00001 - P00300)
│   ├── KRIYO_Craft_Techniques.xlsx          # 150 technique process records (T001 - T150)
│   ├── KRIYO_Market_Intelligence.xlsx       # 500 market demand records (M00001 - M00500)
│   ├── KRIYO_B2B_Buyers.xlsx                # 200 fictional buyer profiles (BUY001 - BUY200)
│   ├── KRIYO_Language_Glossary.xlsx         # 500 multilingual terms across 6 languages (TERM00001 - TERM00500)
│   └── KRIYO_Provenance.xlsx                # 300 provenance verification records (PROV00001 - PROV00300)
├── 02_knowledge_documents/                  # Vector Store Input (.md)
│   ├── crafts/                              # DOC001 - DOC010
│   ├── techniques/                          # DOC011 - DOC015
│   ├── heritage/                            # DOC016 - DOC020
│   ├── oral_history/                        # DOC021 - DOC024
│   ├── market/                              # DOC025 - DOC027
│   └── research/                            # DOC028 - DOC030
├── 03_evidence/                             # Evidence Graph / RAG Grounding (.xlsx)
│   └── KRIYO_Evidence_Registry.xlsx         # 500 structured evidence claims (EV00001 - EV00500)
├── 04_evaluation/                           # RAG Evaluation Golden Dataset (.xlsx)
│   └── KRIYO_RAG_Golden_Evaluation.xlsx     # 150 benchmark evaluation questions with abstention rules (EVAL001 - EVAL150)
├── 05_manifest/                             # System Manifest (.csv)
│   └── KRIYO_Data_Manifest.csv              # Unified source registry
└── README.md                                # Architecture documentation
```

---

## 2. Entity Relationship Diagram & ID Conventions

All datasets strictly follow canonical ID formatting:

- `craft_id`: `C001` through `C150`
- `artisan_id`: `A001` through `A150`
- `product_id`: `P00001` through `P00300`
- `technique_id`: `T001` through `T150`
- `buyer_id`: `BUY001` through `BUY200`
- `market_id`: `M00001` through `M00500`
- `provenance_id`: `PROV00001` through `PROV00300`
- `term_id`: `TERM00001` through `TERM00500`
- `evidence_id`: `EV00001` through `EV00500`
- `source_id` / `document_id`: `DOC001` through `DOC030`
- `eval_id`: `EVAL001` through `EVAL150`

### Foreign Key Links

- `KRIYO_Craft_Products.xlsx` -> `craft_id` (`Cxxx`), `artisan_id` (`Axxx`)
- `KRIYO_Artisan_Profiles.xlsx` -> `craft_id` (`Cxxx`)
- `KRIYO_Craft_Product_Relationships.xlsx` -> `craft_id` (`Cxxx`), `product_id` (`Pxxxxx`), `evidence_id` (`EVxxxxx`), `source_id` (`DOCxxx`)
- `KRIYO_Evidence_Registry.xlsx` -> `subject_id` (`Cxxx`), `source_id` (`DOCxxx`)
- `KRIYO_Provenance.xlsx` -> `product_id` (`Pxxxxx`), `craft_id` (`Cxxx`), `artisan_id` (`Axxx`)

---

## 3. Data Storage & RAG Processing Guidelines

- **SQL / Relational Ingestion**: Store `01_structured/*.xlsx` workbooks into relational tables for structured filtering (e.g. state, price range, B2B availability, MOQ).
- **Vector Indexing**: Chunk and embed all Markdown files under `02_knowledge_documents/` into vector databases (ChromaDB, Pinecone, Qdrant) using `sentence-transformers/all-MiniLM-L6-v2`.
- **RAG Evaluation**: Utilize `04_evaluation/KRIYO_RAG_Golden_Evaluation.xlsx` to benchmark retrieval precision, recall, citation accuracy, and abstention compliance (30 unanswerable & 20 adversarial queries).
