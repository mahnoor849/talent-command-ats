# Talent Command V6.0.1 - UAT Checklist

Use the Excel workbook in `HANDOVER_DOCUMENTATION/TalentCommand_UAT_Handover_Checklist.xlsx` as the signed tracker. Minimum acceptance sequence:

## Environment
- [ ] Docker Desktop engine running.
- [ ] `START.cmd` completes without manual backend/frontend commands.
- [ ] Frontend opens on `http://localhost:5173`.
- [ ] Backend health reports version `6.0.1`.
- [ ] `HEALTH_CHECK.cmd` -> Demo integrity PASS.

## Access / RBAC
- [ ] Admin, HR Manager, Talent Acquisition, Interview Panel and Viewer login behavior verified.
- [ ] Viewer cannot retrieve candidate PII/interview details.
- [ ] Interview Panel cannot access Talent Pool/requisition analytics outside its role.

## Core recruitment flow
- [ ] Resume import with valid PDF/DOCX/TXT.
- [ ] Invalid/oversize upload handled safely.
- [ ] Talent Pool search/filter/profile/resume access.
- [ ] JD criteria tests: skill only, education only, experience only, combined criteria, full JD.
- [ ] No-match and partial-match behavior reviewed.
- [ ] Requisition and Candidate Careers flow reviewed.
- [ ] Controlled pipeline transitions verified.
- [ ] Interview schedule/reschedule/scorecard constraints verified.
- [ ] Recruitment Analytics totals reconcile with source data.

## HR Copilot
- [ ] `what day is today` returns PKT day/date.
- [ ] `is it <today's weekday> today` returns Yes.
- [ ] `total candidates` uses verified data.
- [ ] `Interviews today` + `How many?` keeps conversation context.
- [ ] `How many employees do we have?` stays out of unsupported HRIS scope.
- [ ] If Ollama is enabled, fuzzy candidate-summary prompt reports provider `ollama` in smoke test.

## Final automation
- [ ] `COPILOT_TEST.cmd` -> PASS.
- [ ] `FINAL_TEST.cmd` -> PASS.
- [ ] No recurring critical backend exceptions in logs.
- [ ] Receiving owner/sign-off captured in the handover workbook.
