# Run Talent Command V6.0.1 on Windows

## Daily start - easiest method
1. Start Docker Desktop and wait for the engine to be ready.
2. Keep Ollama running only if the local generative Copilot is required.
3. Double-click `START.cmd`.
4. Open `http://localhost:5173` if the browser does not open automatically.

## First-time Copilot setup
If Ollama/Qwen is approved and required:

```powershell
ollama --version
ollama list
```

Ensure `qwen2.5:3b` is installed, then run `SETUP_COPILOT.cmd`.

The script verifies Windows Ollama, writes a normalized `.env.runtime`, configures Docker to use `http://host.docker.internal:11434`, and verifies the Docker-to-Ollama bridge when the backend is running.

## PowerShell method
```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\DEMO_START.ps1
.\DEMO_HEALTH.ps1
.\COPILOT_SMOKE.ps1
.\FINAL_SMOKE.ps1
```

Expected final lines:
- backend health/version: V6.0.1
- `Demo integrity: PASS`
- `COPILOT SMOKE: PASS`
- `FINAL SMOKE: PASS`

## Stop safely
Run `STOP.cmd` or:

```powershell
.\DEMO_STOP.ps1
```

Normal stop preserves PostgreSQL, resume and model volumes.

## Reset warning
Do not delete Docker volumes unless an intentional clean reset has been approved. Volume deletion removes local demo/UAT state.
