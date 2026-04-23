# UserPromptSubmit hook -- when the current session crosses 200K tokens, nudge Claude
# to suggest /compact at the end of its reply. Threshold matches the red zone in statusline.ps1.

$ErrorActionPreference = 'SilentlyContinue'
$raw = [Console]::In.ReadToEnd()
if (-not $raw) { exit 0 }
$data = $raw | ConvertFrom-Json
$sessionId = $data.session_id
$cwd       = $data.cwd
if (-not $sessionId -or -not $cwd) { exit 0 }

$threshold = 200000

$projectKey  = $cwd -replace '[:\\/]', '-'
$sessionFile = Join-Path $env:USERPROFILE ".claude\projects\$projectKey\$sessionId.jsonl"
if (-not (Test-Path $sessionFile)) { exit 0 }

$lastUsage = $null
try {
    $tail = Get-Content $sessionFile -Tail 50 -ErrorAction Stop
} catch { exit 0 }
foreach ($line in $tail) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    try {
        $obj = $line | ConvertFrom-Json -ErrorAction Stop
    } catch { continue }
    if ($obj.type -eq 'assistant' -and $obj.message.usage) {
        $lastUsage = $obj.message.usage
    }
}
if (-not $lastUsage) { exit 0 }

$total = [int]$lastUsage.input_tokens +
         [int]$lastUsage.cache_creation_input_tokens +
         [int]$lastUsage.cache_read_input_tokens

if ($total -lt $threshold) { exit 0 }

$tokensK = [math]::Round($total / 1000)
Write-Output "save-tokens compact-suggester: This session is at ${tokensK}K tokens (past the 200K threshold where per-turn re-read cost climbs sharply). At the very end of your reply, briefly suggest the user run /compact to summarize the conversation history and reduce per-turn token consumption. Do not run /compact yourself."
exit 0
