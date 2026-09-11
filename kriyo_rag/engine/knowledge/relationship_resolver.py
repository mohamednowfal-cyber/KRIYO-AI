"""
Relationship Resolver for Multi-Hop Graph Traversal.
Traverses Craft -> Techniques -> Products -> Artisans -> Clusters.
"""

from typing import Dict, Any, List, Optional
from ..ingestion.excel_loader import ExcelLoader
from ...config.settings import settings


class RelationshipResolver:
    def __init__(self, structured_dir: Optional[str] = None):
        self.structured_dir = str(structured_dir or settings.STRUCTURED_DIR)
        self.loader = ExcelLoader(self.structured_dir)
        self.craft_to_products = {}
        self.craft_to_artisans = {}
        self.craft_to_techniques = {}
        self._build_relations()

    def _build_relations(self):
        # 1. Product relationships
        rel_rows = self.loader.load_sheet("KRIYO_Craft_Product_Relationships.xlsx", "Relationships")
        for r in rel_rows:
            cid = str(r.get("craft_id", "")).strip().upper()
            pid = str(r.get("product_id", "")).strip().upper()
            if cid and pid:
                self.craft_to_products.setdefault(cid, []).append(pid)

        # Fallback to Craft Products table
        prod_rows = self.loader.load_sheet("KRIYO_Craft_Products.xlsx", "Products")
        for r in prod_rows:
            cid = str(r.get("craft_id", "")).strip().upper()
            pid = str(r.get("product_id", "")).strip().upper()
            if cid and pid and pid not in self.craft_to_products.get(cid, []):
                self.craft_to_products.setdefault(cid, []).append(pid)

        # 2. Artisan relationships
        artisan_rows = self.loader.load_sheet("KRIYO_Artisan_Profiles.xlsx", "KRIYO_Artisan_Profiles")
        for r in artisan_rows:
            cid = str(r.get("craft_id", "")).strip().upper()
            aid = str(r.get("artisan_id", "")).strip().upper()
            if cid and aid:
                self.craft_to_artisans.setdefault(cid, []).append(aid)

        # 3. Technique relationships
        tech_rows = self.loader.load_sheet("KRIYO_Craft_Techniques.xlsx", "Techniques")
        for r in tech_rows:
            cid = str(r.get("craft_id", "")).strip().upper()
            tid = str(r.get("technique_id", "")).strip().upper()
            if cid and tid:
                self.craft_to_techniques.setdefault(cid, []).append(tid)

    def get_products_for_craft(self, craft_id: str) -> List[str]:
        return self.craft_to_products.get(craft_id.upper(), [])

    def get_artisans_for_craft(self, craft_id: str) -> List[str]:
        return self.craft_to_artisans.get(craft_id.upper(), [])

    def get_techniques_for_craft(self, craft_id: str) -> List[str]:
        return self.craft_to_techniques.get(craft_id.upper(), [])
