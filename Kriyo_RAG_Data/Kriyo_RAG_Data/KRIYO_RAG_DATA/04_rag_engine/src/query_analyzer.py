"""
KRIYO Grounded RAG Engine — Query Analyzer & Intent Classifier
Classifies query intent into 10 fine-grained categories:
1. exact_entity_lookup
2. attribute_lookup
3. location_lookup
4. product_lookup
5. technique_lookup
6. artisan_lookup
7. comparison
8. multi_hop
9. ambiguous
10. unanswerable
"""

import re

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


class QueryAnalyzer:
    def __init__(self):
        pass

    def analyze_query(self, query: str) -> dict:
        """
        Analyzes and classifies query into intent, target attribute, and entity mentions.
        """
        q_lower = query.strip().lower()
        words = re.findall(r"\w+", q_lower)

        # Indian States List for State Index detection
        indian_states = [
            "kerala", "karnataka", "andhra pradesh", "telangana", "odisha", "west bengal",
            "rajasthan", "gujarat", "maharashtra", "madhya pradesh", "uttar pradesh", "bihar",
            "assam", "manipur", "meghalaya", "nagaland", "tripura", "sikkim",
            "himachal pradesh", "uttarakhand", "jammu & kashmir", "tamil nadu", "j&k"
        ]

        # 1. Unanswerable check (out-of-domain or ungrounded future projections / private personal data)
        for pat in UNANSWERABLE_PATTERNS:
            if re.search(pat, q_lower):
                return {
                    "intent": "unanswerable",
                    "query": query,
                    "target_attribute": None,
                    "is_out_of_domain": any(k in q_lower for k in ["cricket", "world cup", "football", "actor", "movie", "weather", "stock market"]),
                    "is_private_data": True,
                    "entities": [],
                    "keywords": words
                }

        # Identify target attribute keyword if present
        target_attr = None
        for attr, kw_list in ATTRIBUTE_KEYWORDS.items():
            if any(kw in q_lower for kw in kw_list):
                target_attr = attr
                break

        # 2. Comparison check (multi-entity)
        if any(k in words for k in ["compare", "difference", "versus", "vs", "better", "contrast", "differ"]):
            return {
                "intent": "comparison",
                "query": query,
                "target_attribute": target_attr,
                "is_out_of_domain": False,
                "is_private_data": False,
                "entities": [],
                "keywords": words
            }

        # 3. Ambiguous check
        if any(trig in q_lower for trig in ["decor item", "is best", "which saree", "best product", "famous saree", "best craft", "popular product"]) or (len(words) <= 5 and any(w in words for w in ["famous", "best", "popular"]) and not any(st in q_lower for st in indian_states)):
            return {
                "intent": "ambiguous",
                "query": query,
                "target_attribute": target_attr,
                "is_out_of_domain": False,
                "is_private_data": False,
                "entities": [],
                "keywords": words
            }

        # 4. State Index check (e.g. "What crafts are famous in Kerala?", "Which crafts come from Karnataka?")
        matched_state = None
        for st in indian_states:
            if st in q_lower:
                matched_state = st.title()
                break

        if matched_state and any(k in q_lower for k in ["craft", "crafts", "famous", "associated", "known for", "traditions", "found", "come from", "list"]):
            if not any(k in q_lower for k in ["material", "materials", "technique", "techniques", "cultural", "significance"]):
                return {
                    "intent": "state_index",
                    "query": query,
                    "target_state": matched_state,
                    "target_attribute": "state_crafts",
                    "is_out_of_domain": False,
                    "is_private_data": False,
                    "entities": [matched_state],
                    "keywords": words
                }

        # 5. Cultural check
        if any(k in q_lower for k in ["cultural significance", "cultural importance", "regional identity", "heritage"]):
            return {
                "intent": "cultural",
                "query": query,
                "target_attribute": "cultural_significance",
                "is_out_of_domain": False,
                "is_private_data": False,
                "entities": [],
                "keywords": words
            }

        # 6. Material Lookup check
        if any(k in q_lower for k in ["material", "materials", "made of", "made from", "what material"]):
            return {
                "intent": "material_lookup",
                "query": query,
                "target_attribute": "materials",
                "is_out_of_domain": False,
                "is_private_data": False,
                "entities": [],
                "keywords": words
            }

        # 7. Technique Lookup check
        if any(k in q_lower for k in ["technique", "techniques", "process", "ikat", "lacquer", "applique"]):
            return {
                "intent": "technique_lookup",
                "query": query,
                "target_attribute": "techniques",
                "is_out_of_domain": False,
                "is_private_data": False,
                "entities": [],
                "keywords": words
            }

        # 8. Location / Cluster / District Lookup check
        if any(k in q_lower for k in ["associated with", "come from", "located", "district", "cluster", "which craft is associated with"]):
            if not matched_state:
                return {
                    "intent": "location_lookup",
                    "query": query,
                    "target_attribute": "location",
                    "is_out_of_domain": False,
                    "is_private_data": False,
                    "entities": [],
                    "keywords": words
                }

        # 9. Product Lookup check
        if any(k in q_lower for k in ["produces", "produce", "product", "products", "wooden toys", "sarees in"]):
            return {
                "intent": "product_lookup",
                "query": query,
                "target_attribute": "products",
                "is_out_of_domain": False,
                "is_private_data": False,
                "entities": [],
                "keywords": words
            }

        # 10. Direct Entity / Definition check (e.g. "What is Pattachitra?", "What is Bidriware?")
        if q_lower.startswith("what is ") or q_lower.startswith("what are "):
            return {
                "intent": "direct_entity",
                "query": query,
                "target_attribute": "definition",
                "is_out_of_domain": False,
                "is_private_data": False,
                "entities": [],
                "keywords": words
            }

        # 11. Multi-hop check
        if ("craft" in q_lower and "artisan" in q_lower) or ("product" in q_lower and "buyer" in q_lower) or ("district" in q_lower and "technique" in q_lower):
            return {
                "intent": "multi_hop",
                "query": query,
                "target_attribute": target_attr,
                "is_out_of_domain": False,
                "is_private_data": False,
                "entities": [],
                "keywords": words
            }

        # 12. Exact Entity Lookup (C###, A###, P#####, T###, BUY###, PROV#####, EV#####)
        if any(re.search(r"\b" + pat + r"\b", q_lower) for pat in [r"c\d{3}", r"a\d{3}", r"p\d{5}", r"t\d{3}", r"buy\d{3}", r"ev\d{5}", r"prov\d{5}"]):
            return {
                "intent": "exact_entity_lookup",
                "query": query,
                "target_attribute": target_attr,
                "is_out_of_domain": False,
                "is_private_data": False,
                "entities": [],
                "keywords": words
            }

        return {
            "intent": "attribute_lookup",
            "query": query,
            "target_attribute": target_attr,
            "is_out_of_domain": False,
            "is_private_data": False,
            "entities": [],
            "keywords": words
        }
