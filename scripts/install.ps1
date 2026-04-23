# Idempotent installer — copies plain-terse style, slash commands, and hooks from this plugin
# into the global ~/.claude locations Claude Code reads from. mtime check skips unchanged files,
# so re-running is safe.

$ErrorActionPreference = 'Stop'

$pluginRoot = Split-Path -Parent $PSScriptRoot
$claudeRoot = Join-Path $env:USERPROFILE '.claude'

$pairs = @(
    @{ Src = Join-Path $pluginRoot 'output-styles\plain-terse.md';   Dst = Join-Path $claudeRoot 'output-styles\plain-terse.md' },
    @{ Src = Join-Path $pluginRoot 'commands\token-rules.md';        Dst = Join-Path $claudeRoot 'commands\token-rules.md' },
    @{ Src = Join-Path $pluginRoot 'commands\usage.md';              Dst = Join-Path $claudeRoot 'commands\usage.md' },
    @{ Src = Join-Path $pluginRoot 'commands\curate-memory.md';      Dst = Join-Path $claudeRoot 'commands\curate-memory.md' },
    @{ Src = Join-Path $pluginRoot 'commands\model-rethink.md';      Dst = Join-Path $claudeRoot 'commands\model-rethink.md' },
    @{ Src = Join-Path $pluginRoot 'hooks\compact-suggester.ps1';    Dst = Join-Path $claudeRoot 'hooks\compact-suggester.ps1' },
    @{ Src = Join-Path $pluginRoot 'hooks\model-suggester.ps1';      Dst = Join-Path $claudeRoot 'hooks\model-suggester.ps1' }
)

foreach ($d in @('output-styles', 'commands', 'hooks')) {
    $p = Join-Path $claudeRoot $d
    if (-not (Test-Path $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
}

$copied  = 0
$skipped = 0
$missing = @()

foreach ($p in $pairs) {
    if (-not (Test-Path $p.Src)) { $missing += $p.Src; continue }

    $needCopy = $true
    if (Test-Path $p.Dst) {
        $srcTime = (Get-Item $p.Src).LastWriteTime
        $dstTime = (Get-Item $p.Dst).LastWriteTime
        if ($srcTime -le $dstTime) { $needCopy = $false }
    }

    if ($needCopy) {
        Copy-Item -Path $p.Src -Destination $p.Dst -Force
        Write-Host "  copied   $(Split-Path -Leaf $p.Src)" -ForegroundColor Green
        $copied++
    } else {
        Write-Host "  skipped  $(Split-Path -Leaf $p.Src) (up to date)" -ForegroundColor DarkGray
        $skipped++
    }
}

Write-Host ""
Write-Host "save-tokens install: $copied copied, $skipped skipped" -ForegroundColor Cyan
if ($missing) {
    Write-Host ""
    Write-Host "Missing source files (skipped):" -ForegroundColor Yellow
    foreach ($m in $missing) { Write-Host "  $m" -ForegroundColor Yellow }
}

Write-Host ""
Write-Host "Next step: ensure ~/.claude/settings.json wires both new hooks under hooks.UserPromptSubmit." -ForegroundColor Yellow
Write-Host "Hook commands to add:" -ForegroundColor Yellow
Write-Host "  powershell -NoProfile -ExecutionPolicy Bypass -File `"$env:USERPROFILE\.claude\hooks\compact-suggester.ps1`"" -ForegroundColor DarkGray
Write-Host "  powershell -NoProfile -ExecutionPolicy Bypass -File `"$env:USERPROFILE\.claude\hooks\model-suggester.ps1`"" -ForegroundColor DarkGray
Write-Host ""
Write-Host "Then restart Claude Code (output styles and hooks load at session start, not hot-reloaded)." -ForegroundColor Yellow
