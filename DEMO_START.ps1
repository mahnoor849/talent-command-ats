$ErrorActionPreference = "Stop"
Set-Location -LiteralPath $PSScriptRoot

$script:RuntimeKeys = @(
    "JWT_SECRET", "POSTGRES_USER", "POSTGRES_PASSWORD", "POSTGRES_DB", "DATABASE_URL",
    "ACCESS_TOKEN_EXPIRE_MINUTES", "ALLOWED_ORIGINS", "ENABLE_AUDIT_LOG", "DATA_RETENTION_DAYS",
    "RESUME_STORAGE_DIR", "MODEL_STORAGE_DIR", "AI_PROVIDER", "AI_API_BASE_URL", "AI_API_KEY", "AI_MODEL",
    "OLLAMA_ENABLED", "OLLAMA_BASE_URL", "OLLAMA_MODEL", "RAG_TOP_K", "RAG_MAX_CONTEXT_CHARS",
    "AI_TIMEOUT_SECONDS", "AI_TEMPERATURE", "SEED_DEMO_USERS", "SEED_PRESENTATION_DATA",
    "PRESENTATION_CANDIDATE_COUNT"
)

function Normalize-RuntimeFile {
    $runtimePath = Join-Path $PSScriptRoot ".env.runtime"
    if (-not (Test-Path $runtimePath)) {
        $jwtSecret = ([guid]::NewGuid().ToString("N") + [guid]::NewGuid().ToString("N"))
        [System.IO.File]::WriteAllLines($runtimePath, [string[]]@("JWT_SECRET=$jwtSecret"), [System.Text.Encoding]::ASCII)
        return
    }

    $raw = [System.IO.File]::ReadAllText($runtimePath)
    $keyPattern = ($script:RuntimeKeys | ForEach-Object { [regex]::Escape($_) }) -join "|"
    $matches = [regex]::Matches($raw, "(?<key>$keyPattern)=")
    $values = [ordered]@{}

    for ($i = 0; $i -lt $matches.Count; $i++) {
        $m = $matches[$i]
        $start = $m.Index + $m.Length
        $end = if ($i + 1 -lt $matches.Count) { $matches[$i + 1].Index } else { $raw.Length }
        $value = $raw.Substring($start, $end - $start).Trim("`r", "`n", " ", "`t")
        $values[$m.Groups["key"].Value] = $value
    }

    if (-not $values.Contains("JWT_SECRET") -or [string]::IsNullOrWhiteSpace([string]$values["JWT_SECRET"])) {
        $values["JWT_SECRET"] = ([guid]::NewGuid().ToString("N") + [guid]::NewGuid().ToString("N"))
    }

    $lines = New-Object System.Collections.Generic.List[string]
    foreach ($key in $script:RuntimeKeys) {
        if ($values.Contains($key)) { [void]$lines.Add("$key=$($values[$key])") }
    }
    [System.IO.File]::WriteAllLines($runtimePath, [string[]]$lines, [System.Text.Encoding]::ASCII)
}

function Get-RuntimeValue([string]$Key) {
    Normalize-RuntimeFile
    $runtimePath = Join-Path $PSScriptRoot ".env.runtime"
    $match = Get-Content $runtimePath | Where-Object { $_ -match ("^" + [regex]::Escape($Key) + "=") } | Select-Object -Last 1
    if (-not $match) { return $null }
    return $match.Substring($Key.Length + 1).Trim()
}

function Set-RuntimeValue([string]$Key, [string]$Value) {
    Normalize-RuntimeFile
    $runtimePath = Join-Path $PSScriptRoot ".env.runtime"
    $lines = @(Get-Content $runtimePath)
    $pattern = "^" + [regex]::Escape($Key) + "="
    $newLines = New-Object System.Collections.Generic.List[string]
    $found = $false
    foreach ($line in $lines) {
        if ($line -match $pattern) {
            if (-not $found) {
                [void]$newLines.Add("$Key=$Value")
                $found = $true
            }
        } else {
            [void]$newLines.Add($line)
        }
    }
    if (-not $found) { [void]$newLines.Add("$Key=$Value") }
    [System.IO.File]::WriteAllLines($runtimePath, [string[]]$newLines, [System.Text.Encoding]::ASCII)
}

