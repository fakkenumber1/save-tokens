# /usage — token totals across the rolling 5-hour and 7-day Pro/Max rate-limit windows,
# plus today for context. Per-model breakdown with re-read share so you can spot when
# /compact is overdue.

. "$PSScriptRoot\pricing.ps1"

$projectsDir = Join-Path $env:USERPROFILE '.claude\projects'
$now      = Get-Date
$today    = $now.Date
$cutoff5h = $now.AddHours(-5)
$cutoff7d = $now.AddDays(-7)

$windows = @{
    '5h'    = @{}
    '7d'    = @{}
    'today' = @{}
}

function Add-Usage {
    param($Bucket, $Model, $Usage)
    if (-not $Bucket.ContainsKey($Model)) {
        $Bucket[$Model] = [ordered]@{
            InputNew    = 0
            Output      = 0
            CacheRead   = 0
            CacheCreate = 0
        }
    }
    $Bucket[$Model].InputNew    += [int]$Usage.input_tokens
    $Bucket[$Model].Output      += [int]$Usage.output_tokens
    $Bucket[$Model].CacheRead   += [int]$Usage.cache_read_input_tokens
    $Bucket[$Model].CacheCreate += [int]$Usage.cache_creation_input_tokens
}

Get-ChildItem -Path $projectsDir -Filter *.jsonl -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -ge $cutoff7d } |
    ForEach-Object {
        try { $content = Get-Content $_.FullName -ErrorAction Stop } catch { return }
        foreach ($line in $content) {
            if ([string]::IsNullOrWhiteSpace($line)) { continue }
            try { $obj = $line | ConvertFrom-Json -ErrorAction Stop } catch { continue }
            if ($obj.type -ne 'assistant') { continue }
            if (-not $obj.timestamp) { continue }
            try { $ts = [datetime]::Parse($obj.timestamp) } catch { continue }
            $model = $obj.message.model
            $usage = $obj.message.usage
            if (-not $model -or -not $usage) { continue }

            if ($ts -ge $cutoff5h)   { Add-Usage $windows['5h']    $model $usage }
            if ($ts -ge $cutoff7d)   { Add-Usage $windows['7d']    $model $usage }
            if ($ts.Date -eq $today) { Add-Usage $windows['today'] $model $usage }
        }
    }

function Write-Window {
    param([string]$Title, [string]$Subtitle, $Bucket)

    Write-Output ""
    Write-Output "  $Title"
    Write-Output "    $Subtitle"
    Write-Output ""

    if ($Bucket.Count -eq 0) {
        Write-Output "    (no assistant messages in this window)"
        return
    }

    $windowCost  = 0.0
    $windowTotal = 0
    foreach ($model in ($Bucket.Keys | Sort-Object)) {
        $t = $Bucket[$model]
        $total = $t.InputNew + $t.CacheRead + $t.CacheCreate + $t.Output
        $windowTotal += $total

        $aggregateUsage = @{
            input_tokens                = $t.InputNew
            output_tokens               = $t.Output
            cache_read_input_tokens     = $t.CacheRead
            cache_creation_input_tokens = $t.CacheCreate
        }
        $cost = Get-MessageCost $model $aggregateUsage
        $windowCost += $cost

        $reReadPct = if ($total -gt 0) { [math]::Round(($t.CacheRead / $total) * 100) } else { 0 }
        Write-Output ("    {0,-46}  {1,12:N0} tok   re-read {2,3}%" -f $model, $total, $reReadPct)
    }
    Write-Output ("    {0,-46}  {1,12:N0} tok   est. `$ {2:N2}" -f 'TOTAL', $windowTotal, $windowCost)
}

Write-Output ""
Write-Output "  Claude Code usage  $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
Write-Output ""
Write-Output "  The 5h and 7d windows are the rolling buckets that drive Pro/Max rate-limit"
Write-Output "  warnings. 'today' is shown for reference only."

Write-Window 'CURRENT 5-HOUR WINDOW' "(messages since $($cutoff5h.ToString('yyyy-MM-dd HH:mm')))" $windows['5h']
Write-Window 'CURRENT 7-DAY WINDOW'  "(messages since $($cutoff7d.ToString('yyyy-MM-dd HH:mm')))" $windows['7d']
Write-Window 'TODAY'                  "(midnight to now)"                                          $windows['today']

Write-Output ""
Write-Output "  re-read % is the share of tokens spent re-reading old conversation context."
Write-Output "  High re-read % in long sessions = run /compact to summarize and drop raw history."
Write-Output "  Pricing approximated from published per-million rates; actual billing at console.anthropic.com."
Write-Output ""
