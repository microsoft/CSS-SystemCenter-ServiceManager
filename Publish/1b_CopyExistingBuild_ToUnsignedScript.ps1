Set-PSDebug -Strict # from now on, all variables must be explicitly declared before they are used  
$Error.Clear();
Set-Location $PSScriptRoot 

$sourcePath = "..\LocalDebug\SCSM-Diagnostic-Tool.ps1"
$targetPath = "..\LocalDebug\UnsignedScript\SCSM-Diagnostic-Tool.ps1"

New-Item -ItemType Directory -Force -Path ( Split-Path -Path $targetPath -Parent ) | Out-Null
Write-Host "Prepared folder: " -NoNewline
Write-Host "$targetPath" -ForegroundColor Yellow

Write-Host " "
$copyAction = Copy-Item -Path $sourcePath -Destination $targetPath -Confirm:(Test-Path -Path $targetPath) -PassThru
if ($copyAction -ne $null) {
    Write-Host "Copied script."
}
else {
    Write-Host "NOT copied script."    
}

Read-Host " "
