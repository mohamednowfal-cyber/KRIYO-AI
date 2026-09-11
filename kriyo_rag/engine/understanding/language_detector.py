"""
Language & Script Detector.
Detects English, Tamil, Hindi, or Indic transliteration in queries.
"""

import re
from typing import Dict, Any


class LanguageDetector:
    # Unicode blocks
    TAMIL_RANGE = re.compile(r"[\u0B80-\u0BFF]")
    DEVANAGARI_RANGE = re.compile(r"[\u0900-\u097F]")

    # Common transliteration phonetic tokens
    TAMIL_PHONETICS = ["vanakkam", "kaithari", "pattu", "seelai", "nool", "saree", "madurai", "kovil"]
    HINDI_PHONETICS = ["namaste", "hathkargha", "shilpkar", "bunkar", "banarasi", "chanderi", "sooti"]

    def detect(self, query: str) -> Dict[str, Any]:
        q = query.strip()
        has_tamil = bool(self.TAMIL_RANGE.search(q))
        has_devanagari = bool(self.DEVANAGARI_RANGE.search(q))

        if has_tamil:
            return {
                "language": "ta",
                "script": "Tamil",
                "is_transliterated": False
            }
        if has_devanagari:
            return {
                "language": "hi",
                "script": "Devanagari",
                "is_transliterated": False
            }

        q_lower = q.lower()
        if any(w in q_lower for w in self.TAMIL_PHONETICS):
            return {
                "language": "ta-Latn",
                "script": "Latin",
                "is_transliterated": True
            }

        if any(w in q_lower for w in self.HINDI_PHONETICS):
            return {
                "language": "hi-Latn",
                "script": "Latin",
                "is_transliterated": True
            }

        return {
            "language": "en",
            "script": "Latin",
            "is_transliterated": False
        }
