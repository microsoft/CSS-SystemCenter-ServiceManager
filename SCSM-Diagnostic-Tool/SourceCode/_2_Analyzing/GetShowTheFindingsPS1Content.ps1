function GetShowTheFindingsPS1Content() {
$findingsPS1_Content = @"
<#

--------------------------------------------
Please execute with right/click + 'Run with PowerShell'
--------------------------------------------

#>

"@
$findingsPS1_Content += @'
Remove-Variable * -ErrorAction SilentlyContinue -Exclude PSDefaultParameterValues
Remove-Module *;
$Error.Clear();
Get-job | Remove-Job -Force
$host.privatedata.ErrorForegroundColor ="DarkGray"  # For accessibility
$global:ProgressPreference = 'SilentlyContinue'
'@
$findingsPS1_Content += '
$code = {
'
$findingsPS1_Content += GetFunctionDeclaration LogStatInfo
$findingsPS1_Content += GetFunctionDeclaration InvokeRestMethod_WithProxy
$findingsPS1_Content += GetFunctionDeclaration GetProxy
$findingsPS1_Content += GetFunctionDeclaration GetHashOfString
$findingsPS1_Content += GetFunctionDeclaration GetPossibleDateTimeStringFormats
$findingsPS1_Content += GetFunctionDeclaration GetPossibleDateTimeStringFormatsWithTz
$findingsPS1_Content += GetFunctionDeclaration GetPossibleDateTimeStringFormatsWithoutTz
$findingsPS1_Content += GetFunctionDeclaration GetDateTimeStringFormatFromDateTimeString
$findingsPS1_Content += GetFunctionDeclaration ConvertDateTimeStringToDateTime
$findingsPS1_Content += GetFunctionDeclaration ConvertDateTimeStringToDateTime_Utc
$findingsPS1_Content += GetFunctionDeclaration AddTzToDateTimeString
$findingsPS1_Content += GetFunctionDeclaration Get-UserFriendlyTimeSpane
$findingsPS1_Content += @'

if ($input.MoveNext()) { $inputs = $input.Current } else { return }
foreach($v in $inputs.Keys) {
        New-Variable -Name $v -Value $inputs[$v]
}
Set-Location $workingFolder
$statInfoXmlString = Get-Content -Path ".\$analyzer_FolderName\StatInfo.xml" -Encoding UTF8
$statInfoXml = New-Object xml
$statInfoXml.LoadXml($statInfoXmlString)
LogStatInfo $statInfoXml "Open"
}

'@

$findingsPS1_Content += GetFunctionDeclaration GetProxy
$findingsPS1_Content += GetFunctionDeclaration InvokeWebRequest_WithProxy
$findingsPS1_Content += GetFunctionDeclaration IsInternetAvailable

$findingsPS1_Content += @"

if ( !(IsInternetAvailable) )
{
    Read-Host "The Findings report contains links to resources on the internet. Therefore, please unzip the whole ZIP file on a machine that is connected to the INTERNET and then try again."
    Exit
}

`$analyzer_FolderName  = "$analyzer_FolderName"
`$findingsHtml_FileName = "$findingsHtml_FileName"
`$findingsTxt_FileName = "$findingsTxt_FileName"

"@
$findingsPS1_Content += @'
Set-Location $PSScriptRoot
if (Test-Path ".\$analyzer_FolderName\StatInfo.xml") {
    $vars = @{
        "workingFolder"  = $PSScriptRoot
        "analyzer_FolderName"  = $analyzer_FolderName
    }
    Start-Job -ScriptBlock $code -InputObject $vars | Out-Null
}
else {
    Read-Host "Please unzip the whole ZIP file and then try again."
    Exit
}

if (!(Test-Path ".\$analyzer_FolderName\$findingsHtml_FileName")) {
    $encodedValue = Get-Content -Path .\$analyzer_FolderName\$findingsTxt_FileName -Encoding UTF8
    $decodedBytes = [System.Convert]::FromBase64String($encodedValue)
    $decodedText  = [System.Text.Encoding]::Utf8.GetString($decodedBytes)
    Set-Content -Path .\$analyzer_FolderName\$findingsHtml_FileName -Value $decodedText -Encoding UTF8
}
Start-Process .\$analyzer_FolderName\$findingsHtml_FileName

Write-Host "Please wait, this will close in max 20 seconds." -NoNewline
foreach($psJob in Get-Job) {
    while ( $psJob.State -eq [System.Management.Automation.JobState]::Running ) {
        Start-Sleep -Milliseconds 1000
		Write-Host "." -NoNewline
    }
}
cls
'@

$findingsPS1_Content
}