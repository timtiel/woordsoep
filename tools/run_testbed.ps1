# Start de app in een Qt-venster op de pc -- testen zonder tablet.
# Gebruik:  powershell -ExecutionPolicy Bypass -File tools/run_testbed.ps1 [-Qml <pad naar qml.exe>]
param(
    [string]$Qml = ""
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot

if (-not $Qml -or -not (Test-Path $Qml)) {
    $found = Get-ChildItem -Path (Join-Path $root ".qt") -Recurse -Filter "qml.exe" -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($found) { $Qml = $found.FullName }
}

if (-not $Qml -or -not (Test-Path $Qml)) {
    Write-Host ""
    Write-Host "qml.exe is niet gevonden." -ForegroundColor Red
    Write-Host "Installeer eenmalig Qt (qtbase + qtdeclarative) en probeer opnieuw:"
    Write-Host "  py -m pip install aqtinstall truststore"
    Write-Host "  py tools\run_aqt.py install-qt windows desktop 6.6.3 win64_msvc2019_64 --archives qtbase qtdeclarative --outputdir .qt"
    Write-Host "  powershell -ExecutionPolicy Bypass -File tools\run_testbed.ps1"
    exit 1
}

$imports = Join-Path $root "tools\testbed\imports"
$wrapper = Join-Path $root "tools\testbed\RunTestbed.qml"

Write-Host "qml: $Qml"
Write-Host "App: $wrapper"
Write-Host ""
Write-Host "Sluiten kan met de Sluiten-knop in de app, Escape, of het kruisje van het venster."
& $Qml -I $imports $wrapper
