# Security and Production Readiness

Talent Command V6.0.1 is a prototype/UAT release. The following must be completed before production use in a bank environment.

## Already demonstrated
- JWT authentication and backend RBAC.
- Optional TOTP/2FA.
- Role-restricted candidate/interview data access.
- Audit logging for meaningful workflow actions.
- Upload extension/size controls and public application consent.
- Rate limiting on selected endpoints.
- Local/private Ollama option; no cloud LLM required.

## Required before production
1. Enterprise identity/SSO integration and removal of demo accounts/login cards.
2. Bank-managed secrets/key vault; rotate all demo/default database credentials.
3. TLS termination/reverse proxy and approved internal DNS.
4. Formal database migrations (Alembic) instead of development `create_all`/compatibility ALTERs.
5. Malware scanning and DLP for uploaded resumes/documents.
6. Encryption-at-rest controls for database, resume storage, backups and model storage.
7. Formal retention/deletion process tied to HR/legal policy.
8. SIEM/central logging, alerting and operational monitoring.
9. Backup/restore runbook tested by Bank IT/DBA.
10. Vulnerability assessment, dependency/SBOM review and penetration testing.
11. HRIS/identity/recruitment integrations through approved interfaces.
12. Accessibility and supported-browser acceptance testing.
13. Model-risk/fairness/privacy review for ranking and Copilot use.
14. Approved local-model lifecycle/update process if Ollama is retained.
15. Production UAT/change-management approvals.

## Demo seeding
For non-demo work set:
```text
SEED_DEMO_USERS=false
SEED_PRESENTATION_DATA=false
PRESENTATION_CANDIDATE_COUNT=0
```
Do not run a production environment with synthetic demo seeding enabled.

## AI data boundary
Ollama is optional and local. The backend retrieves authorized evidence before generation. Do not configure an external AI endpoint with real candidate data until Information Security/Data Privacy approves the data-processing path.
