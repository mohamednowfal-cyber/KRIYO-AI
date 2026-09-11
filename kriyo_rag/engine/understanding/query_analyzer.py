"""
Unified Query Analyzer.
Combines Language Detection, Intent Classification, and Entity Resolution.
"""

import re
from typing import Dict, Any, List, Optional
from .language_detector import LanguageDetector
from .intent_classifier import IntentClassifier
from .entity_resolver import EntityResolver


class QueryAnalyzer:
    def __init__(self, structured_dir: Optional[str] = None):
        self.language_detector = LanguageDetector()
        self.intent_classifier = IntentClassifier()
        self.entity_resolver = EntityResolver(structured_dir=structured_dir)

    def analyze_query(self, query: str) -> Dict[str, Any]:
        """
        Analyzes query into language, intent, canonical entities, keywords, and routing signals.
        """
        q_clean = query.strip()
        lang_info = self.language_detector.detect(q_clean)
        intent_info = self.intent_classifier.classify(q_clean)
        entities = self.entity_resolver.resolve_entities(q_clean)

        words = re.findall(r"\w+", q_clean.lower())

        return {
            "query": q_clean,
            "language": lang_info["language"],
            "script": lang_info["script"],
            "is_transliterated": lang_info["is_transliterated"],
            "intent": intent_info["intent"],
            "target_attribute": intent_info.get("target_attribute"),
            "target_state": intent_info.get("target_state"),
            "is_out_of_domain": intent_info.get("is_out_of_domain", False),
            "is_private_data": intent_info.get("is_private_data", False),
            "entities": entities,
            "keywords": words
        }
