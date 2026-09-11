"""
Unit and Integration Tests for KRIYO RAG Components.
"""

from kriyo_rag.engine.understanding.query_analyzer import QueryAnalyzer
from kriyo_rag.engine.understanding.intent_classifier import IntentClassifier
from kriyo_rag.engine.understanding.language_detector import LanguageDetector
from kriyo_rag.engine.understanding.entity_resolver import EntityResolver
from kriyo_rag.engine.answering.refusal_policy import OUT_OF_DOMAIN_MSG, INSUFFICIENT_EVIDENCE_MSG


def test_language_detector_tamil():
    detector = LanguageDetector()
    res = detector.detect("காஞ்சிபுரம் பட்டு சேலை")
    assert res["language"] == "ta"
    assert res["script"] == "Tamil"


def test_language_detector_devanagari():
    detector = LanguageDetector()
    res = detector.detect("बनारसी साड़ी की विशेषताएं क्या हैं?")
    assert res["language"] == "hi"
    assert res["script"] == "Devanagari"


def test_intent_classifier_state_index():
    classifier = IntentClassifier()
    res = classifier.classify("What are the crafts of Tamil Nadu?")
    assert res["intent"] == "state_index"
    assert res["target_state"] == "Tamil Nadu"


def test_intent_classifier_out_of_domain():
    classifier = IntentClassifier()
    res = classifier.classify("Who won the cricket world cup?")
    assert res["intent"] == "unanswerable"
    assert res["is_out_of_domain"] is True


def test_intent_classifier_private_data():
    classifier = IntentClassifier()
    res = classifier.classify("Tell me the exact annual income and phone number of the weaver")
    assert res["intent"] == "unanswerable"
    assert res["is_private_data"] is True


def test_entity_resolver_aliases():
    resolver = EntityResolver()
    matches = resolver.resolve_entities("Tell me about Kanchi silk and swamimalai bronze")
    cids = [m["canonical_craft_id"] for m in matches]
    assert "C001" in cids
    assert "C003" in cids
