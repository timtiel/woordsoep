# fix_python_tls.ps1 - laat Python de Windows-certificaatopslag vertrouwen.
#
# Nodig op machines waar TLS-inspectie (antivirus/proxy) de eigen
# CA-bundel van Python blokkeert. Symptomen: SSL-fouten in aqt/pip terwijl
# PowerShell/curl download.qt.io gewoon kunnen bereiken.
#
# Gebruik (dot-source, met de punt ervoor, zodat de omgevingsvariabelen in
# je terminal-sessie blijven staan):
#
#   . .\tools\fix_python_tls.ps1
#
# Daarna werkt bijv.:
#   py tools\run_aqt.py install-qt windows desktop 6.6.3 win64_msvc2019_64 --archives qtbase --outputdir .qt

$out = Join-Path $env:TEMP "win-ca-bundle.pem"
$sb = New-Object System.Text.StringBuilder

foreach ($store in @("Cert:\LocalMachine\Root", "Cert:\CurrentUser\Root", "Cert:\LocalMachine\CA", "Cert:\CurrentUser\CA")) {
    Get-ChildItem $store -ErrorAction SilentlyContinue | ForEach-Object {
        $b64 = [Convert]::ToBase64String($_.RawData)
        [void]$sb.AppendLine("# " + $_.Subject)
        [void]$sb.AppendLine("-----BEGIN CERTIFICATE-----")
        for ($i = 0; $i -lt $b64.Length; $i += 64) {
            [void]$sb.AppendLine($b64.Substring($i, [Math]::Min(64, $b64.Length - $i)))
        }
        [void]$sb.AppendLine("-----END CERTIFICATE-----")
    }
}

Set-Content -Path $out -Value $sb.ToString() -Encoding ASCII

$env:REQUESTS_CA_BUNDLE = $out
$env:SSL_CERT_FILE = $out

Write-Host "CA-bundel geschreven naar $out en ingesteld voor deze sessie."
