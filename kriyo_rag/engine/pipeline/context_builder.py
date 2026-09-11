"""
RAG Context Builder.
Assembles retrieved chunks, structured attributes, and evidence claims into an aggregated prompt context.
"""

from typing import Dict, Any, List


class ContextBuilder:
    @staticmethod
    def build_context(retrieval_output: Dict[str, Any]) -> str:
        chunks = retrieval_output.get("retrieved_chunks", [])
        structured = retrieval_output.get("structured_data", {})
        claims = retrieval_output.get("evidence_claims", [])

        sections = []

        if structured:
            craft = structured.get("craft")
            if craft:
                sections.append(f"### Craft Master Details:\n- Name: {craft.get('canonical_name')}\n- State: {craft.get('state')}\n- District: {craft.get('district')}\n- GI Status: {craft.get('gi_status')}")

        if chunks:
            sections.append("### Retrieved Knowledge Excerpts:")
            for i, chunk in enumerate(chunks, 1):
                doc_id = chunk.get("document_id", "DOC")
                sec = chunk.get("section_name", "Section")
                text = chunk.get("text", "").strip()
                sections.append(f"[{i}] [{doc_id}: {sec}]\n{text}")

        if claims:
            sections.append("### Verified Evidence Claims:")
            for claim in claims:
                sections.append(f"- [{claim.get('evidence_id')}]: {claim.get('claim_text')}")

        return "\n\n".join(sections)
