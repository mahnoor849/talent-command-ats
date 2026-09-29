# Changelog

## 6.0.1 - Handover baseline (23 Sep 2026)
- Finalized V6 recruitment workflow and UI/UX polish.
- Separated weighted ranking evidence from mandatory coverage.
- Improved interview/pipeline/requisition/analytics workflows and filters.
- Added governed HR Copilot deterministic + retrieval + optional local Ollama architecture.
- Fixed date/day intent collisions and conversational interview follow-ups.
- Added natural weekday confirmation (`is it Tuesday today`, `is today Tuesday`).
- Hardened `.env.runtime` handling: automatic repair, deduplication and one-key-per-line output.
- Added Docker-to-Ollama diagnostic and host gateway mapping.
- Added environment-driven PostgreSQL settings and switches to disable demo seeding.
- Added Windows CMD wrappers for execution-policy-safe routine operation.
- Consolidated bank handover documentation and UAT/sign-off artifacts.
- Audited baseline: 143/143 backend/source tests; 25/25 focused Copilot/RAG tests.
