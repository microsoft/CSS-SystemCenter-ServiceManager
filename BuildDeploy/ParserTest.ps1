[System.Management.Automation.Language.Token[]]$tokens = $null
[System.Management.Automation.Language.ParseError[]]$parseErrors = $null
cls
$scriptFileFullPath = "C:\Users\khusmeno\Desktop\SCSM-Diagnostic-Tool\LastBuild\SCSM-Diagnostic-Tool.ps1"
$p = [System.Management.Automation.Language.Parser]::ParseFile($scriptFileFullPath,[ref]$tokens,[ref]$parseErrors) 

#$p.Extent
#$tokens|ft -auto

if($parseErrors.Count -gt 0){
    Write-Warning "Errors found. $parseErrors"
}
else {
    Write-Host "OK"
}

