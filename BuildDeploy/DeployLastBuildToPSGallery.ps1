#region resetting the PS environment
Set-StrictMode -Version 1.0
Remove-Variable * -ErrorAction SilentlyContinue -Exclude PSDefaultParameterValues; 
Remove-Module *; 
$error.Clear(); 
Get-job | Remove-Job
$host.privatedata.ErrorForegroundColor ="DarkGray"  # For accessibility
#endregion
#region params
$NuGetApiKey = 'intenionally wrong' #'oy2j6r344tssyj772lwaf3dmxprunhfence7ukl4rtbzzm'
<# API key for testing in my personal hotmail.com account
Name: TestKeyForScsmDiagnosticTool
Expires in a year => Jun 6, 2023
Package owner: kubhus
Glob pattern: *
#>
$sourceScriptFolderName = 'LastBuild'
$sourceScriptFileName = 'SCSM-Diagnostic-Tool.ps1'
$targetReleaseFolderName = 'LastBuild'
$targetScriptFileName = 'SCSM-Diagnostic-Tool.ps1'
$invalidDeployScriptFileName = "_InvalidDeploy_$sourceScriptFileName"
$Output_DeployFolderName = "Output_Deploy"
$transcriptFileName = "$Output_DeployFolderName\Deploy_Transcript.txt"
#endregion
#region Starting Transcripting
$transcriptFilePath = Join-Path -Path $PSScriptRoot -ChildPath $transcriptFileName
Start-Transcript -Path $transcriptFilePath | Out-Null
#endregion
try {
    #region init 
    Set-Location $PSScriptRoot 
    $parentPath = Split-Path -Path (Get-Location) -Parent
    $sourceFilePath = Join-Path -Path $parentPath -ChildPath $sourceScriptFolderName | Join-Path -ChildPath $sourceScriptFileName
    $successFilePath = Join-Path -Path $parentPath -ChildPath $targetReleaseFolderName | Join-Path -ChildPath $targetScriptFileName
    
    $currentVersionStr = (Test-ScriptFileInfo -Path $successFilePath).Version
    Write-Host "Deploy started for Version $currentVersionStr"
    Write-Host "--------------------------------"
    #endregion
    #region Publish to PSGallery
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Publish-Script -Path $successFilePath -NuGetApiKey $NuGetApiKey
    #endregion
    #region Verification of Publish
    $publishResult = Find-Script -Name $targetScriptFileName    

    if ( $currentVersionStr -eq $($publishResult.Version)  ) 
    {
        Write-Host "Publish SUCCEEDED for version $currentVersionStr of $successFilePath" -ForegroundColor Yellow
    }
    else {
        #this should never happen
        throw "Publish-Script has completed *BUT* the published script's version $($publishResult.Version) is not identical with version $currentVersionStr in $successFilePath"
    }
    #endregion
} 
catch {    
    $_ | fl     # to re-throw
    Write-Error "Deploy FAILED for Version $currentVersionStr. Check $Output_DeployFolderName folder."
}
finally {
    Stop-Transcript | out-null
    Read-Host " "
}

