# Talent Command V6.0.1 - Read Me First

## Purpose
Talent Command is a recruitment and resume-screening prototype prepared for Demo Bank People & Culture / AI & Data Science handover. The core workflow is:

**Resume Import -> Talent Pool -> Talent Intelligence/JD Matching -> HR Review -> Hiring Pipeline -> Interview Desk -> Analytics/Audit**

HR Copilot is a governed decision-support interface over Talent Command data. Exact counts/workflow facts are database-driven; fuzzy conversational questions can optionally use a private local Ollama model over retrieved evidence.

## Start here
For the simplest Windows workflow, use the supplied command wrappers:

- `START.cmd` - start Docker services and open the UI
- `STOP.cmd` - stop services without deleting data volumes
- `HEALTH_CHECK.cmd` - health, integrity and Copilot runtime diagnostics
- `COPILOT_TEST.cmd` - live Copilot smoke test
- `FINAL_TEST.cmd` - final non-destructive system smoke test
- `SETUP_COPILOT.cmd` - one-time local Ollama/Qwen configuration

PowerShell equivalents remain available for technical users.

## URLs
- Frontend: `http://localhost:5173`
- API / Swagger: `http://localhost:8000/docs`
- Backend health: `http://localhost:8000/health`

## Demo accounts - UAT/demo only
- Administrator: `admin@demobank.demo` / `Admin@26`
- HR Manager: `hr@demobank.demo` / `HR@2026`
- Talent Acquisition: `talent@demobank.demo` / `Talent@26`
- Interview Panel: `panel@demobank.demo` / `Panel@26`
- Executive Viewer: `viewer@demobank.demo` / `View@2026`

These credentials and synthetic records are for demonstration/UAT only and must not be reused in production.

## First-time machine setup
1. Install/start Docker Desktop.
2. Extract the package to a normal local folder such as `C:\TalentCommand_v6.0.1`.
3. If local generative Copilot is required, install/start approved Ollama and run `SETUP_COPILOT.cmd` once. Default model: `qwen2.5:3b`.
4. Run `START.cmd`.
5. Run `HEALTH_CHECK.cmd`, `COPILOT_TEST.cmd`, then `FINAL_TEST.cmd`.

## Important operating behavior
- `.env.runtime` is local runtime configuration and is intentionally excluded from source control/handover secrets.
- Startup automatically normalizes/repairs malformed or duplicated runtime entries.
- Docker data volumes are preserved by normal stop/start.
- Local Ollama is optional. If unavailable, HR Copilot safely falls back to verified SQL/retrieval behavior.
- The application is a prototype/UAT release, not a bank production deployment. See `SECURITY_PRODUCTION_READINESS.md`.

## Documentation map
- `RUN_STEP_BY_STEP.md` - exact operating procedure
- `DEVELOPER_GUIDE.md` - codebase and continuation guide
- `AI_ML_RAG_ARCHITECTURE.md` - AI/NLP/RAG design
- `LOCAL_COPILOT_SETUP.md` - Ollama setup and verification
- `TROUBLESHOOTING.md` - common failures and fixes
- `SECURITY_PRODUCTION_READINESS.md` - controls and production gaps
- `FINAL_QA_V6.md` - current audit evidence
- `UAT_CHECKLIST_V6.md` - live acceptance procedure
- `CHANGELOG.md` - release history
- `HANDOVER_DOCUMENTATION/` - formal manual, checklist workbook and sign-off material
