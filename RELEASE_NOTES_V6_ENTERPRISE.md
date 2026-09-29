# Talent Command V6.0.1 - Release Notes

## Release purpose
Bank/department handover baseline for the recruitment prototype and its supporting documentation.

## Main functional areas
Command Center, Resume Import, Talent Pool, Candidate Profile, Talent Intelligence/JD Matching, Requisitions/Candidate Careers, Hiring Pipeline, Interview Desk, Recruitment Analytics, HR Copilot, Audit & Access.

## Handover hardening
- Runtime environment repair/deduplication.
- Local Ollama setup and Docker bridge verification.
- Natural day/date Copilot intent fixes and conversational follow-ups.
- Environment-configurable PostgreSQL values.
- Demo seeding can be disabled.
- Execution-policy-safe Windows command wrappers.
- Updated formal operations, security, UAT and continuation documentation.

## Verified source baseline
- 143/143 backend/source tests PASS.
- 25/25 focused Copilot/RAG tests PASS.
- Python compile PASS.
- JavaScript syntax checks PASS for non-JSX modules.
- Docker Compose YAML/service validation PASS.

## Required receiving-machine gate
Run `HEALTH_CHECK.cmd`, `COPILOT_TEST.cmd` and `FINAL_TEST.cmd` before sign-off.
