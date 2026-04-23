# Iosevka Nerd Font installer — user-scope, no admin required.
# Downloads the latest Iosevka Nerd Font zip from the nerd-fonts GitHub release,
# extracts only the four Mono variants we need, copies them into the user's
# private Fonts folder, and registers each in HKCU so apps pick them up without
# a reboot or a sign-out. Idempotent: safe to re-run.

$ErrorActionPreference = 'Stop'

$fontFaces = @(
    @{ File = 'IosevkaNerdFontMono-Regular.ttf';    Display = 'Iosevka Nerd Font Mono Regular (TrueType)' }
    @{ File = 'IosevkaNerdFontMono-Bold.ttf';       Display = 'Iosevka Nerd Font Mono Bold (TrueType)' }
    @{ File = 'IosevkaNerdFontMono-Italic.ttf';     Display = 'Iosevka Nerd Font Mono Italic (TrueType)' }
    @{ File = 'IosevkaNerdFontMono-BoldItalic.ttf'; Display = 'Iosevka Nerd Font Mono Bold Italic (TrueType)' }
)

$zipUrl   = 'https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Iosevka.zip'
$zipPath  = Join-Path $env:TEMP 'Iosevka-NF.zip'
$stagDir  = Join-Path $env:TEMP 'Iosevka-NF-extract'
$destDir  = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
$regPath  = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'

# --- Ensure dirs exist ---
New-Item -ItemType Directory -Force -Path $destDir | Out-Null
if (Test-Path $stagDir) { Remove-Item $stagDir -Recurse -Force }
New-Item -ItemType Directory -Force -Path $stagDir | Out-Null
if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }

# --- Download ---
Write-Host "Downloading Iosevka Nerd Font..." -ForegroundColor Cyan
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing

# --- Extract only what we need ---
Write-Host "Extracting Mono variants..." -ForegroundColor Cyan
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
try {
    foreach ($face in $fontFaces) {
        $entry = $zip.Entries | Where-Object { $_.Name -eq $face.File } | Select-Object -First 1
        if (-not $entry) {
            Write-Host "  ! Not found in zip: $($face.File)" -ForegroundColor Yellow
            continue
        }
        $outPath = Join-Path $stagDir $face.File
        [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $outPath, $true)
    }
} finally {
    $zip.Dispose()
}

# --- Install + register each face ---
$installed = @()
foreach ($face in $fontFaces) {
    $src = Join-Path $stagDir $face.File
    if (-not (Test-Path $src)) { continue }
    $dst = Join-Path $destDir $face.File
    Copy-Item -Path $src -Destination $dst -Force
    # Registry: value name = display name with TrueType suffix; value data = full path.
    Set-ItemProperty -Path $regPath -Name $face.Display -Value $dst -Type String -Force
    $installed += $face.Display
}

# --- Cleanup ---
Remove-Item $stagDir -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item $zipPath -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "Installed:" -ForegroundColor Green
$installed | ForEach-Object { Write-Host "  - $_" }
Write-Host ""
Write-Host "Windows Terminal font face name to use:" -ForegroundColor Cyan
Write-Host "  Iosevka Nerd Font Mono"
Write-Host ""
Write-Host "Note: existing Windows Terminal windows cache the font list - close all windows and relaunch to see it."
