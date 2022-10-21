$targetPath = "..\LocalDebug\SignedScript\SCSM-Diagnostic-Tool.ps1"
New-Item -ItemType Directory -Force -Path ( Split-Path -Path $targetPath -Parent ) | Out-Null
Write-Host "Prepared folder: " -NoNewline
Write-Host "$targetPath" -ForegroundColor Yellow

# code here if signing can be started programmatically. Otherwise, start it manually...


# File to be signed is at:     "..\LocalDebug\UnsignedScript\SCSM-Diagnostic-Tool.ps1"

# Signed File should be saved at:     "..\LocalDebug\SignedScript\SCSM-Diagnostic-Tool.ps1"

Write-Host "Now waiting for signing to complete..."
Read-Host " "