$ErrorActionPreference = "Stop"
Set-Location -LiteralPath $PSScriptRoot

$Base = "http://localhost:8000"
$Frontend = "http://localhost:5173"
$pass = 0
$fail = 0

function Pass([string]$Message) {
    $script:pass++
    Write-Host "PASS  $Message" -ForegroundColor Green
}
function Fail([string]$Message, [string]$Detail = "") {
    $script:fail++
    if ($Detail) { Write-Host "FAIL  $Message -- $Detail" -ForegroundColor Red }
    else { Write-Host "FAIL  $Message" -ForegroundColor Red }
}
function Check([bool]$Condition, [string]$Message, [string]$Detail = "") {
    if ($Condition) { Pass $Message } else { Fail $Message $Detail }
}
function Login([string]$Email, [string]$Password) {
    $body = @{ email = $Email; password = $Password } | ConvertTo-Json
    $r = Invoke-RestMethod -Method Post -Uri "$Base/auth/login" -ContentType "application/json" -Body $body -TimeoutSec 15
    if ($r.totp_required) {
        throw "2FA is enabled on $Email. This smoke script cannot enter a TOTP code. Use another untouched demo account or disable 2FA after your 2FA demonstration."
    }
    if (-not $r.access_token) { throw "Login returned no access token for $Email" }
    return $r.access_token
}
function AuthHeaders([string]$Token) {
    return @{ Authorization = "Bearer $Token" }
}
function HttpStatus([string]$Uri, [hashtable]$Headers = @{}) {
    try {
        $r = Invoke-WebRequest -Uri $Uri -Headers $Headers -UseBasicParsing -TimeoutSec 15
        return [int]$r.StatusCode
    } catch {
        if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
            return [int]$_.Exception.Response.StatusCode
        }
        throw
    }
}

Write-Host ""
Write-Host "Demo Bank Talent Command V6.0.1 -- non-destructive final smoke" -ForegroundColor Cyan
Write-Host "This checks live APIs/RBAC/JD/Copilot. JD matching may add an audit event but does not change candidate/job/interview state." -ForegroundColor DarkGray
Write-Host ""

try {
    $health = Invoke-RestMethod -Uri "$Base/health" -TimeoutSec 15
    Check ($health.status -eq "ok") "Backend health" ("status=" + $health.status)
    if ($health.version -ne "6.0.1") {
        Fail "Backend version is 6.0.1" ("version=" + $health.version)
        Write-Host "FINAL SMOKE: FAIL -- an older/wrong backend owns localhost:8000. Start the V6.0.1 environment first." -ForegroundColor Red
        exit 1
    }
    Pass "Backend version is 6.0.1"
} catch {
    Fail "Backend health" $_.Exception.Message
    Write-Host "FINAL SMOKE: FAIL -- backend is unavailable" -ForegroundColor Red
    exit 1
}

try {
    $frontStatus = HttpStatus $Frontend
    Check ($frontStatus -ge 200 -and $frontStatus -lt 500) "Frontend responds on :5173" ("HTTP " + $frontStatus)
} catch { Fail "Frontend responds on :5173" $_.Exception.Message }

