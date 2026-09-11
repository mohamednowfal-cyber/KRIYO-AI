"""
Validation helpers for user inputs, IDs, and domain rules.
"""

import re


def validate_aadhaar_last_four(val: str) -> bool:
    """Validate that the string consists of exactly 4 numeric digits."""
    return bool(re.fullmatch(r"^\d{4}$", val.strip()))


def validate_full_name(name: str) -> bool:
    """Validate full name (at least 2 characters, alphabets, spaces, and hyphens)."""
    cleaned = name.strip()
    return len(cleaned) >= 2 and bool(re.match(r"^[a-zA-Z\s\.\'-]+$", cleaned))
