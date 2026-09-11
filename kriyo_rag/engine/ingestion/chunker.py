"""
Recursive Markdown Section Chunker.
Splits documents by hierarchical headers (# and ##) into semantic chunks.
"""

import re
from typing import List, Dict, Any
from .metadata_builder import MetadataBuilder, clean_section_name

HEADER_REGEX = re.compile(r"^(#{1,3})\s+(.+)$", re.MULTILINE)


class MarkdownChunker:
    def __init__(self):
        self.metadata_builder = MetadataBuilder()

    def chunk_document(self, document_data: Dict[str, Any]) -> List[Dict[str, Any]]:
        """
        Chunks a single document into section-level chunk records.
        """
        raw_content = document_data["raw_content"]
        filepath = document_data["filepath"]
        rel_path = document_data["rel_path"]
        folder_type = document_data["folder_type"]
        default_doc_id = document_data["doc_id"]

        metadata = self.metadata_builder.parse_metadata(raw_content, default_doc_id=default_doc_id)
        doc_id = metadata["document_id"] or default_doc_id

        header_matches = list(HEADER_REGEX.finditer(raw_content))
        chunks = []

        if not header_matches:
            # Single-chunk document
            text = raw_content.strip()
            if text:
                chunk_id = f"{doc_id}#c0"
                chunks.append({
                    "chunk_id": chunk_id,
                    "document_id": doc_id,
                    "title": metadata["title"] or doc_id,
                    "section_name": "Full Document",
                    "filepath": filepath,
                    "rel_path": rel_path,
                    "craft_id": metadata["craft_id"],
                    "craft_name": metadata["craft_name"],
                    "data_status": metadata["data_status"],
                    "folder_type": folder_type,
                    "text": text,
                })
            return chunks

        # Process each section
        for i, match in enumerate(header_matches):
            section_title_raw = match.group(2)
            section_name = clean_section_name(section_title_raw)

            # Determine content span
            start_pos = match.start()
            end_pos = header_matches[i + 1].start() if i + 1 < len(header_matches) else len(raw_content)
            section_text = raw_content[start_pos:end_pos].strip()

            if not section_text or len(section_text) < 15:
                continue

            chunk_id = f"{doc_id}#c{i}_{section_name.replace(' ', '_')[:25]}"

            chunks.append({
                "chunk_id": chunk_id,
                "document_id": doc_id,
                "title": metadata["title"] or doc_id,
                "section_name": section_name,
                "filepath": filepath,
                "rel_path": rel_path,
                "craft_id": metadata["craft_id"],
                "craft_name": metadata["craft_name"],
                "data_status": metadata["data_status"],
                "folder_type": folder_type,
                "text": section_text,
            })

        return chunks

    def chunk_all(self, documents: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        all_chunks = []
        for doc in documents:
            chunks = self.chunk_document(doc)
            all_chunks.extend(chunks)
        return all_chunks
