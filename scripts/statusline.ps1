# Claude Code status line — OPSEC edition.
# Grid of spaced rows: context · 5H · 7D · identity. Monochrome-lean palette with amber
# caution and crimson critical as the only signal colors. Labels dim-italic uppercase,
# values ivory, bars are smooth Unicode block fills on a hairline track.
#
# Shows: context usage, 5H / 7D rate limits, project name, peak-window countdown.
# Suppresses: session cost, git branch, and model name when on the default model.
# Crosses 85% on anything important → bold + crimson for loud-but-local warning.

[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
$payload = $Input | Out-String | ConvertFrom-Json

$esc   = [char]27
$reset = "$esc[0m"
$bold  = "$esc[1m"

# Palette: cool slate framing, ivory primary, sage for calm, amber for caution, crimson for critical.
$labelC    = "$esc[3m$esc[38;2;132;136;142m"
$hairlineC = "$esc[38;2;72;76;82m"
$ivoryC    = "$esc[38;2;228;222;212m"
$sageC     = "$esc[38;2;140;160;125m"
$amberC    = "$esc[38;2;220;170;80m"
$crimsonC  = "$esc[38;2;210;70;60m"
$modelC    = "$esc[38;2;148;138;128m"

$FULL  = [char]0x2588
$LIGHT = [char]0x2591
$DOT   = [char]0x00B7
$ARROW = [char]0x25B8

function New-Bar {
    param([double]$Pct, [int]$Width, [string]$FillColor)
    if ($Pct -lt 0) { $Pct = 0 } elseif ($Pct -gt 100) { $Pct = 100 }
    $eighths    = [int][math]::Round(($Pct / 100.0) * $Width * 8)
    $fullBlocks = [math]::Floor($eighths / 8)
    $partial    = $eighths % 8
    if ($fullBlocks -ge $Width) { $fullBlocks = $Width; $partial = 0 }

    $filled  = ([string]$FULL) * $fullBlocks
    $trailer = ''
    $emptyCount = $Width - $fullBlocks
    if ($partial -gt 0 -and $fullBlocks -lt $Width) {
        # Partial block codepoints 0x258F..0x2589 = 1/8..7/8 filled; 0x2590 - n picks the right one.
        $trailer    = [char](0x2590 - $partial)
        $emptyCount = $Width - $fullBlocks - 1
    }
    $track = ([string]$LIGHT) * $emptyCount

    return "${FillColor}${filled}${trailer}${reset}${hairlineC}${track}${reset}"
}

function Get-CtxColor {
    param([int]$Pct)
    if ($Pct -ge 85)     { return $crimsonC }
    elseif ($Pct -ge 60) { return $amberC }
    else                 { return $sageC }
}

function Get-RateColor {
    param([int]$Pct)
    if ($Pct -ge 85)     { return $crimsonC }
    elseif ($Pct -ge 60) { return $amberC }
    else                 { return $ivoryC }
}

function Format-Label { param([string]$Text) return "${labelC}${Text}${reset}" }

function Format-Pct {
    # Critical → bold + color; else → plain color.
    param([int]$Pct, [string]$Color)
    if ($Pct -ge 85) { return "${bold}${Color}${Pct}%${reset}" }
    else             { return "${Color}${Pct}%${reset}" }
}

function Get-PeakCountdown {
    # Returns @{ Tag; TimeLeft } with a 60s cache so the countdown ticks without a registry hit per render.
    $cache = Join-Path $env:TEMP "save-tokens-peak-cache.json"
    $now   = [int][DateTimeOffset]::Now.ToUnixTimeSeconds()
    try {
        $pc = Get-Content $cache -Raw -ErrorAction Stop | ConvertFrom-Json
        if ([int]$pc.validUntil -gt $now) {
            return @{ Tag = [string]$pc.tag; TimeLeft = [string]$pc.timeLeft }
        }
    } catch {}

    $result = @{ Tag = ''; TimeLeft = '' }
    try {
        $tz = [System.TimeZoneInfo]::FindSystemTimeZoneById('Pacific Standard Time')
    } catch { return $result }
    $local   = [System.TimeZoneInfo]::ConvertTime((Get-Date), $tz)
    $weekday = $local.DayOfWeek -ne [DayOfWeek]::Saturday -and $local.DayOfWeek -ne [DayOfWeek]::Sunday
    $isPeak  = $weekday -and $local.Hour -ge 5 -and $local.Hour -lt 11

    if ($isPeak) {
        $end  = Get-Date -Year $local.Year -Month $local.Month -Day $local.Day -Hour 11 -Minute 0 -Second 0
        $span = $end - $local
        $result.Tag = 'PEAK'
    } else {
        # Next weekday 5 AM PT — walk forward until we land on Mon-Fri.
        if ($weekday -and $local.Hour -lt 5) {
            $next = Get-Date -Year $local.Year -Month $local.Month -Day $local.Day -Hour 5 -Minute 0 -Second 0
        } else {
            $next = (Get-Date -Year $local.Year -Month $local.Month -Day $local.Day -Hour 5 -Minute 0 -Second 0).AddDays(1)
        }
        while ($next.DayOfWeek -eq [DayOfWeek]::Saturday -or $next.DayOfWeek -eq [DayOfWeek]::Sunday) {
            $next = $next.AddDays(1)
        }
        $span = $next - $local
        $result.Tag = 'OFF-PEAK'
    }

    $h = [int][math]::Floor($span.TotalHours)
    $m = $span.Minutes
    $result.TimeLeft = if ($h -gt 0) { "${h}h ${m}m" } else { "${m}m" }

    try {
        @{ validUntil = ($now + 60); tag = $result.Tag; timeLeft = $result.TimeLeft } |
            ConvertTo-Json | Out-File -FilePath $cache -Encoding UTF8 -Force
    } catch {}
    return $result
}

# --- Gather state ---
$cwd = $payload.workspace.current_dir

$totalSize     = $payload.context_window.context_window_size
$usage         = $payload.context_window.current_usage
$currentTokens = if ($usage) {
    [int]$usage.input_tokens + [int]$usage.cache_creation_input_tokens + [int]$usage.cache_read_input_tokens
} else { 0 }
$ctxPct      = if ($totalSize -gt 0) { [math]::Round(($currentTokens / $totalSize) * 100) } else { 0 }
$ctxColor    = Get-CtxColor $ctxPct
$ctxBar      = New-Bar $ctxPct 20 $ctxColor
$tokensLabel = if ($currentTokens -ge 1000) { "$([math]::Round($currentTokens / 1000))K" } else { "$currentTokens" }

$rate5H = $null; $rate7D = $null
if ($payload.rate_limits) {
    if ($null -ne $payload.rate_limits.five_hour.used_percentage) { $rate5H = [int]$payload.rate_limits.five_hour.used_percentage }
    if ($null -ne $payload.rate_limits.seven_day.used_percentage) { $rate7D = [int]$payload.rate_limits.seven_day.used_percentage }
}

$projectName  = (Split-Path -Leaf $cwd).ToUpper()
$peak         = Get-PeakCountdown
$peakTag      = $peak.Tag
$peakTimeLeft = $peak.TimeLeft
$peakColor    = if ($peakTag -eq 'PEAK') { $crimsonC } else { $sageC }

# Model — hide when on the default (pattern set via env var or fallback).
$defaultPattern = if ($env:CLAUDE_STATUSLINE_DEFAULT_MODEL) { $env:CLAUDE_STATUSLINE_DEFAULT_MODEL } else { 'Opus 4\.7' }
$modelName      = $payload.model.display_name
$showModel      = $modelName -and ($modelName -notmatch $defaultPattern)

$terseActive = $payload.output_style.name -eq 'plain-terse'

# --- Compose rows ---
$ctxRow = "  $(Format-Label 'CTX')   ${ctxBar}   $(Format-Pct $ctxPct $ctxColor)   ${hairlineC}${DOT}${reset}   ${ivoryC}${tokensLabel}${reset}"

# Rates on a single row, side-by-side, 10-cell bars.
$rateSegments = @()
if ($null -ne $rate5H) {
    $c = Get-RateColor $rate5H
    $rateSegments += "$(Format-Label '5H')   $(New-Bar $rate5H 10 $c)   $(Format-Pct $rate5H $c)"
}
if ($null -ne $rate7D) {
    $c = Get-RateColor $rate7D
    $rateSegments += "$(Format-Label '7D')   $(New-Bar $rate7D 10 $c)   $(Format-Pct $rate7D $c)"
}
$rateRow = if ($rateSegments.Count -gt 0) { "  " + ($rateSegments -join "     ") } else { $null }

$idParts = @("${ivoryC}${projectName}${reset}")
if ($peakTag) {
    $idParts += "${peakColor}${peakTag}${reset} ${hairlineC}${ARROW}${reset} ${ivoryC}${peakTimeLeft}${reset}"
}
if ($showModel) {
    $idParts += "${modelC}${modelName}${reset}"
}
if ($terseActive) {
    $idParts += "$(Format-Label 'TERSE')"
}
$idSep = "   ${hairlineC}${DOT}${reset}   "
$idRow = "  " + ($idParts -join $idSep)

# --- Output with breathing room ---
# A single space on "blank" lines defeats the renderer's empty-line stripper
# while still looking blank to the eye.
Write-Output ' '
Write-Output $ctxRow
Write-Output ' '
if ($rateRow) {
    Write-Output $rateRow
    Write-Output ' '
}
Write-Output $idRow
