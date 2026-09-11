"""
Canonical Entity & Location Resolver.
Integrates KRIYO_Entity_Aliases.xlsx and KRIYO_Location_Gazetteer.xlsx.
Maps synonyms, local names, and location clusters to canonical craft IDs (C001–C150).
"""

import os
import re
from typing import List, Dict, Any, Optional
import openpyxl  # type: ignore
from ...config.settings import settings


class EntityResolver:
    def __init__(self, structured_dir: Optional[str] = None):
        self.structured_dir = str(structured_dir or settings.STRUCTURED_DIR)
        self.alias_map: Dict[str, str] = {}
        self.location_map: Dict[str, List[str]] = {}
        self.craft_name_map: Dict[str, str] = {}
        self._load_registries()

    def _load_registries(self):
        """Loads canonical entity maps from Excel registries."""
        # 1. Load Craft Master
        master_path = os.path.join(self.structured_dir, "KRIYO_Craft_Master.xlsx")
        if os.path.exists(master_path):
            try:
                wb = openpyxl.load_workbook(master_path, data_only=True)
                sheet = wb["KRIYO_Craft_Master"]
                max_r = sheet.max_row or 0
                for r in range(2, max_r + 1):
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
                max_r = sheet.max_row or 0
                for r in range(2, max_r + 1):
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
                max_r = sheet.max_row or 0
                for r in range(2, max_r + 1):
                    alias = sheet.cell(r, 2).value
                    cid = sheet.cell(r, 3).value
                    if alias and cid:
                        self.alias_map[str(alias).strip().lower()] = str(cid).strip().upper()
            except Exception:
                pass

        # Hardcoded canonical aliases
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
            "toda": "C008",
            "toda embroidery": "C008",
            "bhavani": "C009",
            "bhavani jamakkalam": "C009",
            "vilachery": "C010",
            "vilachery clay toys": "C010",
            "dharmavaram": "C011",
            "kalamkari": "C012",
            "machilipatnam": "C012",
            "srikalahasti": "C012",
            "kondapalli": "C013",
            "uppada": "C014",
            "bidri": "C021",
            "bidriware": "C021",
            "channapatna": "C022",
            "channapatna toys": "C022",
            "mysore silk": "C023",
            "ilkal": "C024",
            "ilkal saree": "C024",
            "aranmula": "C031",
            "aranmula kannadi": "C031",
            "aranmula metal mirror": "C031",
            "kasaragod": "C032",
            "kasaragod saree": "C032",
            "bell metal": "C033",
            "screw pine": "C034",
            "pochampally": "C041",
            "pochampally ikat": "C041",
            "gadwal": "C042",
            "pembarthi": "C043",
            "dhokra": "C044",
            "cheriyal": "C045",
            "banaras": "C051",
            "banarasi silk": "C051",
            "chikankari": "C052",
            "lucknow chikankari": "C052",
            "blue pottery": "C061",
            "jaipur blue pottery": "C061",
            "sanganeri": "C062",
            "sanganeri print": "C062",
            "pashmina": "C071",
            "kashmir pashmina": "C071",
            "kani": "C072",
            "kani shawl": "C072",
            "patola": "C081",
            "patan patola": "C081",
            "ajrakh": "C082",
            "muga": "C091",
            "muga silk": "C091",
            "assam silk": "C091",
            "sambalpuri": "C101",
            "sambalpuri saree": "C101"
        }
        for k, v in hardcoded_aliases.items():
            if k not in self.alias_map:
                self.alias_map[k] = v

    def resolve_entities(self, query: str) -> List[Dict[str, Any]]:
        """
        Extracts and resolves entity mentions in query to canonical craft IDs.
        """
        q_lower = query.lower()
        resolved = []
        matched_cids = set()

        sorted_aliases = sorted(self.alias_map.keys(), key=lambda x: len(x), reverse=True)
        for alias in sorted_aliases:
            if re.search(rf"\b{re.escape(alias)}\b", q_lower):
                cid = self.alias_map[alias]
                if cid not in matched_cids:
                    matched_cids.add(cid)
                    resolved.append({
                        "mention": alias,
                        "canonical_craft_id": cid,
                        "canonical_name": self.craft_name_map.get(cid, alias.title()),
                        "match_type": "alias"
                    })

        for loc, cids in self.location_map.items():
            if re.search(rf"\b{re.escape(loc)}\b", q_lower):
                for cid in cids:
                    if cid not in matched_cids:
                        matched_cids.add(cid)
                        resolved.append({
                            "mention": loc,
                            "canonical_craft_id": cid,
                            "canonical_name": self.craft_name_map.get(cid, loc.title()),
                            "match_type": "location_cluster"
                        })

        return resolved
