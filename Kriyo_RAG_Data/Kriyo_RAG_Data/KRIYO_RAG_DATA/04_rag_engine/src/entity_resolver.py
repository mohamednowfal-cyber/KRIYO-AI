"""
KRIYO RAG Engine — Canonical Entity & Location Resolver
Integrates KRIYO_Entity_Aliases.xlsx and KRIYO_Location_Gazetteer.xlsx
Maps synonyms, local names, and location clusters to canonical craft IDs (C001–C150).
"""

import os
import re
import openpyxl

STRUCTURED_DIR = r"D:\Kriyo_RAG_Data\KRIYO_RAG_DATA\01_structured"


class EntityResolver:
    def __init__(self, structured_dir: str = STRUCTURED_DIR):
        self.structured_dir = structured_dir
        self.alias_map = {}      # alias_lower -> craft_id
        self.location_map = {}   # location_lower -> list of craft_ids
        self.craft_name_map = {} # craft_id -> canonical_name
        self._load_registries()

    def _load_registries(self):
        """Loads canonical entity maps from Excel registries."""
        # 1. Load Craft Master
        master_path = os.path.join(self.structured_dir, "KRIYO_Craft_Master.xlsx")
        if os.path.exists(master_path):
            try:
                wb = openpyxl.load_workbook(master_path, data_only=True)
                sheet = wb["KRIYO_Craft_Master"]
                for r in range(2, sheet.max_row + 1):
                    cid = sheet.cell(r, 1).value
                    cname = sheet.cell(r, 2).value
                    if cid and cname:
                        cid = str(cid).strip().upper()
                        cname = str(cname).strip()
                        self.craft_name_map[cid] = cname
                        self.alias_map[cname.lower()] = cid
                        self.alias_map[cid.lower()] = cid
            except Exception:
                pass

        # 2. Load Location Gazetteer
        gazetteer_path = os.path.join(self.structured_dir, "KRIYO_Location_Gazetteer.xlsx")
        if os.path.exists(gazetteer_path):
            try:
                wb = openpyxl.load_workbook(gazetteer_path, data_only=True)
                sheet = wb["Gazetteer"]
                for r in range(2, sheet.max_row + 1):
                    loc_name = sheet.cell(r, 2).value
                    alt_names = sheet.cell(r, 3).value
                    rel_crafts = sheet.cell(r, 8).value

                    craft_list = [c.strip().upper() for c in str(rel_crafts).split(",") if c.strip()]
                    if loc_name and craft_list:
                        loc_key = str(loc_name).strip().lower()
                        self.location_map[loc_key] = craft_list

                    if alt_names and craft_list:
                        for alt in str(alt_names).split(","):
                            if alt.strip():
                                self.location_map[alt.strip().lower()] = craft_list
            except Exception:
                pass

        # 3. Load Entity Aliases
        aliases_path = os.path.join(self.structured_dir, "KRIYO_Entity_Aliases.xlsx")
        if os.path.exists(aliases_path):
            try:
                wb = openpyxl.load_workbook(aliases_path, data_only=True)
                sheet = wb["Aliases"]
                for r in range(2, sheet.max_row + 1):
                    alias = sheet.cell(r, 2).value
                    cid = sheet.cell(r, 3).value
                    if alias and cid:
                        self.alias_map[str(alias).strip().lower()] = str(cid).strip().upper()
            except Exception:
                pass

        # Hardcoded canonical aliases matching exact KRIYO_Craft_Master.xlsx
        hardcoded_aliases = {
            "kanchipuram": "C001",
            "kanchi": "C001",
            "kanchipuram silk": "C001",
            "kanchipuram silk weaving": "C001",
            "thanjavur painting": "C002",
            "tanjore painting": "C002",
            "thanjavur bronze": "C003",
            "thanjavur bronze casting": "C003",
            "swamimalai bronze": "C003",
            "chettinad": "C004",
            "chettinad athangudi": "C004",
            "chettinad kottan": "C007",
            "sungudi": "C005",
            "sungudi saree": "C005",
            "madurai sungudi": "C005",
            "nachiarkoil": "C006",
            "nachiarkoil brass": "C006",
            "nachiarkoil lamps": "C006",
            "pattamadai": "C007",
            "pattamadai mat": "C007",
            "pattamadai grass mat": "C007",
            "korai grass": "C007",
            "thanjavur doll": "C008",
            "karuppur kalamkari": "C009",
            "coimbatore cotton": "C010",
            "toda embroidery": "C085",
            "toda": "C085"
        }
        for k, v in hardcoded_aliases.items():
            self.alias_map[k.lower()] = v

        hardcoded_gazetteer = {
            "kanchipuram": ["C001"],
            "kanchi": ["C001"],
            "thanjavur": ["C002", "C003", "C008", "C025", "C104"],
            "tanjore": ["C002", "C003", "C008", "C025", "C104"],
            "swamimalai": ["C003"],
            "madurai": ["C005"],
            "pattamadai": ["C007"],
            "chettinad": ["C004", "C007"],
            "sivaganga": ["C004", "C007"],
            "nilgiris": ["C085"],
            "coimbatore": ["C010"],
            "nachiarkoil": ["C006"],
            "tirunelveli": ["C007"]
        }
        for loc, cids in hardcoded_gazetteer.items():
            self.location_map[loc] = cids

    def resolve_entities(self, query: str) -> list[dict]:
        """
        Resolves query terms to one or more canonical entities.
        Supports multi-entity extraction for comparison queries.
        """
        q_lower = query.lower()
        found_entities = []
        seen_cids = set()

        # Direct regex check for C###
        c_matches = re.findall(r"\b(c\d{3})\b", q_lower)
        for cm in c_matches:
            cid = cm.upper()
            if cid not in seen_cids:
                seen_cids.add(cid)
                found_entities.append({
                    "craft_id": cid,
                    "craft_name": self.craft_name_map.get(cid, cid),
                    "matched_alias": cid,
                    "match_type": "exact_id"
                })

        # Alias Map Lookup
        for alias, cid in sorted(self.alias_map.items(), key=lambda x: len(x[0]), reverse=True):
            if alias in q_lower and cid not in seen_cids:
                seen_cids.add(cid)
                found_entities.append({
                    "craft_id": cid,
                    "craft_name": self.craft_name_map.get(cid, alias.title()),
                    "matched_alias": alias,
                    "match_type": "alias"
                })

        # Location Gazetteer Lookup
        for loc, cids in sorted(self.location_map.items(), key=lambda x: len(x[0]), reverse=True):
            if loc in q_lower:
                for cid in cids:
                    if cid not in seen_cids:
                        seen_cids.add(cid)
                        found_entities.append({
                            "craft_id": cid,
                            "craft_name": self.craft_name_map.get(cid, loc.title()),
                            "matched_alias": loc,
                            "match_type": "location"
                        })

        return found_entities

    def resolve_craft(self, query: str) -> dict:
        """Helper to return top resolved craft entity."""
        entities = self.resolve_entities(query)
        return entities[0] if entities else None
