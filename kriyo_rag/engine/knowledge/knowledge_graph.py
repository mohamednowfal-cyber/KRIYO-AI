"""
In-Memory Knowledge Graph.
Combines EntityRegistry and RelationshipResolver for graph-style entity inspection.
"""

from typing import Dict, Any, List, Optional
from .entity_registry import EntityRegistry
from .relationship_resolver import RelationshipResolver


class KnowledgeGraph:
    def __init__(self, structured_dir: Optional[str] = None):
        self.entity_registry = EntityRegistry(structured_dir)
        self.relationship_resolver = RelationshipResolver(structured_dir)

    def get_full_craft_context(self, craft_id: str) -> Dict[str, Any]:
        cid = craft_id.upper()
        craft = self.entity_registry.get_craft(cid)
        if not craft:
            return {}

        product_ids = self.relationship_resolver.get_products_for_craft(cid)
        products = [self.entity_registry.get_product(pid) for pid in product_ids if self.entity_registry.get_product(pid)]

        artisan_ids = self.relationship_resolver.get_artisans_for_craft(cid)
        artisans = [self.entity_registry.get_artisan(aid) for aid in artisan_ids if self.entity_registry.get_artisan(aid)]

        technique_ids = self.relationship_resolver.get_techniques_for_craft(cid)
        techniques = [self.entity_registry.get_technique(tid) for tid in technique_ids if self.entity_registry.get_technique(tid)]

        return {
            "craft": craft,
            "products": products,
            "artisans": artisans,
            "techniques": techniques
        }
