$ErrorActionPreference = "Stop"
Set-Location -LiteralPath $PSScriptRoot
Write-Host "Stopping Demo Bank Talent Command containers (data volumes are preserved)..." -ForegroundColor Yellow
$composeArgs = @()
if (Test-Path ".env.runtime") { $composeArgs += @("--env-file", ".env.runtime") }
& docker compose @composeArgs down
