# Supervisor Q&A — Demo Bank Talent Command V6.0 Enterprise

## What problem does Talent Command solve?
HR can receive large resume dumps and spend significant time manually opening CVs and comparing them with a job requirement. Talent Command structures resume information and lets a recruiter search/rank candidates using one criterion, several criteria, or a complete JD, while keeping the original resume available for human review.

## What is the main feature?
**Talent Intelligence / JD matching.** Resume Import and Talent Pool create the structured evidence; Talent Intelligence interprets the recruiter's requirement and ranks relevant candidates.

## Why did you remove AI Governance?
Because it was outside the recruiter-facing purpose of this prototype. Model-training controls made the UI look like a development console. The presentation should demonstrate the resume-screening workflow, while technical implementation stays in backend code/documentation.

## Is there still AI/ML/NLP in the project?
Yes. Resume/JD text extraction, requirement parsing, structured matching and local semantic retrieval are implementation capabilities. The product does not need to expose model-training screens to prove that the backend uses NLP/ML techniques.

## Does the Match % mean a candidate should be hired?
No. It is a decision-support relevance score based on evidence such as required skills, education, experience and JD similarity. It is not a hiring probability and cannot replace recruiter/interviewer judgment.

## Can I give only `Python` instead of a full JD?
Yes. The matcher supports sparse single criteria as well as combinations such as `Python, 3 years` or `Python, BS, 3 years`. A sparse query is labelled/treated as criterion matching rather than complete role qualification.

## Can the system use a full JD?
Yes. A full natural-language JD can be pasted (and supported JD document formats can be parsed), requirements are detected and can be reviewed before candidate ranking.

## What resume formats are supported?
PDF, DOCX and TXT for the resume workflow, with a 10 MB server-side size limit. Bulk resume import is capped at 200 files per request. Spreadsheet candidate import supports XLSX/CSV.

## What happens with duplicate resumes?
Identical resume content is detected using a content hash, and candidate identity can be merged by email instead of blindly creating duplicate clean records. Potential/incomplete records can be sent to manual review.

## Why are there 1,250 candidates?
They are synthetic presentation records used to demonstrate scale and workflow. They are not real Demo Bank candidates and should not be presented as production data.

## Why can candidate count, resume count and application count differ?
They represent different entities. One candidate can have multiple resume versions and can have applications to different requisitions over time. The system therefore should not force those totals to equal each other.

## Why doesn't Interview Desk total equal candidates in Interview stage?
Interview Desk counts interview **events**. A candidate may have multiple rounds or historical events. Candidate stage is only the candidate's current pipeline state. The sidebar's actionable interview count can also exclude completed/cancelled history.

## How do you postpone/reschedule an interview?
For an eligible future interview, select **Reschedule**, choose a new future time, enter the mandatory reason and confirm. The previous time and reason remain traceable. Interview Panel can do this only for interviews assigned to that panel account.

## Why is the scorecard button disabled before the interview?
That is intentional workflow integrity. Feedback cannot be formally submitted before the scheduled interview has taken place.

## What can Executive Viewer do?
View requisitions and aggregated recruitment analytics for oversight. It is read-only and is deliberately blocked from candidate CV/PII and Interview Desk details.

## How does a candidate apply?
From Candidate Careers, a user sees only active/non-expired vacancies, opens a job, completes basic information, explicitly consents to recruitment-data processing and uploads a PDF/DOCX/TXT resume.

## Why can't a candidate check application status just by entering email?
An email address is not identity verification. An email-only lookup could reveal another person's recruitment information. A production portal should use a signed application reference, OTP or authenticated candidate account.

## What does HR Copilot do?
It answers recruitment questions using Talent Command data: totals, pipeline, resume inventory, skill/experience/education candidate searches, requisitions, interview queues and candidate summaries. It is decision support; it does not change candidate status or make hiring decisions.

## Does Copilot need ChatGPT/OpenAI/internet?
No external cloud LLM is required. Exact operational questions are answered from the local database. For more natural/fuzzy questions, the final handover build can optionally use a private Ollama model running on the same Windows machine. If that local model is unavailable, Copilot automatically falls back to verified SQL/retrieval answers.

## Why is that better for the demo?
It avoids external API keys, cloud-provider quotas and third-party data transfer. Factual recruitment answers still come from Talent Command's own records, while the optional local model improves conversational phrasing over bounded retrieved evidence.

## How do you prevent Copilot from exposing raw AI output?
Direct operational questions use deterministic data paths. Semantic fallback is bounded and cleaned before it reaches the UI; regression tests check that headings/scores such as `SEMANTIC TOP-K RETRIEVAL` and `semantic score` are not shown as the normal response.

## Can Copilot answer `total candidates` correctly?
Yes. This was specifically fixed and tested. It now uses the candidate table directly instead of falling into semantic retrieval.

## Can Copilot combine criteria?
Yes. For example, `Find candidates with Python, BS and 3 years experience` applies skill + Bachelor's-or-higher education + minimum experience together.

## What happens if I ask “How many employees do we have?”
Copilot explains that Talent Command contains recruitment/candidate data and cannot claim Demo Bank's employee headcount. It deliberately avoids fabricating an answer outside its data scope.

## Can Copilot modify data?
No. It is a read/decision-support assistant in this prototype. It does not hire/reject candidates, move pipeline stages, schedule/reschedule interviews or submit scorecards.

## Who can use HR Copilot?
Administrator, HR Manager and Talent Acquisition. Executive Viewer and Interview Panel cannot use it as a route to candidate PII.

## What security controls are demonstrated?
Role-based API authorization, authenticated sessions/JWT, restricted PII routes, controlled pipeline transitions, interview ownership, file type/size checks, rate limits on sensitive public/Copilot paths, explicit consent for public application and audit events for meaningful workflow actions.

## Is this production-ready for a bank?
No claim of production readiness should be made. It is an internship prototype with synthetic data. A production deployment would need formal security architecture, enterprise SSO, malware scanning, DLP, approved data retention/privacy controls, HRIS integration, secret/key management, fairness/model-risk review, monitoring and production UAT.

## How was it tested?
The V6.0.1 Enterprise Final automated/source gate contains **143 passing backend/source regression tests**, including **25/25 focused Copilot/RAG tests**. Python compilation, frontend JS/JSX syntax, operational-button wiring and Docker Compose structure also pass. The package includes live `DEMO_HEALTH.ps1`, `COPILOT_SMOKE.ps1` and `FINAL_SMOKE.ps1` scripts for the target Windows Docker machine. The source/regression release is finalized; the presentation laptop should still pass all live checks against backend version 6.0.1 before the demo.


## Why does Interview Scheduling show department and role now?
At scale, candidate names alone are ambiguous. V6 shows the candidate's department, role and current pipeline stage before scheduling, and supports department filtering so HR can select the correct person quickly and defensibly.

## What are Weighted Relevance and Required Coverage?
**Weighted Relevance** prioritizes candidates using only the reviewed criteria that apply to the current search. **Required Coverage** separately shows how many mandatory criteria have evidence. Neither is a hiring probability; missing mandatory evidence remains visible and can cap the recommendation.

## Why can pipeline time metrics differ from time-to-hire?
Time-to-hire measures Application → Hired for candidates who reached Hired. Time-in-stage measures how long candidates remained in each active workflow stage based on stage-history timestamps. V6 avoids treating time spent after terminal outcomes such as Hired/Rejected/Withdrawn as recruitment cycle time.
