"""
Markdown Loader for KRIYO Knowledge Documents.
Recursively loads markdown files from 02_knowledge_documents.
"""

import os
import glob
from typing import List, Dict, Any


class MarkdownLoader:
    def __init__(self, docs_dir: str):
        self.docs_dir = docs_dir

    def load_documents(self) -> List[Dict[str, Any]]:
        """
        Recursively finds and reads all markdown files under docs_dir.
        """
        documents = []
        pattern = os.path.join(self.docs_dir, "**", "*.md")
        md_files = glob.glob(pattern, recursive=True)

        for filepath in md_files:
            rel_path = os.path.relpath(filepath, self.docs_dir)
            folder_type = os.path.dirname(rel_path).replace("\\", "/")
            base_name = os.path.basename(filepath)
            doc_id = os.path.splitext(base_name)[0]

            try:
                with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
                    raw_content = f.read()

                documents.append({
                    "doc_id": doc_id,
                    "filepath": filepath,
                    "rel_path": rel_path,
                    "folder_type": folder_type,
                    "raw_content": raw_content
                })
            except Exception as e:
                print(f"[!] Error reading {filepath}: {e}")

        return documents
