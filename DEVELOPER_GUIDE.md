# Developer Continuation Guide

## Code map
- `frontend/src/App.jsx` - main React UI and screen workflows.
- `frontend/src/api.js` - API client/auth token handling.
- `backend/app/main.py` - FastAPI app/routers/health.
- `backend/app/models.py` - SQLAlchemy domain model.
- `backend/app/schemas.py` - request/response validation.
- `backend/app/routers/` - business/API modules.
- `backend/app/matching.py` - JD requirement/ranking logic.
- `backend/app/nlp.py` - extraction/normalization/embedding utilities.
- `backend/app/rag.py` - provider-neutral grounded generation layer.
- `backend/app/seed*.py` - demo/UAT seed data only.
- `backend/tests/` - regression and contract tests.

## Local source regression
From the project root in a Python environment with dependencies:
```powershell
$env:DATABASE_URL="sqlite:///./talent_test.db"
$env:PYTHONPATH="backend"
pytest -q backend/tests
```
Current audited baseline: **143 passing tests**.

## Safe change workflow
1. Create a branch/copy; do not edit the only handover copy.
2. Make the smallest scoped change.
3. Add/update regression tests.
4. Run the full source suite.
5. Rebuild Docker with `START.cmd`.
6. Run health, Copilot and final smoke scripts.
7. Update `CHANGELOG.md` and relevant handover docs.
8. Do not commit `.env.runtime`, real resumes, tokens or bank credentials.

## Database changes
The prototype currently uses development table creation/compatibility ALTERs. New production-bound schema work should first introduce Alembic and migration versioning rather than adding more startup-time ALTER statements.

## Frontend changes
Preserve role-based visibility, responsive overflow handling and backend authorization. Never rely on hiding a button as an authorization control.

## Copilot changes
Keep exact operational facts deterministic where possible. Fuzzy generation must remain grounded in retrieved authorized evidence. Add intent regression tests whenever a routing phrase is fixed.

## Release process
- Update `VERSION.txt` only for an intentional release.
- Run all automated and live gates.
- Regenerate formal handover documents/checksums.
- Record unresolved issues in the UAT workbook; do not hide them.
