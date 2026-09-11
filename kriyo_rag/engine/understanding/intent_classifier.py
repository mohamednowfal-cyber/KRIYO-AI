"""
Fine-grained Intent Classifier for KRIYO RAG Engine.
Classifies query intent into 11 domain categories.
"""

import re
from typing import Dict, Any, List

UNANSWERABLE_PATTERNS = [
    r"exact\s+annual\s+income",
    r"annual\s+income\s+of",
    r"phone\s*number",
    r"aadhaar",
    r"bank\s*account",
    r"password",
    r"live\s*price",
    r"cricket",
    r"world\s*cup",
    r"football",
    r"actor",
    r"president",
    r"prime\s*minister",
    r"movie",
    r"weather",
    r"stock\s*market",
    r"\b203\d\b",
    r"\b204\d\b",
    r"\b205\d\b",
    r"export\s+value\s+projection",
    r"future\s+projection",
    r"exact\s+net\s+worth",
    r"personal\s+contact",
    r"most\s+profitable\s+craft\s+in",
    r"richest\s+artisan",
    r"biggest\s+craft"
]

ATTRIBUTE_KEYWORDS = {
    "materials": ["material", "materials", "silk", "cotton", "thread", "metal", "wood", "clay", "grass"],
    "tools": ["tool", "tools", "loom", "chisels", "crucible", "lathe", "shuttle"],
    "techniques": ["technique", "techniques", "process", "weaving", "casting", "embroidery", "carving"],
    "products": ["product", "products", "item", "saree", "lamp", "plate", "idol", "mat", "basket"],
    "location": ["district", "state", "located", "region", "cluster", "famous for", "in habited"],
    "price": ["price", "cost", "b2b", "value"],
    "gi": ["gi", "gi status", "registered"]
}


class IntentClassifier:
    def classify(self, query: str) -> Dict[str, Any]:
        q_lower = query.strip().lower()
        words = re.findall(r"\w+", q_lower)

        # 1. Unanswerable check
        for pat in UNANSWERABLE_PATTERNS:
            if re.search(pat, q_lower):
                is_out_of_domain = any(k in q_lower for k in ["cricket", "world cup", "football", "actor", "movie", "weather", "stock market"])
                return {
                    "intent": "unanswerable",
                    "target_attribute": None,
                    "is_out_of_domain": is_out_of_domain,
                    "is_private_data": True
                }

        # Target attribute
        target_attr = None
        for attr, kw_list in ATTRIBUTE_KEYWORDS.items():
            if any(kw in q_lower for kw in kw_list):
                target_attr = attr
                break

        # 2. Comparison
        if any(k in words for k in ["compare", "difference", "versus", "vs", "better", "contrast", "differ"]):
            return {"intent": "comparison", "target_attribute": target_attr}

        # 3. State Index
        indian_states = [
            "kerala", "karnataka", "andhra pradesh", "telangana", "odisha", "west bengal",
            "rajasthan", "gujarat", "maharashtra", "madhya pradesh", "uttar pradesh", "bihar",
            "assam", "manipur", "meghalaya", "nagaland", "tripura", "sikkim",
            "himachal pradesh", "uttarakhand", "jammu & kashmir", "tamil nadu", "j&k"
        ]
        if any(st in q_lower for st in indian_states) and any(w in words for w in ["what", "which", "list", "name", "all", "crafts", "craft", "handloom"]):
            for st in indian_states:
                if st in q_lower:
                    return {
                        "intent": "state_index",
                        "target_state": st.title(),
                        "target_attribute": "crafts"
                    }

        # 4. Multi-hop / Relational
        if any(phrase in q_lower for phrase in ["artisan making", "artisan who makes", "who crafts", "who weaves", "which artisan"]):
            return {"intent": "artisan_lookup", "target_attribute": "artisan"}

        # 5. Product lookup
        if any(k in words for k in ["product", "products", "item", "saree", "lamps", "toy", "sari", "shawl", "carpet"]):
            return {"intent": "product_lookup", "target_attribute": "products"}

        # 6. Technique lookup
        if any(k in words for k in ["technique", "process", "weaving", "casting", "dyeing", "tie and dye", "block print"]):
            return {"intent": "technique_lookup", "target_attribute": "techniques"}

        # 7. Location lookup
        if any(k in words for k in ["where", "origin", "originated", "district", "region", "cluster", "state", "from"]):
            return {"intent": "location_lookup", "target_attribute": "location"}

        # 8. Attribute lookup
        if target_attr:
            return {"intent": "attribute_lookup", "target_attribute": target_attr}

        # Default
        return {"intent": "exact_entity_lookup", "target_attribute": None}
