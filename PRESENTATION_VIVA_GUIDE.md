# Demo Bank Talent Command — Presentation & Viva Guide

## 1. One-line project definition
**Demo Bank Talent Command is a People & Culture resume-screening and recruitment workflow prototype that converts candidate resumes into searchable profiles and ranks candidates against individual hiring criteria or a complete job description, while keeping the final decision with HR.**

## 2. Business problem
A recruiter may receive a large resume dump. Manual review creates three problems: time spent opening files one by one, inconsistent comparison against a JD, and fragmented follow-up once a candidate is shortlisted. Talent Command centralizes the workflow.

## 3. Core business flow

```text
Resume / Candidate Application
        ↓
Resume Import & Parsing
        ↓
Structured Candidate Profile
        ↓
Talent Pool
        ↓
Hiring Requirement / JD
        ↓
Talent Intelligence Ranking
        ↓
HR Review + Original CV
        ↓
Shortlist / Hiring Pipeline
        ↓
Interview Desk
        ↓
Scorecard → Offer → Hired
```

Supporting layers: Requisitions, Recruitment Analytics, HR Copilot, Audit & Access, Account & Security.

## 4. Technology stack — what and why

### Frontend — React 18 + Vite
- **React** builds the interactive recruiter interface using state-driven components.
- **Vite** provides the frontend development/build pipeline.
- Why: fast UI iteration, reusable components/state, clean REST API integration and a lightweight presentation deployment.

### Backend — Python + FastAPI
- **FastAPI** exposes REST endpoints for authentication, candidates, resumes, jobs, Talent Intelligence, interviews, analytics, audit and Copilot.
- Why: Python fits resume/NLP/ML tooling well, FastAPI has typed request validation and clean API structure, and it is fast enough for this prototype.

### Data layer — PostgreSQL + SQLAlchemy
- **PostgreSQL 16** stores users, candidates, requisitions, applications, stage history, interviews, scorecards, resume metadata and audit events.
- **SQLAlchemy** maps Python models to database tables.
- Why: relational integrity matters because candidates, jobs, applications and interviews have clear relationships and need auditable state.

### Resume handling
- **pdfplumber** extracts text from text-based PDFs.
- **python-docx** reads DOCX resumes.
- Parsed evidence is converted into structured candidate data such as skills, education and experience and can be reviewed by HR.
- Original resume files are stored separately from database metadata and remain downloadable.

### Talent Intelligence
- Deterministic requirement parsing identifies skills, experience, education, role/department, certifications, location and other applicable criteria.
- For a detailed JD, the backend can additionally use **SentenceTransformer `all-MiniLM-L6-v2`** for contextual text similarity.
- That similarity is an internal ranking signal, not a probability that the candidate should be hired.
- Required gaps cap the final score, so contextual similarity cannot hide a missing mandatory requirement.

### HR Copilot
- Presentation mode does **not require an external cloud LLM/API**.
- Common HR questions are answered directly from verified database queries.
- Local sentence embeddings support fuzzy talent discovery when exact operational logic is not enough.
- An optional private Ollama model (`qwen2.5:3b` by default) can summarize bounded retrieved evidence conversationally.
- If the local model is unavailable, verified deterministic/retrieval fallback remains fully usable.
- Technical retrieval details are intentionally hidden from the recruiter UI.

### Security
- JWT-based authentication.
- Role-based access control (RBAC).
- Optional TOTP two-factor authentication.
- Rate limiting on sensitive/public operations.
- Audit logging for material recruitment actions.
- Executive Viewer is read-only and cannot access candidate PII.

### Deployment — Docker Compose
Three presentation services:
1. PostgreSQL database
2. FastAPI backend
3. React/Vite frontend

Docker gives the project a reproducible environment and avoids separately configuring PostgreSQL/Python/Node every time on the presentation laptop.

## 5. Architecture — explain it simply

```text
Browser / React UI
       │ HTTPS/REST-style API calls
       ▼
FastAPI Backend
       │
       ├─ Authentication + RBAC
       ├─ Candidate/Resume Services
       ├─ Talent Intelligence
       ├─ Interview Workflow
       ├─ Copilot Logic
       ├─ Analytics / Audit
       │
       ├──────────────► Resume File Storage
       │
       ▼
PostgreSQL
```

The browser never trains or parses resumes itself. The frontend collects input and displays results; business logic and data access remain on the backend.

## 6. Every main screen

### Command Center
Purpose: a quick operational snapshot of the recruitment workload.
Say: **“This is not employee headcount; these KPIs represent the recruitment/candidate dataset currently loaded in Talent Command.”**

### Resume Import
Purpose: bring candidate resumes/spreadsheets into the system.
Flow: choose files → backend extracts/reconciles candidate details → HR reviews resulting records → profiles enter Talent Pool.

### Talent Pool
Purpose: searchable candidate repository.
Show: search, department/status/requisition filters, review queue, pagination, candidate drawer, original CV download.

### Candidate Profile
Purpose: one HR-reviewed record with contact information, role, department, education, experience, skills, source, workflow status and resume actions.
Important: extracted data is decision support and can be reviewed/edited by authorized HR users.

### Talent Intelligence
Purpose: solve the main screening problem.
Examples:
- `Python` → skill-only criterion.
- `3 years` → experience-only criterion.
- `BS` → education-only criterion.
- `Python, BS, 3 years` → combined criteria.
- Complete AML/KYC JD → full-JD analysis.

Correct explanation of the percentage: **“The displayed relevance score is an explainable ranking score across only the criteria that apply. It is not a hiring probability.”**

### Requisitions
Purpose: represent hiring demand/jobs. A candidate profile describes the person; a requisition describes the position being filled; an application links the two.