function Test-OllamaHostApi {
    param([int]$TimeoutSeconds = 8)
    foreach ($endpoint in @("http://127.0.0.1:11434/api/tags", "http://localhost:11434/api/tags")) {
        try {
            $params = @{ Uri = $endpoint; TimeoutSec = $TimeoutSeconds; ErrorAction = "Stop" }
            if ((Get-Command Invoke-RestMethod).Parameters.ContainsKey("NoProxy")) { $params["NoProxy"] = $true }
            $response = Invoke-RestMethod @params
            if ($null -ne $response -and $null -ne $response.models) {
                return [pscustomobject]@{ Ready = $true; Endpoint = $endpoint; Response = $response }
            }
        } catch { }
    }
    return [pscustomobject]@{ Ready = $false; Endpoint = $null; Response = $null }
}

Normalize-RuntimeFile

Write-Host ""
Write-Host "Demo Bank Talent Command V6.0.1 - starting presentation/UAT environment" -ForegroundColor Cyan
Write-Host ""

& docker version *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Docker Desktop is installed but the Docker engine is not ready." -ForegroundColor Red
    Write-Host "Start Docker Desktop, wait until the engine is running, then run .\DEMO_START.ps1 again." -ForegroundColor Yellow
    exit 1
}

$preferredModel = Get-RuntimeValue "OLLAMA_MODEL"
if ([string]::IsNullOrWhiteSpace($preferredModel)) { $preferredModel = "qwen2.5:3b" }
$providerMode = Get-RuntimeValue "AI_PROVIDER"
if ([string]::IsNullOrWhiteSpace($providerMode)) { $providerMode = "auto"; Set-RuntimeValue "AI_PROVIDER" "auto" }
$ollamaConfigured = (Get-RuntimeValue "OLLAMA_ENABLED") -eq "true"

if ($providerMode -in @("auto", "ollama", "local")) {
    $probe = Test-OllamaHostApi -TimeoutSeconds 8
    if ($probe.Ready) {
        $installedNames = @($probe.Response.models | ForEach-Object { [string]$_.name })
        $installedModel = $installedNames | Where-Object { $_ -eq $preferredModel -or $_ -like "$preferredModel*" } | Select-Object -First 1
        if ($installedModel) {
            Set-RuntimeValue "AI_PROVIDER" "auto"
            Set-RuntimeValue "OLLAMA_ENABLED" "true"
            Set-RuntimeValue "OLLAMA_BASE_URL" "http://host.docker.internal:11434"
            Set-RuntimeValue "OLLAMA_MODEL" $installedModel
            Write-Host "Local Ollama detected: $installedModel" -ForegroundColor Green
        } else {
            Set-RuntimeValue "OLLAMA_ENABLED" "false"
            Write-Host "Ollama is running, but '$preferredModel' is not installed. Verified fallback will remain available." -ForegroundColor Yellow
        }
    } elseif ($ollamaConfigured) {
        # Do not silently disable a previously approved/configured local model just because
        # the Windows service is starting slowly. The backend has a fast safe fallback.
        Write-Host "Ollama is configured but not reachable yet. Keeping the configuration and starting with safe fallback." -ForegroundColor Yellow
    } else {
        Set-RuntimeValue "OLLAMA_ENABLED" "false"
        Write-Host "Local Ollama is not enabled. Copilot will use verified SQL/retrieval fallback." -ForegroundColor DarkYellow
    }
} elseif ($providerMode -in @("disabled", "off", "none")) {
    Set-RuntimeValue "OLLAMA_ENABLED" "false"
}
Normalize-RuntimeFile

$composeArgs = @("--env-file", ".env.runtime")
$currentProjectPrefix = "demo_bank_talent_command_v6_enterprise-"

# Remove this project's stale containers/network without deleting V6 volumes.
& docker compose @composeArgs down --remove-orphans | Out-Null

# Stop older Talent Command releases so a V5.x backend cannot silently own
# localhost:8000/5173 and make smoke tests hit the wrong application version.
$olderTalentContainers = @(& docker ps --format "{{.Names}}" | Where-Object {
    ($_ -like "demo_bank_talent_command*") -and ($_ -notlike "$currentProjectPrefix*")
})
if ($olderTalentContainers.Count -gt 0) {
    Write-Host "Stopping older Demo Bank Talent Command containers that could conflict with V6.0..." -ForegroundColor Yellow
    $olderTalentContainers | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkYellow }
    & docker stop $olderTalentContainers | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Could not stop one or more older Talent Command containers." -ForegroundColor Red
        exit 1
    }
}

# Refuse to start if an unrelated container still owns presentation ports.
$portBlockers = @(& docker ps --format "{{.Names}}|{{.Ports}}" | Where-Object {
    ($_ -match "(?:0\.0\.0\.0|\[::\]):8000->") -or ($_ -match "(?:0\.0\.0\.0|\[::\]):5173->")
})
if ($portBlockers.Count -gt 0) {
    Write-Host "Ports 8000 or 5173 are still occupied by another running container:" -ForegroundColor Red
    $portBlockers | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    Write-Host "Stop that container, then rerun .\DEMO_START.ps1." -ForegroundColor Yellow
    exit 1
}

