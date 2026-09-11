"""
Provenance Formatter.
Attaches synthetic demo notice and formal source provenance to responses.
"""

SYNTHETIC_DEMO_NOTICE = (
    "\n\n*(Note: All facts and sources referenced above are from the KRIYO synthetic_demo dataset for RAG testing only.)*"
)


class ProvenanceFormatter:
    @staticmethod
    def format_provenance(answer_text: str, citations: list[str] | None = None) -> str:
        clean_text = answer_text.strip()
        if not clean_text.endswith(SYNTHETIC_DEMO_NOTICE.strip()):
            clean_text = f"{clean_text}{SYNTHETIC_DEMO_NOTICE}"
        return clean_text
