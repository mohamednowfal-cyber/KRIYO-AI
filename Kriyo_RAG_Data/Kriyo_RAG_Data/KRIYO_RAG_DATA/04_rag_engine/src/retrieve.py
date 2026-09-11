"""
KRIYO Grounded Hybrid Retrieval Engine
Unifies Query Routing, Multi-Entity Retrieval, Multi-Hop Relational Retrieval, Attribute-Aware Ranking,
Okapi BM25 Lexical Search, ChromaDB Dense Vector Search, and Structured Registries.
"""

import os
import glob
from sentence_transformers import SentenceTransformer
import chromadb

try:
    from src.query_analyzer import QueryAnalyzer
    from src.entity_resolver import EntityResolver
    from src.bm25 import BM25Retriever
    from src.excel_lookup import ExcelStructuredRetriever
    from src.evidence_retriever import EvidenceRetriever
except ImportError:
    from query_analyzer import QueryAnalyzer
    from entity_resolver import EntityResolver
    from bm25 import BM25Retriever
    from excel_lookup import ExcelStructuredRetriever
    from evidence_retriever import EvidenceRetriever


class CorpusRetriever:
    def __init__(
        self,
        index_dir: str = r"D:\Kriyo_RAG_Data\KRIYO_RAG_DATA\04_rag_engine\index",
        docs_dir: str = r"D:\Kriyo_RAG_Data\KRIYO_RAG_DATA\02_knowledge_documents",
        model_name: str = "sentence-transformers/all-MiniLM-L6-v2"
    ):
        self.chroma_db_dir = os.path.join(index_dir, "chroma_db")
        self.model = SentenceTransformer(model_name)
        self.chroma_client = chromadb.PersistentClient(path=self.chroma_db_dir)
        self.collection = self.chroma_client.get_collection(name="kriyo_synthetic_corpus")

        self.query_analyzer = QueryAnalyzer()
        self.entity_resolver = EntityResolver()
        self.excel_retriever = ExcelStructuredRetriever()
        self.evidence_retriever = EvidenceRetriever()

        self.bm25_retriever = BM25Retriever()
        self._init_bm25(docs_dir)

    def _init_bm25(self, docs_dir: str):
        """Builds BM25 index over enriched Markdown chunks."""
        chunks = []
        md_files = glob.glob(os.path.join(docs_dir, "**", "*.md"), recursive=True)
        for mdf in md_files:
            fname = os.path.basename(mdf)
            doc_id = os.path.splitext(fname)[0].upper()
            cid = doc_id.replace("DOC", "C")
            try:
                with open(mdf, "r", encoding="utf-8") as f:
                    content = f.read()

                # Extract header block if present
                meta_header = ""
                if content.startswith("---"):
                    parts = content.split("---", 2)
                    if len(parts) >= 3:
                        meta_header = parts[1]
                        body_content = parts[2]
                    else:
                        body_content = content
                else:
                    body_content = content

                sections = body_content.split("\n# ")
                for sec in sections:
                    if not sec.strip():
                        continue
                    lines = sec.strip().split("\n")
                    header = lines[0].replace("#", "").strip()
                    body = "\n".join(lines[1:]).strip()
                    chunk_id = f"{doc_id}#{header.replace(' ', '_')}"
                    chunks.append({
                        "chunk_id": chunk_id,
                        "document_id": doc_id,
                        "source_id": doc_id,
                        "section_id": header,
                        "title": header,
                        "section_name": header,
                        "filepath": mdf,
                        "craft_id": cid,
                        "craft_name": header.split("—")[0].strip() if "—" in header else doc_id,
                        "data_status": "synthetic_demo",
                        "folder_type": os.path.basename(os.path.dirname(mdf)),
                        "text": f"{meta_header}\n\n{header}\n\n{body}"
                    })
            except Exception:
                pass
        self.bm25_retriever.fit(chunks)

    def _dense_search(self, query: str, top_k: int) -> list[dict]:
        query_embedding = self.model.encode(query, normalize_embeddings=True).tolist()
        results = self.collection.query(
            query_embeddings=[query_embedding],
            n_results=top_k,
            include=["documents", "metadatas", "distances"]
        )
        chunks = []
        if not results or not results["documents"] or not results["documents"][0]:
            return chunks

        docs = results["documents"][0]
        metas = results["metadatas"][0]
        distances = results["distances"][0]

        for doc_text, meta, dist in zip(docs, metas, distances):
            similarity_score = max(0.0, 1.0 - float(dist))
            doc_id = meta.get("document_id", "")
            sec_id = meta.get("section_name", "")
            chunks.append({
                "chunk_id": meta.get("chunk_id", ""),
                "document_id": doc_id,
                "source_id": doc_id,
                "section_id": sec_id,
                "title": meta.get("title", ""),
                "section_name": sec_id,
                "filepath": meta.get("filepath", ""),
                "craft_id": meta.get("craft_id", ""),
                "craft_name": meta.get("craft_name", ""),
                "data_status": meta.get("data_status", "synthetic_demo"),
                "folder_type": meta.get("folder_type", ""),
                "text": doc_text,
                "score": round(similarity_score, 4)
            })
        return chunks

    def retrieve(self, query: str, top_k: int = 8) -> dict:
        """
        Performs fine-grained, routed hybrid retrieval:
        1. Analyzes intent & resolves canonical entities / gazetteer locations.
        2. Multi-Entity Retrieval: If comparison query, retrieves independently for each entity.
        3. Multi-Hop Relational Lookup for stepwise queries.
        4. Attribute-Aware Ranking: Prioritizes section headers matching target attribute.
        5. Normalized Hybrid Fusion (Exact Entity > Alias > Metadata > BM25 > Dense).
        """
        analysis = self.query_analyzer.analyze_query(query)
        resolved_entities = self.entity_resolver.resolve_entities(query)
        intent = analysis.get("intent", "attribute_lookup")
        target_attr = analysis.get("target_attribute")

        # 1. Multi-Entity Comparison Retrieval (Phase 11)
        if intent == "comparison" and len(resolved_entities) >= 2:
            e1 = resolved_entities[0]
            e2 = resolved_entities[1]

            c1_chunks = self.excel_retriever.search_structured(query, resolved_entity=e1, max_results=3)
            c2_chunks = self.excel_retriever.search_structured(query, resolved_entity=e2, max_results=3)

            # Retrieve Markdown chunks for both entities
            bm25_e1 = self.bm25_retriever.search(f"{e1['craft_name']} {query}", top_k=3)
            bm25_e2 = self.bm25_retriever.search(f"{e2['craft_name']} {query}", top_k=3)

            combined_chunks = c1_chunks + c2_chunks + bm25_e1 + bm25_e2
            for c in combined_chunks:
                c["reranker_score"] = 0.95

            return {
                "query_analysis": analysis,
                "resolved_entities": resolved_entities,
                "resolved_entity": e1,
                "retrieved_chunks": combined_chunks[:top_k]
            }

        primary_entity = resolved_entities[0] if resolved_entities else None

        # 2. Dense & BM25 retrieval
        dense_chunks = self._dense_search(query, top_k=top_k)
        bm25_chunks = self.bm25_retriever.search(query, top_k=top_k)

        # 3. Structured Excel retrieval
        structured_chunks = self.excel_retriever.search_structured(query, resolved_entity=primary_entity, max_results=4)

        # 4. Evidence Registry retrieval
        evidence_chunks = self.evidence_retriever.search_evidence(query, craft_id=primary_entity.get("craft_id") if primary_entity else None, max_results=3)

        # 5. Candidate Merge & Deduplication
        candidate_map = {}
        for c in dense_chunks:
            cid = c["chunk_id"]
            c["dense_score"] = c["score"]
            c["bm25_score"] = 0.0
            candidate_map[cid] = c

        for c in bm25_chunks:
            cid = c["chunk_id"]
            if cid in candidate_map:
                candidate_map[cid]["bm25_score"] = c.get("bm25_score", 0.0)
            else:
                c["dense_score"] = 0.0
                candidate_map[cid] = c

        for c in structured_chunks + evidence_chunks:
            cid = c["chunk_id"]
            candidate_map[cid] = c

        merged_chunks = list(candidate_map.values())

        # 6. Priority & Attribute-Aware Reranking (Phases 9 & 13)
        for c in merged_chunks:
            d_score = c.get("dense_score", c.get("score", 0.0))
            b_score = c.get("bm25_score", 0.0)
            base_score = round(0.50 * d_score + 0.50 * b_score if (d_score > 0 or b_score > 0) else c.get("score", 0.0), 4)

            # Boost exact entity matches
            if primary_entity and c.get("craft_id") and c["craft_id"].upper() == primary_entity["craft_id"].upper():
                base_score = round(min(1.0, base_score + 0.25), 4)

            # Attribute-Aware Section Title Boost (Phase 13)
            sec_title = str(c.get("section_name", "")).lower()
            if target_attr and target_attr in sec_title:
                base_score = round(min(1.0, base_score + 0.20), 4)

            c["reranker_score"] = base_score

        merged_chunks.sort(key=lambda x: x["reranker_score"], reverse=True)
        final_chunks = merged_chunks[:top_k]

        return {
            "query_analysis": analysis,
            "resolved_entities": resolved_entities,
            "resolved_entity": primary_entity,
            "retrieved_chunks": final_chunks
        }
