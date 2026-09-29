# HR Copilot — Complete Functional Audit

## Audit objective
Copilot must behave like a reliable recruitment assistant, not a developer console. It must answer common questions from verified Talent Command data, avoid raw retrieval output, respect RBAC, remain usable without an external LLM, and fail cleanly.

## Final design
The presentation build uses three answer paths:

1. **Deterministic database answers** for counts, workflow summaries and structured candidate filters.
2. **Structured candidate/profile retrieval** for known skills, education, experience and explicit department criteria.
3. **Bounded semantic retrieval** only for genuinely fuzzy talent discovery. The UI never exposes raw embedding scores or engine headings.

External cloud generative AI is not required. The final handover build supports an **optional private local Ollama model** for grounded conversational/fuzzy questions. If Ollama is absent or unavailable, Copilot falls back to verified deterministic/retrieval answers without breaking the workflow.

## Authorization
`POST /chatbot/hr` is available only to:
- Administrator
- HR Manager
- Talent Acquisition

Executive Viewer and Interview Panel cannot use HR Copilot as a route to candidate PII.

The endpoint is rate limited to **30 requests/minute**.

## Request safety contract
- Allowed message roles: `user`, `assistant` only.
- Maximum conversation sent to backend: 20 messages.
- Maximum message length: 4,000 characters.
- Frontend automatically sends only the most recent 20 messages.
- Candidate/HR data is never made public through the public assistant.

## Tested intent matrix

| User question | Expected data path | Expected behavior | Test status |
|---|---|---|---|
| `hi` | deterministic | professional recruitment greeting | PASS |
| `total candidates` | candidates table | exact total | PASS |
| `pipeline breakdown` | candidates table | total + all pipeline stages | PASS |
| `how many are shortlisted?` | candidates table | Shortlisted count, not interview count | PASS |
| `How many interviews are there?` | interview tables | interview event breakdown | PASS |
| `total resumes` | resumes table | resume-file total + unique candidates | PASS |
| `how many candidates need review?` | candidates table | import/parsing review queue | PASS |
| `How many Python candidates are there?` | structured profile | exact Python count, not total population | PASS |
| `Find Python candidates with at least 3 years of experience` | structured profile | all criteria mandatory | PASS |
| `Find candidates with Python, BS and 3 years experience` | structured profile | skill + Bachelor's-or-higher + 3+ years | PASS |
| `Find candidates in Compliance department` | structured profile | explicit department filter | PASS |
| `How many active requisitions are there?` | jobs table | active count | PASS |
| `List active requisitions` | jobs table | active titles/departments/locations | PASS |
| `Which active requisitions have the largest candidate pools?` | jobs + applications | ranked application counts | PASS |
| `Interviews tomorrow` | interviews | tomorrow's schedule in PKT | PASS |
| `Summarize interviews awaiting feedback` | interviews + scorecards | actionable feedback queue | PASS |
| `Tell me about <candidate>` | candidates | verified candidate profile | PASS |
| `How many employees do we have?` | scope guard | refuses to invent bank employee headcount | PASS |

## Critical bug checks
### Raw semantic output
The earlier UI could expose text similar to `SEMANTIC TOP-K RETRIEVAL` and `semantic score`. V6.0 removes these from business-facing fallback responses. Regression coverage explicitly asserts that raw engine text is absent.

### Misleading count queries
A generic “how many” question previously risked falling into a candidate-total context even when the user meant another metric. V6.0 routes resume, review, skill, experience, education, requisition and interview counts explicitly before generic fallback.

### External AI outage
The core presentation does not depend on an external provider. Compose now reads local-AI settings from `.env.runtime`. `DEMO_START.ps1` enables Ollama only when a configured local model is actually reachable; otherwise `OLLAMA_ENABLED=false` and direct operational answers/semantic retrieval remain local.

### Long conversation failure
Backend requests are limited to 20 messages. The frontend now trims API history to the last 20 messages while retaining the full visible chat, preventing the 11th+ user interaction from suddenly failing because the payload exceeded the backend contract.

### Error presentation
If the API call fails, the UI inserts a professional in-chat recovery message and also shows a toast. It no longer looks like the Copilot simply stopped responding.

## V6 operational expansion
V6 keeps the verified-data approach and adds business questions for:
- employee referrals;
- candidates waiting longest in active stages;
- department-focused talent discovery;
- active requisitions with no shortlisted-or-beyond candidates;
- weekly interview summaries.

## Dedicated automated Copilot suite
`backend/tests/test_v53_copilot_runtime.py` (retained filename; V6 regression coverage) executes Copilot intent logic against a controlled fake recruitment dataset.

Current handover baseline: **25 / 25 focused Copilot/RAG tests PASS**. Full backend/source regression: **143 / 143 PASS**.

## Live presentation verification
After Docker starts, run:

```powershell
.\COPILOT_SMOKE.ps1
```

The script logs in as HR Manager and validates live data for greeting, candidate total, pipeline, resume inventory, review queue, skill/experience/education searches, requisitions, interview totals/feedback, scope control, evidence sources, and the absence of raw semantic/debug output.

Final expected line:

`COPILOT SMOKE: PASS`


## V6.0.1 conversational/local-AI patch
- Fixed the `today` routing bug: `what date is today` now returns the PKT date instead of interview data.
- Interview retrieval now requires interview intent; the words `today` or `tomorrow` alone cannot trigger the interview schedule.
- Added high-confidence conversational follow-ups, e.g. `Interviews today` → `How many?`, and `What about tomorrow?`.
- Exact counts/workflow facts remain deterministic SQL answers.
- Fuzzy/natural candidate questions can use private local Ollama generation over bounded retrieved evidence.
- UI labels distinguish **Local AI · verified Talent Command data** from deterministic verified responses.
- Ollama outages are probed quickly and degrade to the grounded fallback instead of causing repeated long waits.
- `SETUP_LOCAL_COPILOT.ps1` provisions the local model and applies runtime settings without storing an external API key.
