# KRIYO Grounded RAG — Golden Evaluation Report

**Benchmark Timestamp**: 2026-09-11T19:20:41.966362  
**Total Questions Evaluated**: 150  
**Passed Questions**: 145 (96.67%)  
**Failed Questions**: 5  

## Summary Performance Metrics

| Metric | Score | Status |
| :--- | :--- | :--- |
| **Retrieval Recall** | `1.0` | PASS |
| **Answer Correctness** | `0.9537` | PASS |
| **Evidence Coverage** | `0.8` | PASS |
| **Groundedness** | `1.0` | PASS |
| **Hallucination Rate** | `0.0` | ZERO HALLUCINATIONS |
| **Abstention Accuracy** | `0.9667` | PASS |
| **Citation Accuracy** | `1.0` | PASS |
| **Irrelevant Retrieval Rate** | `0.0142` | OPTIMAL |

---

## Failing Questions & Recommended Fixes

Total failing questions: 5

### Question: What crafts are famous in Kerala? (Query Variation 106)
- **Retrieved Sources**: DOC001, KRIYO_Craft_Master.xlsx
- **Expected Answer**: Famous crafts of Kerala include Aranmula Kannadi metal mirrors, Kasavu handloom weaving, Coir craft, Nettur Petti wooden caskets, and Payyanur Bell Metal craft.
- **Actual Answer**: I don't have sufficient evidence in the KRIYO knowledge base to answer that reliably.
- **Failure Reason**: Abstention mismatch
- **Recommended Fix**: Tune answerability gate threshold
---

### Question: What crafts are famous in Assam? (Query Variation 113)
- **Retrieved Sources**: DOC013, KRIYO_Craft_Master.xlsx
- **Expected Answer**: Assam is renowned for golden Muga silk weaving, Eri silk weaving, Mekhela Chador weaving, Assam bamboo & cane craft, Jaapi sun hat making, and Sarthebari bell metal craft.
- **Actual Answer**: I don't have sufficient evidence in the KRIYO knowledge base to answer that reliably.
- **Failure Reason**: Abstention mismatch
- **Recommended Fix**: Tune answerability gate threshold
---

### Question: What crafts are famous in Kerala? (Query Variation 127)
- **Retrieved Sources**: DOC001, KRIYO_Craft_Master.xlsx
- **Expected Answer**: Famous crafts of Kerala include Aranmula Kannadi metal mirrors, Kasavu handloom weaving, Coir craft, Nettur Petti wooden caskets, and Payyanur Bell Metal craft.
- **Actual Answer**: I don't have sufficient evidence in the KRIYO knowledge base to answer that reliably.
- **Failure Reason**: Abstention mismatch
- **Recommended Fix**: Tune answerability gate threshold
---

### Question: What crafts are famous in Assam? (Query Variation 134)
- **Retrieved Sources**: DOC013, KRIYO_Craft_Master.xlsx
- **Expected Answer**: Assam is renowned for golden Muga silk weaving, Eri silk weaving, Mekhela Chador weaving, Assam bamboo & cane craft, Jaapi sun hat making, and Sarthebari bell metal craft.
- **Actual Answer**: I don't have sufficient evidence in the KRIYO knowledge base to answer that reliably.
- **Failure Reason**: Abstention mismatch
- **Recommended Fix**: Tune answerability gate threshold
---

### Question: What crafts are famous in Kerala? (Query Variation 148)
- **Retrieved Sources**: DOC001, KRIYO_Craft_Master.xlsx
- **Expected Answer**: Famous crafts of Kerala include Aranmula Kannadi metal mirrors, Kasavu handloom weaving, Coir craft, Nettur Petti wooden caskets, and Payyanur Bell Metal craft.
- **Actual Answer**: I don't have sufficient evidence in the KRIYO knowledge base to answer that reliably.
- **Failure Reason**: Abstention mismatch
- **Recommended Fix**: Tune answerability gate threshold
---
