# Local HR Copilot Setup and Operating Model

## What is deterministic vs generative
Talent Command intentionally uses a hybrid design:

- Exact counts, pipeline facts, requisition facts, interview schedules and date/time -> deterministic SQL/system logic.
- Structured candidate filters -> database/profile logic.
- Fuzzy discovery and evidence summarization -> retrieval + optional local Ollama/Qwen generation.

This prevents an LLM from inventing exact operational facts while still providing natural-language assistance.

## One-time setup
1. Install/start bank-approved Ollama for Windows.
2. Confirm the API works:

```powershell
Invoke-RestMethod http://127.0.0.1:11434/api/tags
```

3. Confirm the model exists:

```powershell
ollama list
```

4. Run `SETUP_COPILOT.cmd` or:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\SETUP_LOCAL_COPILOT.ps1
```

Default model: `qwen2.5:3b`.

## Required runtime values
The setup script manages these in `.env.runtime`:

```text
AI_PROVIDER=auto
OLLAMA_ENABLED=true
OLLAMA_BASE_URL=http://host.docker.internal:11434
OLLAMA_MODEL=qwen2.5:3b
AI_TIMEOUT_SECONDS=30
AI_TEMPERATURE=0.10
```

The runtime file is automatically normalized to one key per line; duplicate/malformed historical entries are repaired.

## Verification
Run `HEALTH_CHECK.cmd`. A healthy local-AI configuration shows:
- Preferred provider: `ollama`
- Generation enabled: `True`
- Docker -> Ollama: `PASS`

Then run `COPILOT_TEST.cmd`. When local generation is enabled, the fuzzy-answer check must use provider `ollama`.

## Recommended prompts
- `what day is today`
- `is it Tuesday today`
- `total candidates`
- `how many interviews today`
- `Interviews today` followed by `How many?`
- `Find candidates with strong Python and analytics backgrounds and summarize the evidence.`

## Failure behavior
If Ollama is stopped/unreachable, the application remains usable. Exact SQL answers and deterministic/retrieval fallback continue; no external AI service is contacted unless one is explicitly configured and approved.
