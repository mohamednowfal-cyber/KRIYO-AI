"""
KRIYO Synthetic Demo RAG Ingestion Module
Ingests all Markdown files from 02_knowledge_documents, parses metadata,
and chunks content by Markdown section headings.
"""

import os
import re
import glob
import yaml

METADATA_TABLE_REGEX = re.compile(
    r"\|\s*([A-Za-z0-9_\-]+)\s*\|\s*(.*?)\s*\|"
)

HEADER_REGEX = re.compile(r"^(#{1,3})\s+(.+)$", re.MULTILINE)
ANCHOR_REGEX = re.compile(r"\s*\{#[A-Za-z0-9_\-]+\}\s*$")


def clean_section_name(title: str) -> str:
    """Remove Markdown anchors like {#craft_overview} and formatting."""
    cleaned = ANCHOR_REGEX.sub("", title.strip())
    cleaned = re.sub(r"[\*`_]", "", cleaned)
    return cleaned.strip()


def parse_metadata(content: str, default_doc_id: str = "") -> dict:
    """
    Extract metadata from YAML front matter or Markdown metadata table.
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

    # 1. Parse YAML Front Matter if present
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

    # 2. Parse Markdown Table if present
    for line in content.splitlines():
        match = METADATA_TABLE_REGEX.match(line.strip())
        if match:
            key = match.group(1).strip().lower()
            val = match.group(2).strip()
            # Ignore table header line
            if key in ["field", "---", ":---", "---:"]:
                continue
            if key in meta:
                meta[key] = val
            elif key == "topic" and not meta["title"]:
                meta["title"] = val

    # Fallback title extraction from first H1 header
    if not meta["title"]:
        h1_match = re.search(r"^#\s+(.+)$", content, re.MULTILINE)
        if h1_match:
            meta["title"] = clean_section_name(h1_match.group(1))

    return meta


def chunk_document(filepath: str, root_docs_dir: str) -> list[dict]:
    """
    Reads a single Markdown document, parses metadata, and chunks text by section headers (# or ##).
    """
    with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
        content = f.read()

    rel_path = os.path.relpath(filepath, root_docs_dir)
    path_parts = rel_path.split(os.sep)
    folder_type = path_parts[0] if len(path_parts) > 1 else "unknown"

    base_name = os.path.basename(filepath)
    default_doc_id = os.path.splitext(base_name)[0]

    metadata = parse_metadata(content, default_doc_id=default_doc_id)
    doc_id = metadata["document_id"] or default_doc_id

    # Split document by headers
    # Find all header positions
    header_matches = list(HEADER_REGEX.finditer(content))
    chunks = []

    if not header_matches:
        # Single section document
        text = content.strip()
        if text:
            chunks.append({
                "chunk_id": f"{doc_id}#full",
                "document_id": doc_id,
                "title": metadata["title"],
                "section_name": "Main",
                "filepath": filepath,
                "craft_id": metadata["craft_id"],
                "craft_name": metadata["craft_name"],
                "data_status": metadata["data_status"],
                "folder_type": folder_type,
                "text": text
            })
        return chunks

    # Process preamble before first header if it contains text other than front matter / metadata table
    preamble = content[:header_matches[0].start()].strip()
    # Remove front matter or metadata table from preamble
    cleaned_preamble = re.sub(r"---.*?---", "", preamble, flags=re.DOTALL)
    cleaned_preamble = re.sub(r"\|.*\|", "", cleaned_preamble)
    cleaned_preamble = cleaned_preamble.strip()
    if len(cleaned_preamble) > 50:
        chunks.append({
            "chunk_id": f"{doc_id}#preamble",
            "document_id": doc_id,
            "title": metadata["title"],
            "section_name": "Preamble / Notice",
            "filepath": filepath,
            "craft_id": metadata["craft_id"],
            "craft_name": metadata["craft_name"],
            "data_status": metadata["data_status"],
            "folder_type": folder_type,
            "text": cleaned_preamble
        })

    for i, match in enumerate(header_matches):
        raw_header = match.group(2)
        section_name = clean_section_name(raw_header)

        start_pos = match.end()
        end_pos = header_matches[i + 1].start() if (i + 1) < len(header_matches) else len(content)

        section_body = content[start_pos:end_pos].strip()

        # Clean metadata tables or notices from top of section if present
        section_text_clean = re.sub(r"\|.*\|", "", section_body).strip()
        
        # We store the section text with header title prefixed for context awareness
        full_chunk_text = f"{section_name}\n\n{section_body}".strip()

        # Skip empty or negligible chunks (e.g. metadata table only)
        if len(section_text_clean) < 30 and "DOCUMENT METADATA" in section_name.upper():
            continue

        if section_body:
            sec_slug = re.sub(r"[^a-zA-Z0-9]", "_", section_name).lower()
            chunk_idx = len(chunks) + 1
            chunk_id = f"{doc_id}#{sec_slug}_{chunk_idx:03d}"
            
            chunks.append({
                "chunk_id": chunk_id,
                "document_id": doc_id,
                "title": metadata["title"],
                "section_name": section_name,
                "filepath": filepath,
                "craft_id": metadata["craft_id"],
                "craft_name": metadata["craft_name"],
                "data_status": metadata["data_status"],
                "folder_type": folder_type,
                "text": full_chunk_text
            })

    return chunks


def ingest_corpus(docs_root: str) -> list[dict]:
    """
    Ingests all Markdown documents recursively under docs_root.
    Returns list of chunk objects.
    """
    if not os.path.exists(docs_root):
        raise FileNotFoundError(f"Corpus root directory not found: {docs_root}")

    md_files = glob.glob(os.path.join(docs_root, "**", "*.md"), recursive=True)
    md_files = sorted(md_files)

    all_chunks = []
    print(f"[*] Discovered {len(md_files)} Markdown documents in {docs_root}")

    for filepath in md_files:
        doc_chunks = chunk_document(filepath, docs_root)
        all_chunks.extend(doc_chunks)

    print(f"[*] Ingested {len(md_files)} files into {len(all_chunks)} chunks.")
    return all_chunks


if __name__ == "__main__":
    test_root = r"D:\Kriyo_RAG_Data\KRIYO_RAG_DATA\02_knowledge_documents"
    chunks = ingest_corpus(test_root)
    if chunks:
        print(f"[Sample Chunk]\nID: {chunks[0]['chunk_id']}\nSection: {chunks[0]['section_name']}\nText Snippet: {chunks[0]['text'][:150]}...")