### Hiring Pipeline
Purpose: control candidate movement across Applied, Screening, Shortlisted, Interview, Offer and Hired. Rejected/Withdrawn are terminal outcomes.

### Interview Desk
Purpose: schedule and govern interviews.
- HR chooses an Interview Panel member, date/time, duration and format.
- Reschedule/Postpone keeps the previous appointment reference and requires a reason.
- Feedback/scorecards belong after the interview.

### Recruitment Analytics
Purpose: recruitment funnel and process insight. It is not a bank-wide HRIS dashboard.

### HR Copilot
Purpose: fast natural-language access to authorized recruitment facts.
Good demo prompts:
- `total candidates`
- `pipeline breakdown`
- `How many resumes do we have?`
- `review queue`
- `Find Python candidates with at least 3 years of experience`
- `Find Python candidates with BS and at least 3 years of experience`
- `show candidates in Data & Analytics department`
- `Summarize interviews awaiting feedback`

### Audit & Access
Purpose: trace important activity and provide administrative oversight; not part of the main resume-screening demo unless asked.

### Account & Security
Purpose: identity/password/2FA for the logged-in user.

### Candidate Careers
Purpose: separate public-facing application path for active requisitions. It avoids giving external candidates access to internal HR screens.

## 7. How Talent Intelligence scoring works

The backend scores only dimensions actually present in the reviewed requirement:
- Skills: relative weight 0.40 when applicable.
- Experience: 0.25.
- Education: 0.20.
- Required/preferred certifications: 0.08.
- Seniority: 0.08.
- Role/department evidence: 0.18 when applicable.
- Location: 0.05 when requested.
- Contextual text similarity: 0.15 only when enough full-JD context exists.

Weights are normalized across the components that actually apply. Required gaps also impose caps. Therefore a candidate cannot receive a misleading high score merely because one optional signal is strong.

For sparse instructions without a target role, the UI describes results as **criterion matches**, not complete role qualification.

## 8. What “contextual similarity” means if asked
Do not call it “82% qualified.” Say:

**“For a detailed JD, a pretrained sentence-embedding model can compare the overall meaning of the JD with candidate resume evidence even when the wording differs. It is only one internal relevance signal. Mandatory skills, education and experience remain explicit, and HR makes the decision.”**

The premium frontend intentionally does not display this internal percentage because it is easy to misinterpret.

## 9. Why AI Governance was removed from the visible app
**“The assignment is a resume-screening/recruitment system. Model-development controls were technically interesting but distracted from the HR use case. In the final presentation build, the recruiter sees recruitment functions only; technical implementation remains documented and backend-owned.”**

## 10. High-probability viva questions

### Why React?
For a responsive role-based HR interface with reusable components and API-driven state.

### Why FastAPI?
It fits Python NLP/data tooling, validates requests with typed schemas and cleanly separates business APIs from the UI.

### Why PostgreSQL?
Recruitment data is relational: users, candidates, jobs, applications, interviews, stage history and audits need integrity and traceability.

### Why Docker?
To reproduce the same database/backend/frontend environment on another machine and minimize local setup differences.

### Is AI hiring candidates?
No. Ranking/Copilot are decision support. HR remains responsible for shortlist, progression, interviews, offers and hiring.

### What happens if a candidate misses a mandatory requirement?
The backend records the gap and caps relevance rather than allowing another signal to hide it.

### What if HR enters only “Python”?
It becomes a skill-only criterion. The system does not pretend this single criterion proves complete role fit.

### What is the difference between candidate, resume and application?
Candidate = person/profile; resume = uploaded file/evidence; application = candidate linked to a specific requisition.

### Why not expose model/retrieval terms to HR?
They are implementation details. HR needs requirement evidence, gaps and ranked candidates, not developer diagnostics.

### How does Copilot avoid hallucinating employee headcount?
Its scope is recruitment data. If asked for employee/workforce headcount it explicitly says Talent Command does not contain that HRIS information.

### How are permissions handled?
JWT identifies the user, backend role checks enforce allowed operations, and the frontend also shows only the relevant navigation for that role.

### Can Executive Viewer see resumes?
No. The role is deliberately read-only and blocked from candidate PII/interview APIs.

### How do you handle duplicate applications?
Public application and import workflows use identity/application relationships to prevent accidental duplicate records for the same opportunity and to match existing profiles where appropriate.

### What is not production-ready yet?
Enterprise SSO, production candidate/HRIS integrations, formal migrations, DLP/key management, security testing, monitoring and formal organizational governance/UAT would be required.

## 11. Recommended 6–8 minute live demo
1. Command Center — 20–30 seconds.
2. Talent Pool — search/filter/open a candidate/download CV.
3. Talent Intelligence — `Python, BS, 3 years`, then a complete JD.
4. Open one ranked candidate and explain strengths/gaps.
5. Hiring Pipeline — show controlled stages.
6. Interview Desk — show panel/date/format and reschedule concept; only submit if already live-tested.
7. HR Copilot — use 2–3 known-good prompts.
8. Recruitment Analytics — brief close.

Close with: **“Talent Command reduces manual resume review, standardizes candidate comparison against hiring requirements and keeps the entire recruitment path auditable while leaving final decisions with People & Culture.”**

## 12. Final presentation-machine checks
Before the supervisor arrives:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\DEMO_START.ps1
.\DEMO_HEALTH.ps1
.\COPILOT_SMOKE.ps1
.\FINAL_SMOKE.ps1
```

Then manually verify one browser path: fresh login → Talent Pool → CV → Talent Intelligence → Pipeline → Interview Desk → Copilot.
