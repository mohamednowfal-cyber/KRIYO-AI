"""
Safety, Evidence Bounds, and Refusal Policies.
Standard refusal messages for out-of-domain, missing evidence, and private data.
"""

INSUFFICIENT_EVIDENCE_MSG = (
    "I don't have sufficient evidence in the KRIYO knowledge base to answer that reliably."
)

OUT_OF_DOMAIN_MSG = (
    "The answer you are looking for is not available in the KRIYO knowledge base."
)

UNGROUNDED_PREDICTION_MSG = (
    "I don't have sufficient evidence in the KRIYO knowledge base to make speculative or future projections."
)

PRIVATE_DATA_REFUSAL_MSG = (
    "Personal contact details, financial information, and private identifiers are not available in the KRIYO knowledge base."
)


class RefusalPolicy:
    @staticmethod
    def get_refusal(reason: str) -> str:
        if reason == "out_of_domain":
            return OUT_OF_DOMAIN_MSG
        if reason == "private_data":
            return PRIVATE_DATA_REFUSAL_MSG
        if reason == "prediction":
            return UNGROUNDED_PREDICTION_MSG
        return INSUFFICIENT_EVIDENCE_MSG
