# Troubleshooting Guide

## PowerShell says script is not digitally signed
Use the `.cmd` wrappers. They launch PowerShell with process-scoped execution-policy bypass. Manual alternative:
```powershell
Set-ExecutionPolicy -Scope Process Bypass
```

## Docker engine unavailable
Open Docker Desktop, wait for Engine running, then rerun `START.cmd`.

## Docker Hub / Debian / TLS download timeout
This is network/registry connectivity, not application logic. Retry on an approved stable network or internal registry/cache. Do not rewrite the Dockerfile merely to hide a network failure.

## Ports 8000 or 5173 in use
`DEMO_START.ps1` stops older Talent Command containers and refuses to silently use an unrelated service. Inspect:
```powershell
docker ps
```
Stop the unrelated owner, then rerun start.

## `.env.runtime` looks duplicated or concatenated
Current startup/setup scripts automatically normalize the file. Rerun `SETUP_COPILOT.cmd` (if Ollama is intended) or `START.cmd`. Verify one setting per line with:
```powershell
Get-Content .env.runtime
```

## Ollama works in Windows but not in Talent Command
Run `HEALTH_CHECK.cmd`. If Windows `/api/tags` works but Docker -> Ollama fails, verify Docker Desktop networking and `host.docker.internal:11434`. The Compose file includes a host-gateway mapping.

## Copilot says fallback / local LLM not active
This is safe behavior. If local generation is required, run `SETUP_COPILOT.cmd`, then `HEALTH_CHECK.cmd`. Exact SQL questions work without Ollama.

## Wrong answer for a natural phrase
Check whether it is an exact operational intent or a fuzzy request. Add a deterministic routing rule only when the intent has a single factual interpretation, and add a regression test. Do not keep adding broad keywords that can steal unrelated questions.

## Database credentials changed but old volume remains
PostgreSQL initialization environment variables only create credentials on a new data directory. For an existing volume, coordinate a password/database migration with the DBA; do not simply change Compose variables and expect the stored database user to change.

## Need a clean demo reset
Treat volume deletion as destructive. Export/backup any required UAT evidence first, then coordinate a deliberate `docker compose down -v` reset. Normal `STOP.cmd` does not delete volumes.
