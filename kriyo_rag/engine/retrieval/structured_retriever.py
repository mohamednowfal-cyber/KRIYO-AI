"""
Structured Excel Retriever.
Provides fast in-memory structured queries over 01_structured Excel datasets.
"""

import os
import re
from typing import List, Dict, Any, Optional
from ..ingestion.excel_loader import ExcelLoader
from ...config.settings import settings


class StructuredRetriever:
    def __init__(self, structured_dir: Optional[str] = None):
        self.structured_dir = str(structured_dir or settings.STRUCTURED_DIR)
        self.loader = ExcelLoader(self.structured_dir)
        self.cache = self.loader.load_all_key_workbooks()

    def search_craft_by_id(self, craft_id: str) -> Optional[Dict[str, Any]]:
        crafts_data = self.cache.get("crafts", {}).get("records", [])
        cid_upper = craft_id.upper()
        for r in crafts_data:
            if str(r.get("craft_id", "")).upper() == cid_upper:
                return r
        return None

    def search_crafts_by_state(self, state_name: str) -> List[Dict[str, Any]]:
        crafts_data = self.cache.get("crafts", {}).get("records", [])
        st_lower = state_name.strip().lower()
        matched = []
        for r in crafts_data:
            if str(r.get("state", "")).strip().lower() == st_lower:
                matched.append(r)
        return matched

    def search_products(self, query: str, craft_id: Optional[str] = None, max_results: int = 5) -> List[Dict[str, Any]]:
        prods = self.cache.get("products", {}).get("records", [])
        q_words = [w.lower() for w in query.split() if len(w) > 2]
        hits = []

        for r in prods:
            if craft_id and str(r.get("craft_id", "")).upper() != craft_id.upper():
                continue
            text = f"{r.get('product_name', '')} {r.get('description', '')} {r.get('craft_name', '')}".lower()
            match_count = sum(1 for w in q_words if w in text)
            if match_count > 0 or not q_words:
                hits.append((match_count, r))

        hits.sort(key=lambda x: x[0], reverse=True)
        return [h[1] for h in hits[:max_results]]

    def search_artisans(self, craft_id: Optional[str] = None, name_query: Optional[str] = None) -> List[Dict[str, Any]]:
        artisans = self.cache.get("artisans", {}).get("records", [])
        matched = []
        for a in artisans:
            if craft_id and str(a.get("craft_id", "")).upper() != craft_id.upper():
                continue
            if name_query:
                if name_query.lower() not in str(a.get("artisan_name", "")).lower():
                    continue
            matched.append(a)
        return matched

    def search_techniques(self, craft_id: Optional[str] = None, query: Optional[str] = None) -> List[Dict[str, Any]]:
        techniques = self.cache.get("techniques", {}).get("records", [])
        matched = []
        for t in techniques:
            if craft_id and str(t.get("craft_id", "")).upper() != craft_id.upper():
                continue
            if query:
                text = f"{t.get('technique_name', '')} {t.get('summary', '')}".lower()
                if not any(w in text for w in query.lower().split() if len(w) > 2):
                    continue
            matched.append(t)
        return matched

    def search_b2b_buyers(self, craft_id: Optional[str] = None, buyer_type: Optional[str] = None) -> List[Dict[str, Any]]:
        buyers = self.cache.get("b2b", {}).get("records", [])
        matched = []
        for b in buyers:
            if craft_id and craft_id.upper() not in str(b.get("preferred_craft_ids", "")).upper():
                continue
            if buyer_type and buyer_type.lower() not in str(b.get("buyer_type", "")).lower():
                continue
            matched.append(b)
        return matched
