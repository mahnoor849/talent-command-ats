@echo off
setlocal
cd /d "%~dp0"
where pwsh >nul 2>&1
if %errorlevel%==0 (
  pwsh -NoProfile -ExecutionPolicy Bypass -File "%~dp0COPILOT_SMOKE.ps1" %*
) else (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0COPILOT_SMOKE.ps1" %*
)
set EXITCODE=%errorlevel%
if not "%EXITCODE%"=="0" pause
exit /b %EXITCODE%
