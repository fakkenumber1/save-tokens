# Install Commit Mono Nerd Font for the current user (no admin required).
# Downloads the latest CommitMono.zip from the Nerd Fonts release, copies .ttf files
# into %LOCALAPPDATA%\Microsoft\Windows\Fonts, and registers each face under HKCU.

$ErrorActionPreference = 'Stop'

$zipUrl   = 'https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CommitMono.zip'
$tempDir  = Join-Path $env:TEMP "commit-mono-nf-install"
$zipPath  = Join-Path $tempDir "CommitMono.zip"
$fontDest = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Fonts"
$regPath  = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"

Write-Host "Installing Commit Mono Nerd Font to user scope..." -ForegroundColor Cyan

if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
New-Item -ItemType Directory -Path $tempDir  | Out-Null
New-Item -ItemType Directory -Path $fontDest -Force | Out-Null
if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }

Write-Host "  Downloading $zipUrl ..."
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing

Write-Host "  Extracting ..."
Expand-Archive -Path $zipPath -DestinationPath $tempDir -Force

# Prefer the "NerdFontMono" variant - strict monospace, correct column widths in terminals.
$allFaces = Get-ChildItem $tempDir -Recurse -Include '*.ttf','*.otf'
$candidates = $allFaces | Where-Object { $_.Name -match 'NerdFontMono' }
if (-not $candidates) { $candidates = $allFaces | Where-Object { $_.Name -notmatch 'Propo' } }
if (-not $candidates) { $candidates = $allFaces }

Add-Type -AssemblyName System.Drawing

$installed = 0
foreach ($ttf in $candidates) {
    $destPath = Join-Path $fontDest $ttf.Name
    Copy-Item $ttf.FullName $destPath -Force

    $style = if ($ttf.Name -match '(?i)bold.*italic') { ' Bold Italic' }
             elseif ($ttf.Name -match '(?i)bold')      { ' Bold' }
             elseif ($ttf.Name -match '(?i)italic')    { ' Italic' }
             else                                       { '' }
    $type = if ($ttf.Extension -ieq '.otf') { 'OpenType' } else { 'TrueType' }

    $pfc = New-Object System.Drawing.Text.PrivateFontCollection
    try {
        $pfc.AddFontFile($ttf.FullName)
        $regName = "$($pfc.Families[0].Name)$style ($type)"
    } catch {
        $regName = "$($ttf.BaseName) ($type)"
    } finally {
        $pfc.Dispose()
    }

    New-ItemProperty -Path $regPath -Name $regName -Value $destPath -PropertyType String -Force | Out-Null
    $installed++
}

Write-Host ""
Write-Host "Installed $installed font files to $fontDest" -ForegroundColor Green
Write-Host ""
Write-Host "Next step - tell Windows Terminal to use it:" -ForegroundColor Yellow
Write-Host "  Settings -> Defaults (or your profile) -> Appearance -> Font face"
Write-Host "  Pick:  CommitMono Nerd Font Mono"
Write-Host ""
Write-Host "You may need to close and reopen Windows Terminal for new fonts to appear." -ForegroundColor DarkGray
