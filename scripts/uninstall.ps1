# Removes files this plugin's install.ps1 deployed.
# Does NOT touch ~/.claude/settings.json — remove the hook entries there by hand.

$claudeRoot = Join-Path $env:USERPROFILE '.claude'

$paths = @(
    'output-styles\plain-terse.md',
    'commands\token-rules.md',
    'commands\usage.md',
    'commands\curate-memory.md',
    'commands\model-rethink.md',
    'hooks\compact-suggester.ps1',
    'hooks\model-suggester.ps1'
)

$removed = 0
foreach ($rel in $paths) {
    $full = Join-Path $claudeRoot $rel
    if (Test-Path $full) {
        Remove-Item -Path $full -Force
        Write-Host "  removed  $rel" -ForegroundColor Yellow
        $removed++
    }
}

Write-Host ""
Write-Host "save-tokens uninstall: $removed file(s) removed." -ForegroundColor Cyan
Write-Host ""
Write-Host "Reminder: also remove the compact-suggester / model-suggester entries from ~/.claude/settings.json hooks.UserPromptSubmit, and revert statusLine.command if you want the previous status line back." -ForegroundColor Yellow
