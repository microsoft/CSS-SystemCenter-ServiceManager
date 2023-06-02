function Collect() {

#region Collector Initial tasks
$resultPrefix = "SCSM_DIAG"
$collectorVersion = GetToolVersion  

$resultFolderPath = Split-Path $scriptFilePath
$resultDateTime = (Get-Date).ToString("yyyy-MM-dd__HH.mm.ss.fff")
$collector_FolderName = "Collector"    
$resultFolder = New-Item -Force -ItemType Directory -Path $resultFolderPath -Name "$($resultPrefix)_$resultDateTime\$collector_FolderName"
Start-Transcript -Path "$resultFolder\Transcript_$resultDateTime.txt" -NoClobber | Out-Null

Write-Host "This script does *NOT* make any change in your SCSM environment. It is completely read-only."
Write-Host ""
Write-Host "SCSM Diagnostic Tool started at $resultDateTime. (local time)"
Write-Host "Please wait for completion. This can take a few minutes..." -ForegroundColor Yellow
Write-Host "(Please ignore any Warning and Errors)"

CopyFileToTargetFolder $scriptFilePath
AppendOutputToFileInTargetFolder ( $collectorVersion ) CollectorVersion.txt
AppendOutputToFileInTargetFolder  '"Duration","EndTime","StartTime","ScriptBlockText"'  Collector-MeasuredScriptBlocks.csv

Ram GetInternetAvailability

$PSDefaultParameterValues['out-file:width'] = 2000
$FormatEnumerationLimit = -1 #prevents truncation of column values if no fit
$ProgressPreference = 'SilentlyContinue'
$preFix_SaveTo = "SaveTo_"  # used as a prefix in psJob.Name to indicate that Job Output should be saved to a file name
#endregion

#region Start Collecting
Collect_Info
#endregion

#region Waiting for background tasks to complete
foreach($psJob in Get-Job) {
    while ( $psJob.State -eq [System.Management.Automation.JobState]::Running ) {
        Start-Sleep -Seconds 1 
    }
    if ( $psJob.Name.StartsWith($preFix_SaveTo) ) {
        $saveToFileName = $psJob.Name.Replace($preFix_SaveTo,"")

        $vNonSuccess=""; $vSuccess="";
        Receive-Job -Job $psJob -OutVariable vSuccess -ErrorVariable vNonSuccess | Out-Null
        AppendOutputToFileInTargetFolder ($vSuccess + "`n" + $vNonSuccess) $saveToFileName
    }
}
#endregion

#region Collector Final tasks
Write-Host ""
$completionDateTime = (Get-Date).ToString("yyyy-MM-dd__HH.mm.ss.fff")  

$currentBackgroundColor = $host.UI.RawUI.BackgroundColor.ToString()
if ($currentBackgroundColor -eq "-1") { $currentBackgroundColor = "DarkBlue" }
Write-Host "Collection completed at $completionDateTime. (local time)" -ForegroundColor $currentBackgroundColor #not to see in PS window but still in the transcript file

$script:SQLResultSetCounter = $null
Stop-Transcript | out-null
#$ProgressPreference = 'Continue'

$zipFileTargetFolder = Split-Path $scriptFilePath
$resultingZipFile_FullPath = (Join-Path -Path $zipFileTargetFolder -ChildPath "$($resultPrefix)_$($script:RoleFoundAbbr)_$($resultDateTime).zip")

$currentFolderName = "$($resultPrefix)_$($resultDateTime)"
AppendOutputToFileInTargetFolder ( (CalculateCollectorTimings $currentFolderName) | ConvertTo-Csv -NoTypeInformation ) CollectorTimings.csv
$newFolderName = "$($resultPrefix)_$($script:RoleFoundAbbr)_$($resultDateTime)"
Rename-Item -Path $currentFolderName -NewName $newFolderName
#endregion

return $resultingZipFile_FullPath # actually, there's no real zip file (anymore), but Analyzer will handle this accordingly
}
