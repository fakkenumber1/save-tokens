# Shared pricing table — single source of truth for per-million token rates.
# Update here when Anthropic changes published rates.

$Pricing = @(
    @{ Match = '*opus*';   In = 15.0; Out = 75.0; CR = 1.50; CC = 18.75 },
    @{ Match = '*sonnet*'; In = 3.0;  Out = 15.0; CR = 0.30; CC = 3.75 },
    @{ Match = '*haiku*';  In = 1.0;  Out = 5.0;  CR = 0.10; CC = 1.25 }
)

function Get-ModelPrice {
    param($ModelId)
    foreach ($p in $Pricing) {
        if ($ModelId -like $p.Match) { return $p }
    }
    return $null
}

function Get-MessageCost {
    param($Model, $Usage)
    $p = Get-ModelPrice $Model
    if (-not $p) { return 0.0 }
    $cost  = ([int]$Usage.input_tokens                 / 1000000.0) * $p.In
    $cost += ([int]$Usage.output_tokens                / 1000000.0) * $p.Out
    $cost += ([int]$Usage.cache_read_input_tokens      / 1000000.0) * $p.CR
    $cost += ([int]$Usage.cache_creation_input_tokens  / 1000000.0) * $p.CC
    return $cost
}
