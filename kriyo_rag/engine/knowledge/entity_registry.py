"""
Entity Registry for KRIYO Craft Knowledge Base.
Maintains canonical lookup tables for Crafts, Artisans, Products, and Techniques.
"""

from typing import Dict, Any, List, Optional
from ..ingestion.excel_loader import ExcelLoader
from ...config.settings import settings


class EntityRegistry:
    def __init__(self, structured_dir: Optional[str] = None):
        self.structured_dir = str(structured_dir or settings.STRUCTURED_DIR)
        self.loader = ExcelLoader(self.structured_dir)
        self._crafts = {}
        self._artisans = {}
        self._products = {}
        self._techniques = {}
        self._load()

    def _load(self):
        craft_rows = self.loader.load_sheet("KRIYO_Craft_Master.xlsx", "KRIYO_Craft_Master")
        for r in craft_rows:
            cid = str(r.get("craft_id", "")).strip().upper()
            if cid:
                self._crafts[cid] = r

        artisan_rows = self.loader.load_sheet("KRIYO_Artisan_Profiles.xlsx", "KRIYO_Artisan_Profiles")
        for r in artisan_rows:
            aid = str(r.get("artisan_id", "")).strip().upper()
            if aid:
                self._artisans[aid] = r

        product_rows = self.loader.load_sheet("KRIYO_Craft_Products.xlsx", "Products")
        for r in product_rows:
            pid = str(r.get("product_id", "")).strip().upper()
            if pid:
                self._products[pid] = r

        technique_rows = self.loader.load_sheet("KRIYO_Craft_Techniques.xlsx", "Techniques")
        for r in technique_rows:
            tid = str(r.get("technique_id", "")).strip().upper()
            if tid:
                self._techniques[tid] = r

    def get_craft(self, craft_id: str) -> Optional[Dict[str, Any]]:
        return self._crafts.get(craft_id.upper())

    def get_artisan(self, artisan_id: str) -> Optional[Dict[str, Any]]:
        return self._artisans.get(artisan_id.upper())

    def get_product(self, product_id: str) -> Optional[Dict[str, Any]]:
        return self._products.get(product_id.upper())

    def get_technique(self, technique_id: str) -> Optional[Dict[str, Any]]:
        return self._techniques.get(technique_id.upper())

    def all_crafts(self) -> List[Dict[str, Any]]:
        return list(self._crafts.values())