Write-Host "Starting clean V6.0.1 containers (cached image layers will be reused where possible)..." -ForegroundColor Yellow
& docker compose @composeArgs up -d --build
if ($LASTEXITCODE -ne 0) {
    Write-Host "Docker Compose did not start the V6.0.1 environment." -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host ""
Write-Host "Container status:" -ForegroundColor Cyan
& docker compose @composeArgs ps

Write-Host ""
Write-Host "Waiting for the V6.0.1 backend initialization/integrity gate (first clean V6.0 run may take several minutes)..." -ForegroundColor Yellow
$backendReady = $false
for ($i = 1; $i -le 180; $i++) {
    try {
        $health = Invoke-RestMethod -Uri "http://localhost:8000/health" -TimeoutSec 3
        if ($health.status -eq "ok" -and $health.version -eq "6.0.1") {
            $backendReady = $true
            Write-Host "Backend ready: $($health.product) v$($health.version)" -ForegroundColor Green
            break
        }
        if ($health.status -eq "ok" -and $health.version -ne "6.0.1") {
            Write-Host "A different Talent Command backend is responding on port 8000 (version $($health.version)); V6.0 will not use it." -ForegroundColor Red
            exit 1
        }
    } catch { }
    Start-Sleep -Seconds 2
}

if (-not $backendReady) {
    Write-Host "V6.0.1 backend did not reach its health endpoint. Recent backend logs:" -ForegroundColor Red
    & docker compose @composeArgs logs backend --tail 180
    exit 1
}

Write-Host "Waiting for frontend (V6.0)..." -ForegroundColor Yellow
$frontendReady = $false
for ($i = 1; $i -le 90; $i++) {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:5173" -UseBasicParsing -TimeoutSec 3
        if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 500) {
            $frontendReady = $true
            break
        }
    } catch { }
    Start-Sleep -Seconds 2
}

if (-not $frontendReady) {
    Write-Host "V6.0.1 frontend did not become ready. Recent frontend logs:" -ForegroundColor Red
    & docker compose @composeArgs logs frontend --tail 140
    exit 1
}

Write-Host ""
Write-Host "Presentation environment is ready." -ForegroundColor Green
$localCopilotActive = $false
try {
    $statusRaw = & docker compose @composeArgs exec -T backend python -c "import json; from app.rag import provider_status; print(json.dumps(provider_status()))"
    $statusLine = @($statusRaw) | Select-Object -Last 1
    $aiStatus = $statusLine | ConvertFrom-Json
    if ($aiStatus.preferred_provider -eq "ollama" -and $aiStatus.generation_enabled -eq $true) {
        & docker compose @composeArgs exec -T backend python -c "import urllib.request; urllib.request.urlopen('http://host.docker.internal:11434/api/tags', timeout=6).read()" *> $null
        if ($LASTEXITCODE -eq 0) { $localCopilotActive = $true }
    }
} catch { }
if ($localCopilotActive) {
    Write-Host "HR Copilot mode: verified data + private local Ollama generation" -ForegroundColor Green
} else {
    Write-Host "HR Copilot mode: verified SQL/retrieval fallback (local LLM not active)" -ForegroundColor Yellow
    Write-Host "If Ollama is intended, run .\SETUP_LOCAL_COPILOT.ps1 and then .\DEMO_HEALTH.ps1." -ForegroundColor DarkYellow
}
Write-Host "Frontend: http://localhost:5173" -ForegroundColor White
Write-Host "API docs: http://localhost:8000/docs" -ForegroundColor White
Start-Process "http://localhost:5173"

Write-Host ""
Write-Host "Administrator: admin@demobank.demo / Admin@26" -ForegroundColor White
Write-Host "HR Manager:    hr@demobank.demo / HR@2026" -ForegroundColor White
Write-Host "Talent:        talent@demobank.demo / Talent@26" -ForegroundColor White
Write-Host "Panel:         panel@demobank.demo / Panel@26" -ForegroundColor White
Write-Host "Viewer:        viewer@demobank.demo / View@2026" -ForegroundColor White
Write-Host ""
Write-Host "Now run: .\DEMO_HEALTH.ps1" -ForegroundColor Cyan
Write-Host "Then run: .\COPILOT_SMOKE.ps1" -ForegroundColor Cyan
Write-Host "Finally: .\FINAL_SMOKE.ps1" -ForegroundColor Cyan
