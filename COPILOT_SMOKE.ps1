$ErrorActionPreference = "Stop"
Set-Location -LiteralPath $PSScriptRoot

$Base = "http://localhost:8000"
$Pass = 0
$Fail = 0

function Pass([string]$Message) {
    $script:Pass++
    Write-Host "PASS  $Message" -ForegroundColor Green
}
function Fail([string]$Message, [string]$Detail = "") {
    $script:Fail++
    if ($Detail) { Write-Host "FAIL  $Message -- $Detail" -ForegroundColor Red }
    else { Write-Host "FAIL  $Message" -ForegroundColor Red }
}
function Check([bool]$Condition, [string]$Message, [string]$Detail = "") {
    if ($Condition) { Pass $Message } else { Fail $Message $Detail }
}

Write-Host "" 
Write-Host "Demo Bank Talent Command V6.0.1 -- HR Copilot live smoke" -ForegroundColor Cyan
Write-Host "Checks verified recruitment answers, date routing, conversational follow-ups and safe local-AI fallback." -ForegroundColor DarkGray
Write-Host ""

# Guard against accidentally testing an older Talent Command backend that still owns port 8000.
try {
    $health = Invoke-RestMethod -Uri "$Base/health" -TimeoutSec 10
    if ($health.status -ne "ok" -or $health.version -ne "6.0.1") {
        Write-Host "COPILOT SMOKE: FAIL -- wrong backend on port 8000 (expected V6.0.1, got $($health.version))." -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "COPILOT SMOKE: FAIL -- V6.0.1 backend unavailable: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

try {
    $loginBody = @{ email = "hr@demobank.demo"; password = "HR@2026" } | ConvertTo-Json
    $login = Invoke-RestMethod -Method Post -Uri "$Base/auth/login" -ContentType "application/json" -Body $loginBody -TimeoutSec 15
    if ($login.totp_required) { throw "HR demo account has 2FA enabled; use a fresh demo database or disable 2FA after testing." }
    $Headers = @{ Authorization = "Bearer $($login.access_token)" }
    Pass "HR Manager login"
} catch {
    Write-Host "COPILOT SMOKE: FAIL -- login/backend unavailable: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

$Cases = @(
    @{ Prompt = "what date is today"; Expect = "Today is" },
    @{ Prompt = "what day is today"; Expect = "Today is" },
    @{ Prompt = "total candidates"; Expect = "candidate" },
    @{ Prompt = "pipeline breakdown"; Expect = "Talent pipeline snapshot" },
    @{ Prompt = "How many resumes do we have?"; Expect = "resume" },
    @{ Prompt = "review queue"; Expect = "manual review" },
    @{ Prompt = "How many active requisitions are there?"; Expect = "active requisition" },
    @{ Prompt = "How many interviews are there?"; Expect = "interview records" },
    @{ Prompt = "Interviews tomorrow"; Expect = "tomorrow" },
    @{ Prompt = "Summarize interviews awaiting feedback"; Expect = "awaiting feedback" },
    @{ Prompt = "Find Python candidates with at least 3 years of experience"; Expect = "matching" },
    @{ Prompt = "Find Python candidates with BS and at least 3 years of experience"; Expect = "education" },
    @{ Prompt = "show candidates in Data & Analytics department"; Expect = "department" },
    @{ Prompt = "Show employee referral candidates"; Expect = "employee-referral candidate" },
    @{ Prompt = "Candidates waiting longest in pipeline"; Expect = "Candidates waiting longest" },
    @{ Prompt = "Which active requisitions have no shortlisted candidates?"; Expect = "active requisition" },
    @{ Prompt = "Summarize interviews this week"; Expect = "interview" },
    @{ Prompt = "How many employees do we have?"; Expect = "not Demo Bank employee headcount" }
)

$Forbidden = @("SEMANTIC TOP-K RETRIEVAL", "semantic score", "AI generation is unavailable", "[object Object]")

foreach ($Case in $Cases) {
    try {
        $body = @{ messages = @(@{ role = "user"; content = $Case.Prompt }) } | ConvertTo-Json -Depth 6
        $response = Invoke-RestMethod -Method Post -Uri "$Base/chatbot/hr" -Headers $Headers -ContentType "application/json" -Body $body -TimeoutSec 30
        $reply = [string]$response.reply
        Check (-not [string]::IsNullOrWhiteSpace($reply)) "Reply returned: $($Case.Prompt)"
        Check ($reply -match [regex]::Escape($Case.Expect)) "Expected business content: $($Case.Prompt)" $reply
        $bad = $false
        foreach ($term in $Forbidden) {
            if ($reply.Contains($term)) { $bad = $true; break }
        }
        Check (-not $bad) "No developer/raw retrieval output: $($Case.Prompt)" $reply
        if ($response.ai -and $Case.Prompt -ne "show candidates in Data & Analytics department") {
            Check ($response.ai.grounded -eq $true) "Grounded response metadata: $($Case.Prompt)"
        }
    } catch {
        Fail "Copilot request: $($Case.Prompt)" $_.Exception.Message
    }
}


# Context-follow-up regression: "How many?" must inherit interview context,
# not fall back to total candidates.
try {
    $firstBody = @{ messages = @(@{ role = "user"; content = "Interviews today" }) } | ConvertTo-Json -Depth 6
    $first = Invoke-RestMethod -Method Post -Uri "$Base/chatbot/hr" -Headers $Headers -ContentType "application/json" -Body $firstBody -TimeoutSec 30
    $followBody = @{
        messages = @(
            @{ role = "user"; content = "Interviews today" },
            @{ role = "assistant"; content = [string]$first.reply },
            @{ role = "user"; content = "How many?" }
        )
    } | ConvertTo-Json -Depth 8
    $follow = Invoke-RestMethod -Method Post -Uri "$Base/chatbot/hr" -Headers $Headers -ContentType "application/json" -Body $followBody -TimeoutSec 30
    $sourceText = @($follow.sources) -join " "
    Check ($sourceText -match "interview_entries") "Conversational follow-up keeps interview context" ([string]$follow.reply)
    Check (-not ([string]$follow.reply -match "candidates in Talent Command")) "Follow-up does not misroute to candidate total" ([string]$follow.reply)
} catch {
    Fail "Conversational follow-up regression" $_.Exception.Message
}

# If local generation is configured, prove that one fuzzy request actually uses Ollama.
try {
    $composeArgs = @()
    if (Test-Path ".env.runtime") { $composeArgs += @("--env-file", ".env.runtime") }
    $statusRaw = & docker compose @composeArgs exec -T backend python -c "import json; from app.rag import provider_status; print(json.dumps(provider_status()))"
    $status = (@($statusRaw) | Select-Object -Last 1) | ConvertFrom-Json
    if ($status.preferred_provider -eq "ollama" -and $status.generation_enabled -eq $true) {
        $body = @{ messages = @(@{ role = "user"; content = "Find candidates with strong Python and analytics backgrounds and summarize the evidence." }) } | ConvertTo-Json -Depth 6
        $response = Invoke-RestMethod -Method Post -Uri "$Base/chatbot/hr" -Headers $Headers -ContentType "application/json" -Body $body -TimeoutSec 60
        Check ($response.ai.provider -eq "ollama" -and $response.ai.generative -eq $true) "Configured local Ollama is used for fuzzy grounded answer" ("provider=" + $response.ai.provider + "; error=" + $response.ai.error)
    } else {
        Write-Host "SKIP  Local Ollama generative check - provider is not enabled; deterministic fallback is allowed." -ForegroundColor DarkYellow
    }
} catch {
    Fail "Local Ollama generative verification" $_.Exception.Message
}

Write-Host ""
Write-Host ("Copilot checks passed: {0} | failed: {1}" -f $Pass, $Fail) -ForegroundColor Cyan
if ($Fail -eq 0) {
    Write-Host "COPILOT SMOKE: PASS" -ForegroundColor Green
    exit 0
}
Write-Host "COPILOT SMOKE: FAIL" -ForegroundColor Red
exit 1
