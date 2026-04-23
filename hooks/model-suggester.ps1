# UserPromptSubmit hook -- fires only on the first prompt of each session.
# Classifies the prompt by simple heuristics and asks Claude to suggest a model switch
# when the recommendation differs from the current model. Claude knows its own model;
# the hook just emits the recommendation.

$ErrorActionPreference = 'SilentlyContinue'
$raw = [Console]::In.ReadToEnd()
if (-not $raw) { exit 0 }
$data = $raw | ConvertFrom-Json
$sessionId = $data.session_id
$prompt    = [string]$data.prompt
if (-not $sessionId) { exit 0 }
if ([string]::IsNullOrWhiteSpace($prompt)) { exit 0 }

$flagFile = Join-Path $env:TEMP "save-tokens-model-fired-$sessionId.flag"
if (Test-Path $flagFile) { exit 0 }
# Sweep stale flags (>24h) before creating a new one so TEMP doesn't accumulate forever.
try {
    Get-ChildItem $env:TEMP -Filter 'save-tokens-model-fired-*.flag' -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -lt (Get-Date).AddHours(-24) } |
        Remove-Item -Force -ErrorAction SilentlyContinue
} catch {}
try { New-Item -ItemType File -Path $flagFile -Force | Out-Null } catch {}

$lower  = $prompt.ToLower()
$length = $prompt.Length

$opusKeywords  = @('architect', 'design ', 'debug', 'plan ', 'review', 'audit', 'refactor', 'analyze', 'investigate', 'critique')
$haikuKeywords = @('rename', 'format', 'fix typo', 'list ', 'echo ', 'show me ', 'what is ', 'what are ', 'tldr')

$recommended = 'sonnet'
$reason      = 'general coding work'

foreach ($kw in $opusKeywords) {
    if ($lower.Contains($kw)) { $recommended = 'opus'; $reason = "mentions '$($kw.Trim())'"; break }
}

if ($recommended -eq 'sonnet' -and $length -gt 800) {
    $recommended = 'opus'; $reason = "long prompt ($length chars suggests complex task)"
}

if ($recommended -eq 'sonnet' -and $length -lt 200) {
    foreach ($kw in $haikuKeywords) {
        if ($lower.Contains($kw)) {
            $recommended = 'haiku'; $reason = "short prompt with '$($kw.Trim())' verb"
            break
        }
    }
}

Write-Output "save-tokens model-suggester: This is the first prompt of the session. By heuristic the task looks ${recommended}-sized ($reason). At the very start of your reply, if your current model differs meaningfully from this recommendation, ask the user one short question: 'This looks ${recommended}-sized -- switch to /model ${recommended}?'. Then continue with whichever they prefer. If your current model already matches, ignore this reminder and proceed normally. Do not switch models yourself."
exit 0
