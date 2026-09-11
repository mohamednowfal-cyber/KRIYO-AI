"""
Metadata Builder for KRIYO Ingestion Pipeline.
Extracts YAML front matter, metadata tables, and document attributes.
"""

import re
import yaml
from typing import Dict, Any

METADATA_TABLE_REGEX = re.compile(r"\|\s*([A-Za-z0-9_\-]+)\s*\|\s*(.*?)\s*\|")
ANCHOR_REGEX = re.compile(r"\s*\{#[A-Za-z0-9_\-]+\}\s*$")


def clean_section_name(title: str) -> str:
    """Remove Markdown anchors like {#craft_overview} and markdown markers."""
    cleaned = ANCHOR_REGEX.sub("", title.strip())
    cleaned = re.sub(r"[\*`_]", "", cleaned)
    return cleaned.strip()


class MetadataBuilder:
    @staticmethod
    def parse_metadata(content: str, default_doc_id: str = "") -> Dict[str, Any]:
        """
        Extract metadata from YAML front matter or Markdown table.
        """
        meta = {
            "document_id": default_doc_id,
            "title": "",
            "craft_id": "",
            "craft_name": "",
            "state": "",
            "data_status": "synthetic_demo",
            "document_type": "",
        }

        # 1. Parse YAML Front Matter
        if content.startswith("---"):
            parts = content.split("---", 2)
            if len(parts) >= 3:
                try:
                    yaml_data = yaml.safe_load(parts[1])
                    if isinstance(yaml_data, dict):
                        for k, v in yaml_data.items():
                            if k in meta and v:
                                meta[k] = str(v).strip()
                except Exception:
                    pass

        # 2. Parse Markdown Table
        for line in content.splitlines():
            match = METADATA_TABLE_REGEX.match(line.strip())
            if match:
                key = match.group(1).strip().lower()
                val = match.group(2).strip()
                if key in ["field", "---", ":---", "---:"]:
                    continue
                if key in meta:
                    meta[key] = val
                elif key == "topic" and not meta["title"]:
                    meta["title"] = val

        # 3. Fallback title extraction from first H1 header
        if not meta["title"]:
            h1_match = re.search(r"^#\s+(.+)$", content, re.MULTILINE)
            if h1_match:
                meta["title"] = clean_section_name(h1_match.group(1))

        return meta
