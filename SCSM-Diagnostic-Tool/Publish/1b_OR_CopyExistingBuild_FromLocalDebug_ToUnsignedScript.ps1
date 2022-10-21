Set-PSDebug -Strict # from now on, all variables must be explicitly declared before they are used  
$Error.Clear();
Set-Location $PSScriptRoot 

$sourcePath = "..\LocalDebug\SCSM-Diagnostic-Tool.ps1"
$targetPath = ".\UnsignedScript\SCSM-Diagnostic-Tool.ps1"

Copy-Item -Path $sourcePath -Destination .\UnsignedScript\SCSM-Diagnostic-Tool.ps1 -Confirm:(Test-Path -Path $targetPath)

Read-Host " "
