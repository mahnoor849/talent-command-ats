# Talent Command V6.0.1 - Technical Architecture

## Runtime architecture
```text
Browser / React (Vite) :5173
        |
        | REST/JSON
        v
FastAPI backend :8000
  |-- Authentication + RBAC + optional TOTP
  |-- Resume import/parsing
  |-- Candidate / requisition / interview workflow
  |-- JD requirement extraction + ranking
  |-- Analytics + audit
  |-- HR Copilot retrieval / grounded generation
        |
        +--> PostgreSQL 16
        +--> Resume/model Docker volumes
        +--> Optional Windows Ollama via host.docker.internal:11434
```

## Frontend
React/Vite single-page application. Role-aware navigation covers Command Center, Resume Import, Talent Pool, Talent Intelligence, Requisitions, Hiring Pipeline, Interview Desk, Recruitment Analytics, HR Copilot and Audit & Access.

## Backend
FastAPI + SQLAlchemy. Business rules and authorization are server-side; the UI is not treated as the security boundary.

## Database
PostgreSQL 16 in Docker for demo/UAT. Persistent named volumes preserve state between normal stop/start. Development convenience uses `Base.metadata.create_all` and a small set of compatibility `ALTER TABLE` operations; a production deployment must replace this with formal Alembic migrations.

## Resume/NLP
Supported resume formats: PDF, DOCX, TXT. Text extraction and structured normalization feed candidate profiles. `sentence-transformers/all-MiniLM-L6-v2` provides 384-dimensional embeddings for semantic similarity/retrieval.

## Talent Intelligence
Requirement parsing supports sparse criteria and full JDs. Scoring separates weighted relevance/evidence from required-criteria coverage and exposes gaps for HR review. Scores are ranking aids, not hiring probabilities.

## HR Copilot
Three governed paths:
1. deterministic SQL/system answers for exact operational facts;
2. structured profile/database filtering;
3. semantic retrieval plus optional local Ollama generation for fuzzy questions.

The model never receives unrestricted database access. The backend retrieves bounded authorized evidence first. HR remains accountable for all decisions.

## Security controls demonstrated
JWT authentication, RBAC, role-restricted candidate/interview APIs, optional TOTP, rate limiting, audit events, controlled pipeline transitions, upload type/size controls and public-application consent.

See `SECURITY_PRODUCTION_READINESS.md` for controls still required before production.
