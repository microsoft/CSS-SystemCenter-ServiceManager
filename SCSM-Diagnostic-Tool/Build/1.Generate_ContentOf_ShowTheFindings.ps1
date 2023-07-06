Set-PSDebug -Strict # from now on, all variables must be explicitly declared before they are used  
$Error.Clear();
Set-Location $PSScriptRoot

$sourceStartingScriptFolderName = 'SourceCode'
$targetBuildFolderName = 'LocalDebug'
$parentPath = Split-Path -Path (Get-Location) -Parent
$sourceStartingFolderPath = Join-Path -Path $parentPath -ChildPath $sourceStartingScriptFolderName 

. ( Join-Path -Path $sourceStartingFolderPath -ChildPath "_1_Collecting\Helper_Functions.ps1" )
. ( Join-Path -Path $sourceStartingFolderPath -ChildPath "_2_Analyzing\GetShowTheFindingsPS1Content.ps1" )

$analyzer_FolderName   = "Analyzer"
$findingsHtml_FileName = "Findings.html"
$findingsTxt_FileName  = "Findings.txt"
$findingsPS1Content    = GetShowTheFindingsPS1Content

Set-Content -Path "..\$targetBuildFolderName\GetShowTheFindingsPS1Content.ps1" -Value $findingsPS1Content
