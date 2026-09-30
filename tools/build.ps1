# Bouwt dist/woordspel (manifest.json, icon.png, resources.rcc) uit app/.
# Gebruik:  powershell -ExecutionPolicy Bypass -File tools/build.ps1 [-Rcc <pad naar rcc.exe>]
param(
    [string]$Rcc = ""
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot

if (-not $Rcc -or -not (Test-Path $Rcc)) {
    $found = Get-ChildItem -Path (Join-Path $root ".qt") -Recurse -Filter "rcc.exe" -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($found) { $Rcc = $found.FullName }
}

if (-not $Rcc -or -not (Test-Path $Rcc)) {
    Write-Host ""
    Write-Host "rcc.exe is niet gevonden." -ForegroundColor Red
    Write-Host "Installeer eenmalig Qt (alleen qtbase) en probeer opnieuw:"
    Write-Host "  py -m pip install aqtinstall"
    Write-Host "  py -m aqt install-qt windows desktop 6.6.3 win64_msvc2019_64 --archives qtbase --outputdir .qt"
    Write-Host "  powershell -ExecutionPolicy Bypass -File tools/build.ps1"
    exit 1
}

Write-Host "rcc: $Rcc"

$appDir = Join-Path $root "app"
$distDir = Join-Path $root "dist\woordspel"

if (Test-Path $distDir) { Remove-Item -Recurse -Force $distDir }
New-Item -ItemType Directory -Path $distDir | Out-Null

Copy-Item (Join-Path $appDir "manifest.json") $distDir

$icon = Join-Path $appDir "icon.png"
if (-not (Test-Path $icon)) {
    Write-Host "Icoon ontbreekt - genereren met tools/make_icon.py ..."
    Push-Location $root
    try {
        & py tools/make_icon.py
    } catch {
        & python tools/make_icon.py
    }
    Pop-Location
}
Copy-Item $icon $distDir

Push-Location $appDir
& $Rcc --binary -o (Join-Path $distDir "resources.rcc") application.qrc
Pop-Location

# Handige zip voor installatie via de terminal of voor het delen van de app.
# (Opruimen van de oude zip-naam na de hernoeming naar Woordsoep.)
$legacyZip = Join-Path $root "dist\Woordspel.zip"
if (Test-Path $legacyZip) { Remove-Item $legacyZip }
$zip = Join-Path $root "dist\Woordsoep.zip"
if (Test-Path $zip) { Remove-Item $zip }
Compress-Archive -Path $distDir -DestinationPath $zip

Write-Host ""
Write-Host "Klaar! Inhoud van dist\woordspel:" -ForegroundColor Green
Get-ChildItem $distDir | Format-Table Name, Length
Write-Host "Zip: $zip"
