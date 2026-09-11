"""
Phone number normalization, validation, and masking utilities.
Primary focus on Indian mobile numbers (+91) with global E.164 fallback.
"""

import re
from typing import Optional
import phonenumbers
from phonenumbers import NumberParseException, PhoneNumberFormat


def normalize_phone_number(raw_phone: str, default_region: str = "IN") -> str:
    """
    Normalizes any mobile number to E.164 international format (e.g., +919876543210).
    Raises ValueError if number is invalid.
    """
    cleaned = re.sub(r"[\s\-\(\)]+", "", raw_phone.strip())
    if not cleaned:
        raise ValueError("Phone number cannot be empty")

    try:
        parsed = phonenumbers.parse(cleaned, default_region)
        if not phonenumbers.is_valid_number(parsed):
            raise ValueError(f"Invalid phone number: {raw_phone}")
        return phonenumbers.format_number(parsed, PhoneNumberFormat.E164)
    except NumberParseException:
        # Fallback heuristic for standard 10-digit Indian numbers
        digits_only = re.sub(r"\D", "", cleaned)
        if len(digits_only) == 10 and digits_only[0] in "6789":
            return f"+91{digits_only}"
        elif len(digits_only) == 12 and digits_only.startswith("91") and digits_only[2] in "6789":
            return f"+{digits_only}"
        raise ValueError(f"Could not parse phone number: {raw_phone}")


def mask_phone_number(e164_phone: str) -> str:
    """
    Masks a phone number for privacy display.
    Example: +919876543210 -> +91 ******3210
    """
    if len(e164_phone) >= 7:
        prefix = e164_phone[:3]
        suffix = e164_phone[-4:]
        return f"{prefix} ******{suffix}"
    return e164_phone
