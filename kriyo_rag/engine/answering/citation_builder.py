"""
Citation Builder.
Constructs, parses, and validates evidence citations from retrieved chunks and records.
"""

from typing import List, Dict, Any, Tuple


class CitationBuilder:
    @staticmethod
    def build_citations(chunks: List[Dict[str, Any]]) -> Tuple[Dict[str, str], str]:
        """
        Returns mapping of citation_string -> doc_id and the primary fallback citation.
        """
        valid_citations_map = {}
        for chunk in chunks:
            doc_id = chunk.get("document_id", "KRIYO-DOC")
            sec_name = chunk.get("section_name", "Overview & Geographic Origin")
            ev_id = chunk.get("evidence_id")
            citation = f"[{ev_id}]" if ev_id else f"[{doc_id}: {sec_name}]"
            valid_citations_map[citation] = doc_id

        first_citation = list(valid_citations_map.keys())[0] if valid_citations_map else "[DOC001: Overview]"
        return valid_citations_map, first_citation

    @staticmethod
    def format_inline(text: str, citation: str) -> str:
        t = text.strip()
        if citation not in t:
            return f"{t} {citation}"
        return t
