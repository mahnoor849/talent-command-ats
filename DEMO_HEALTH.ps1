$ErrorActionPreference = "Continue"
Set-Location -LiteralPath $PSScriptRoot
Write-Host "Demo Bank Talent Command V6.0.1 - health and runtime diagnostic" -ForegroundColor Cyan

$composeArgs = @()
if (Test-Path ".env.runtime") { $composeArgs += @("--env-file", ".env.runtime") }

& docker version *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Docker engine is not available. Start Docker Desktop first." -ForegroundColor Red
    exit 1
}

& docker compose @composeArgs ps
$backendId = (& docker compose @composeArgs ps -q backend).Trim()
if ([string]::IsNullOrWhiteSpace($backendId)) {
    Write-Host "V6.0.1 backend container is not running. Run .\DEMO_START.ps1 first." -ForegroundColor Red
    exit 1
}

try {
    $health = Invoke-RestMethod -Uri "http://localhost:8000/health" -TimeoutSec 5
    if ($health.version -ne "6.0.1") { throw "Wrong backend version: $($health.version)" }
    Write-Host "Backend health: PASS - $($health.product) v$($health.version)" -ForegroundColor Green
} catch {
    Write-Host "Backend health: FAIL - $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Copilot runtime:" -ForegroundColor Cyan
try {
    $statusRaw = & docker compose @composeArgs exec -T backend python -c "import json; from app.rag import provider_status; print(json.dumps(provider_status()))"
    $status = (@($statusRaw) | Select-Object -Last 1) | ConvertFrom-Json
    Write-Host "  Provider mode:       $($status.provider_mode)"
    Write-Host "  Preferred provider:  $($status.preferred_provider)"
    Write-Host "  Model:               $($status.model)"
    Write-Host "  Generation enabled:  $($status.generation_enabled)"
    Write-Host "  Embedding model:     $($status.embedding_model)"

    if ($status.preferred_provider -eq "ollama" -and $status.generation_enabled -eq $true) {
        & docker compose @composeArgs exec -T backend python -c "import urllib.request; urllib.request.urlopen('http://host.docker.internal:11434/api/tags', timeout=8).read(); print('PASS')" *> $null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  Docker -> Ollama:    PASS" -ForegroundColor Green
        } else {
            Write-Host "  Docker -> Ollama:    FAIL (verified SQL/retrieval fallback remains available)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  Docker -> Ollama:    not enabled" -ForegroundColor DarkYellow
    }
} catch {
    Write-Host "  Copilot diagnostic failed: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Running presentation-data integrity gate..." -ForegroundColor Cyan
& docker compose @composeArgs exec -T backend python -m app.demo_verify
if ($LASTEXITCODE -eq 0) {
    Write-Host "Demo integrity: PASS" -ForegroundColor Green
} else {
    Write-Host "Demo integrity: FAIL - review backend logs." -ForegroundColor Red
    & docker compose @composeArgs logs backend --tail 120
    exit 1
}

Write-Host ""
Write-Host "Recent backend logs:" -ForegroundColor Cyan
& docker compose @composeArgs logs backend --tail 40
