param(
    [string]$Model = "qwen2.5:3b"
)

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
Write-Host "Demo Bank Talent Command V6.0.1 - Private Local HR Copilot Setup" -ForegroundColor Cyan
Write-Host "Exact recruitment facts remain database-backed. Ollama is used only for grounded conversational/fuzzy answers." -ForegroundColor DarkGray
Write-Host ""

$ollama = Get-Command ollama -ErrorAction SilentlyContinue
if (-not $ollama) {
    Write-Host "Ollama is not installed or is not available in PATH." -ForegroundColor Red
    Write-Host "Install the bank-approved Windows Ollama package, reopen PowerShell, and rerun this script." -ForegroundColor Yellow
    exit 1
}
Write-Host "Ollama CLI found: $($ollama.Source)" -ForegroundColor Green

$probe = Test-OllamaHostApi -TimeoutSeconds 10
if (-not $probe.Ready) {
    Write-Host "Ollama API is not responding yet. Waiting for the Windows app/service..." -ForegroundColor Yellow
    for ($i = 1; $i -le 15; $i++) {
        Start-Sleep -Seconds 1
        $probe = Test-OllamaHostApi -TimeoutSeconds 5
        if ($probe.Ready) { break }
    }
}

if (-not $probe.Ready) {
    Write-Host "Starting Ollama service..." -ForegroundColor Yellow
    try { Start-Process -FilePath $ollama.Source -ArgumentList "serve" -WindowStyle Hidden } catch { }
    for ($i = 1; $i -le 30; $i++) {
        Start-Sleep -Seconds 1
        $probe = Test-OllamaHostApi -TimeoutSeconds 5
        if ($probe.Ready) { break }
    }
}

if (-not $probe.Ready) {
    Write-Host "Ollama is installed but its API is not reachable on port 11434." -ForegroundColor Red
    Write-Host "Verify with: Invoke-RestMethod http://127.0.0.1:11434/api/tags" -ForegroundColor Yellow
    exit 1
}

Write-Host "Ollama API reachable: $($probe.Endpoint)" -ForegroundColor Green
$names = @($probe.Response.models | ForEach-Object { [string]$_.name })
$installed = $names | Where-Object { $_ -eq $Model -or $_ -like "$Model*" } | Select-Object -First 1
if (-not $installed) {
    Write-Host "Local model '$Model' is not installed. Pulling it now..." -ForegroundColor Yellow
    & $ollama.Source pull $Model
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Model download failed. Check network access and rerun this script." -ForegroundColor Red
        exit $LASTEXITCODE
    }
    $probe = Test-OllamaHostApi -TimeoutSeconds 10
    $names = @($probe.Response.models | ForEach-Object { [string]$_.name })
    $installed = $names | Where-Object { $_ -eq $Model -or $_ -like "$Model*" } | Select-Object -First 1
}
if (-not $installed) { throw "Model '$Model' is not available after setup." }
Write-Host "Local model detected: $installed" -ForegroundColor Green

Set-RuntimeValue "AI_PROVIDER" "auto"
Set-RuntimeValue "OLLAMA_ENABLED" "true"
Set-RuntimeValue "OLLAMA_BASE_URL" "http://host.docker.internal:11434"
Set-RuntimeValue "OLLAMA_MODEL" $installed
Set-RuntimeValue "AI_TIMEOUT_SECONDS" "30"
Set-RuntimeValue "AI_TEMPERATURE" "0.10"
Normalize-RuntimeFile

Write-Host "Runtime configuration normalized and saved to .env.runtime." -ForegroundColor Green

& docker version *> $null
if ($LASTEXITCODE -eq 0) {
    $composeArgs = @("--env-file", ".env.runtime")
    $backendId = (& docker compose @composeArgs ps -q backend 2>$null).Trim()
    if ($backendId) {
        Write-Host "Recreating backend so the local Copilot configuration is applied..." -ForegroundColor Yellow
        & docker compose @composeArgs up -d --force-recreate backend
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

        $ready = $false
        for ($i = 1; $i -le 90; $i++) {
            try {
                $health = Invoke-RestMethod -Uri "http://localhost:8000/health" -TimeoutSec 3
                if ($health.status -eq "ok" -and $health.version -eq "6.0.1") { $ready = $true; break }
            } catch { }
            Start-Sleep -Seconds 2
        }
        if (-not $ready) { throw "Backend did not return to a healthy V6.0.1 state." }

        & docker compose @composeArgs exec -T backend python -c "import urllib.request; urllib.request.urlopen('http://host.docker.internal:11434/api/tags', timeout=10).read(); print('OLLAMA_BRIDGE_OK')"
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Windows Ollama works, but the backend container cannot reach host.docker.internal:11434." -ForegroundColor Red
            Write-Host "Run .\DEMO_HEALTH.ps1 for the exact Copilot diagnostic." -ForegroundColor Yellow
            exit 1
        }

        try {
            $loginBody = @{ email = "hr@demobank.demo"; password = "HR@2026" } | ConvertTo-Json
            $login = Invoke-RestMethod -Method Post -Uri "http://localhost:8000/auth/login" -ContentType "application/json" -Body $loginBody -TimeoutSec 15
            if (-not $login.totp_required) {
                $headers = @{ Authorization = "Bearer $($login.access_token)" }
                $chatBody = @{ messages = @(@{ role = "user"; content = "Find candidates with strong Python and analytics backgrounds and summarize the evidence." }) } | ConvertTo-Json -Depth 8
                $chat = Invoke-RestMethod -Method Post -Uri "http://localhost:8000/chatbot/hr" -Headers $headers -ContentType "application/json" -Body $chatBody -TimeoutSec 60
                if ($chat.ai.provider -eq "ollama" -and $chat.ai.generative -eq $true) {
                    Write-Host "Live Copilot verification: PASS - local Ollama generation is active." -ForegroundColor Green
                } else {
                    Write-Host "Copilot is configured, but the live fuzzy request used fallback." -ForegroundColor Yellow
                    Write-Host "Provider: $($chat.ai.provider) | Error: $($chat.ai.error)" -ForegroundColor DarkYellow
                }
            }
        } catch {
            Write-Host "Live Copilot verification could not complete: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Talent Command is not running. Configuration is ready; run .\DEMO_START.ps1." -ForegroundColor Cyan
    }
} else {
    Write-Host "Docker is not running. Copilot configuration is saved; start Docker then run .\DEMO_START.ps1." -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Setup complete." -ForegroundColor Green