# HR Manager exercises the operational HR surface without depending on Admin 2FA state.
try {
    $hrToken = Login "hr@demobank.demo" "HR@2026"
    $hrHeaders = AuthHeaders $hrToken
    Pass "HR Manager login"

    $me = Invoke-RestMethod -Uri "$Base/auth/me" -Headers $hrHeaders -TimeoutSec 15
    Check ($me.role -eq "hrmanager") "HR identity / role"

    $candidates = @(Invoke-RestMethod -Uri "$Base/candidates" -Headers $hrHeaders -TimeoutSec 30)
    Check ($candidates.Count -ge 1250) "Candidate cohort >= 1,250" ("count=" + $candidates.Count)

    $jobs = @(Invoke-RestMethod -Uri "$Base/jobs" -Headers $hrHeaders -TimeoutSec 20)
    $activeJobs = @($jobs | Where-Object { $_.status -eq "Active" })
    Check ($activeJobs.Count -ge 12) "At least 12 active requisitions" ("active=" + $activeJobs.Count)

    $publicJobs = @(Invoke-RestMethod -Uri "$Base/public/jobs" -TimeoutSec 20)
    Check ($publicJobs.Count -ge 12) "Candidate Careers exposes active openings" ("public=" + $publicJobs.Count)

    $analytics = Invoke-RestMethod -Uri "$Base/analytics/pipeline" -Headers $hrHeaders -TimeoutSec 30
    Check ([int]$analytics.total_candidates -eq $candidates.Count) "Analytics total matches Talent Pool" ("analytics=" + $analytics.total_candidates + "; candidates=" + $candidates.Count)

    $interviews = @(Invoke-RestMethod -Uri "$Base/interviews" -Headers $hrHeaders -TimeoutSec 30)
    Check ($interviews.Count -gt 0) "Interview records available" ("count=" + $interviews.Count)

    $panelUsers = @(Invoke-RestMethod -Uri "$Base/users/interviewers" -Headers $hrHeaders -TimeoutSec 15)
    Check ($panelUsers.Count -ge 1) "Active Interview Panel directory available" ("count=" + $panelUsers.Count)
    if ($panelUsers.Count -ge 1) {
        Check ($panelUsers[0].role -eq "interviewer") "Panel directory contains interviewer role only"
    }

    $chatBody = @{ messages = @(@{ role = "user"; content = "total candidates" }) } | ConvertTo-Json -Depth 6
    $chat = Invoke-RestMethod -Method Post -Uri "$Base/chatbot/hr" -Headers $hrHeaders -ContentType "application/json" -Body $chatBody -TimeoutSec 30
    $expectedCountText = [string]$candidates.Count
    Check (($chat.reply -as [string]) -match [regex]::Escape($expectedCountText)) "Copilot total-candidates intent is grounded" ($chat.reply -as [string])
    Check (-not (($chat.reply -as [string]) -match "SEMANTIC TOP-K RETRIEVAL")) "Copilot does not expose raw semantic retrieval"

    $jdText = "Python, BS, 3 years"
    $analyzeBody = @{ jd_text = $jdText } | ConvertTo-Json
    $analysis = Invoke-RestMethod -Method Post -Uri "$Base/jd-matcher/analyze" -Headers $hrHeaders -ContentType "application/json" -Body $analyzeBody -TimeoutSec 30
    Check ($analysis.requirements.match_mode -eq "combined_criteria") "JD combined-criteria mode"
    Check ([int]$analysis.requirements.min_experience_years -eq 3) "JD detects 3 years"
    Check ($analysis.requirements.required_education -eq "Bachelor's") "JD detects Bachelor's"
    Check (@($analysis.requirements.required_skills) -contains "Python") "JD detects Python"

    $matchBody = @{ jd_text = $jdText; limit = 5 } | ConvertTo-Json -Depth 6
    $match = Invoke-RestMethod -Method Post -Uri "$Base/jd-matcher/match" -Headers $hrHeaders -ContentType "application/json" -Body $matchBody -TimeoutSec 180
    Check (@($match.results).Count -gt 0) "JD ranking returns candidates"
    if (@($match.results).Count -gt 0) {
        Check ([int]$match.results[0].relevance -ge 0 -and [int]$match.results[0].relevance -le 100) "Top JD relevance is bounded 0-100"
    }
} catch {
    Fail "HR operational smoke" $_.Exception.Message
}

# Viewer: only read-only requisitions + analytics; no candidate/interview PII APIs.
try {
    $viewerToken = Login "viewer@demobank.demo" "View@2026"
    $viewerHeaders = AuthHeaders $viewerToken
    Pass "Executive Viewer login"
    Check ((HttpStatus "$Base/jobs" $viewerHeaders) -eq 200) "Viewer can read requisitions"
    Check ((HttpStatus "$Base/analytics/pipeline" $viewerHeaders) -eq 200) "Viewer can read recruitment analytics"
    Check ((HttpStatus "$Base/candidates" $viewerHeaders) -eq 403) "Viewer is blocked from candidate PII"
    Check ((HttpStatus "$Base/interviews" $viewerHeaders) -eq 403) "Viewer is blocked from Interview Desk API"
} catch {
    Fail "Executive Viewer RBAC smoke" $_.Exception.Message
}

# Interview Panel: assigned interviews only; no requisition/analytics bypass.
try {
    $panelToken = Login "panel@demobank.demo" "Panel@26"
    $panelHeaders = AuthHeaders $panelToken
    Pass "Interview Panel login"
    Check ((HttpStatus "$Base/interviews" $panelHeaders) -eq 200) "Interview Panel can read assigned Interview Desk"
    Check ((HttpStatus "$Base/jobs" $panelHeaders) -eq 403) "Interview Panel cannot bypass into requisitions"
    Check ((HttpStatus "$Base/analytics/pipeline" $panelHeaders) -eq 403) "Interview Panel cannot bypass into analytics"
    Check ((HttpStatus "$Base/candidates" $panelHeaders) -eq 403) "Interview Panel cannot retrieve Talent Pool PII"
} catch {
    Fail "Interview Panel RBAC smoke" $_.Exception.Message
}

Write-Host ""
Write-Host ("Checks passed: {0} | failed: {1}" -f $pass, $fail) -ForegroundColor Cyan
if ($fail -eq 0) {
    Write-Host "FINAL SMOKE: PASS" -ForegroundColor Green
    exit 0
}
Write-Host "FINAL SMOKE: FAIL" -ForegroundColor Red
exit 1
