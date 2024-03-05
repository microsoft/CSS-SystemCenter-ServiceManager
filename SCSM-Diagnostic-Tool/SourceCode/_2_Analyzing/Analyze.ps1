function Analyze($resultingZipFile_FullPath) {

#region Preferences about Analyzer behavior

$displaySapCategories = $false #todo: get feedback if this should be $true
$resultingZipFileName_ShouldHaveNewTime = $false  
#$compressTheResults = $false #todo: get feedback if this should be $true
$compressTheResults = $true #todo: get feedback if this should be $false
$removeCollectorResultZipFile = $false   #todo: get feedback if this should be $true
$useProtocolHandler_OpenDefAppByFileExt = $true   #todo
#$openFindingsHtmlAtTheEnd = $true
$openFindingsHtmlAtTheEnd = $false
$openCollectorFolderAtTheEnd = $false #todo: get feedback if this should be $true

$findingsHtml_FileName = "Findings.html"
$findingsTxt_FileName = "Findings.txt"
$collector_FolderName = "Collector"
$analyzer_FolderName = "Analyzer"
$findingsPS1_FileName = "ShowTheFindings.ps1"
#endregion

#region initial tasks

#getting the result zip path of the Collector (even though the zip file does not exist!)
$collectorResultZipPath = $resultingZipFile_FullPath

$analyzerVersion = GetToolVersion

# For accessibility
$errorForegroundColor="DarkGray"
$errorBackgroundColor="Black"
$host.privatedata.ErrorForegroundColor = $errorForegroundColor  

#PS Preferences
$PSDefaultParameterValues['out-file:width'] = 2000
$FormatEnumerationLimit = -1 #prevents truncation of column values if no fit
$ProgressPreference = 'SilentlyContinue'

# setting vars to handle input file
$inputPrefix =  "SCSM_DIAG"
$collectorStartingText = "(Please ignore any Warning and Errors)"
$collectorEndingText = "Collection completed at "
$analyzerStartingText = "Now running the Rules..."
$analyzerEndingText = "SCSM Diagnostic Tool completed at "

#region setting if DEBUG
if ($debugmode) {
    $useProtocolHandler_OpenDefAppByFileExt = $true
    $openCollectorFolderAtTheEnd = $false
    $removeCollectorResultZipFile = $false
    $compressTheResults = $false
}
#endregion

$telemetry = GetEmptyTelemetryRow

#region Preparing folders
    $telemetry.AnalysisID = (Split-Path -Path $collectorResultZipPath -Leaf).Replace(".zip","")
                        
    $resultFolderPath = Split-Path -Path $collectorResultZipPath
    if ($resultingZipFileName_ShouldHaveNewTime) {
        $resultPrefix = "SCSM_ANALYSIS_"
    }
    else {
        $resultPrefix = ""
    }
    $resultFolderName = "$($resultPrefix)"

    if ($resultingZipFileName_ShouldHaveNewTime) {
        $resultFolderName += (Get-Date).ToString("yyyy-MM-dd__HH.mm.ss.fff")    
    }
    else {
        $resultFolderName += (Split-Path -Path $collectorResultZipPath -Leaf).Replace(".zip","")
    }

    #now starting the rules...
    $telemetry.Start_DateTimeUtc = (Get-Date).ToUniversalTime()  #todo: this was actually set in GetEmptyTelemetryRow

    $resultFolder = Join-Path -Path $resultFolderPath -ChildPath "$resultFolderName\$analyzer_FolderName" 

    Start-Transcript -Path "$resultFolder\Transcript.txt" -NoClobber | Out-Null
    $startingDateTime = (Get-Date).ToString("yyyy-MM-dd__HH.mm.ss.fff")  
    Write-Host ""
    AppendOutputToFileInTargetFolder ( Get-SmbClientConfiguration ) Get-SmbClientConfiguration.txt
    CopyFileToTargetFolder $scriptFilePath # -subFolderName $analyzer_FolderName

   AppendOutputToFileInTargetFolder  '"Duration","EndTime","StartTime","ScriptBlockText"'  Analyzer-MeasuredScriptBlocks.csv

    $inputFolder = Join-Path ($resultFolder) "..\$collector_FolderName"
#endregion    

$inputVersion = GetFirstLine ( GetFileContentInSourceFolder CollectorVersion.txt )
#$telemetry.Abort_Reason = 0 #todo

$currentBackgroundColor = $host.UI.RawUI.BackgroundColor.ToString()
if ($currentBackgroundColor -eq "-1") { $currentBackgroundColor = "DarkBlue" }
Write-Host $analyzerStartingText -ForegroundColor $currentBackgroundColor #not to see in PS window but still in the transcript file

#region checking registry for $useProtocolHandler_OpenDefAppByFileExt
$useProtocolHandler_OpenDefAppByFileExt = $false
$reg_OpenDefAppByFileExt_UrlProtocolExists = Get-Item -Path 'Registry::HKEY_CLASSES_ROOT\OpenDefAppByFileExt' -ErrorAction Ignore
if ($reg_OpenDefAppByFileExt_UrlProtocolExists) {
    $reg_OpenDefAppByFileExt_UrlProtocolExists = $reg_OpenDefAppByFileExt_UrlProtocolExists.GetValueNames().Contains("URL Protocol") 

    $reg_OpenDefAppByFileExt_commandValue = (Get-ItemProperty -Path 'Registry::HKEY_CLASSES_ROOT\OpenDefAppByFileExt\shell\open\command'  -ErrorAction Ignore ).'(default)'
    if ($reg_OpenDefAppByFileExt_commandValue) {
        $reg_OpenDefAppByFileExt_commandExists = ( $reg_OpenDefAppByFileExt_commandValue.StartsWith('cmd.exe /C ') -and $reg_OpenDefAppByFileExt_commandValue.Contains('OpenDefAppByFileExt.ps1') )
        $useProtocolHandler_OpenDefAppByFileExt = ($reg_OpenDefAppByFileExt_UrlProtocolExists -and $reg_OpenDefAppByFileExt_commandExists)
    }
}
#endregion

#region prepare Beginning part of $findingsHtml_FileName
$imgNowExpanded = "data:image/svg+xml;base64,PHN2ZyBhcmlhLWhpZGRlbj0idHJ1ZSIgZm9jdXNhYmxlPSJmYWxzZSIgZGF0YS1wcmVmaXg9ImZhcyIgZGF0YS1pY29uPSJjaGV2cm9uLXVwIiBjbGFzcz0ic3ZnLWlubGluZS0tZmEgZmEtY2hldnJvbi11cCBmYS13LTE0IiByb2xlPSJpbWciIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIgdmlld0JveD0iMCAwIDQ0OCA1MTIiPjxwYXRoIGZpbGw9ImN1cnJlbnRDb2xvciIgZD0iTTI0MC45NzEgMTMwLjUyNGwxOTQuMzQzIDE5NC4zNDNjOS4zNzMgOS4zNzMgOS4zNzMgMjQuNTY5IDAgMzMuOTQxbC0yMi42NjcgMjIuNjY3Yy05LjM1NyA5LjM1Ny0yNC41MjIgOS4zNzUtMzMuOTAxLjA0TDIyNCAyMjcuNDk1IDY5LjI1NSAzODEuNTE2Yy05LjM3OSA5LjMzNS0yNC41NDQgOS4zMTctMzMuOTAxLS4wNGwtMjIuNjY3LTIyLjY2N2MtOS4zNzMtOS4zNzMtOS4zNzMtMjQuNTY5IDAtMzMuOTQxTDIwNy4wMyAxMzAuNTI1YzkuMzcyLTkuMzczIDI0LjU2OC05LjM3MyAzMy45NDEtLjAwMXoiPjwvcGF0aD48L3N2Zz4="
$imgNowCollapsed = "data:image/svg+xml;base64,PHN2ZyBhcmlhLWhpZGRlbj0idHJ1ZSIgZm9jdXNhYmxlPSJmYWxzZSIgZGF0YS1wcmVmaXg9ImZhcyIgZGF0YS1pY29uPSJjaGV2cm9uLWRvd24iIGNsYXNzPSJzdmctaW5saW5lLS1mYSBmYS1jaGV2cm9uLWRvd24gZmEtdy0xNCIgcm9sZT0iaW1nIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCA0NDggNTEyIj48cGF0aCBmaWxsPSJjdXJyZW50Q29sb3IiIGQ9Ik0yMDcuMDI5IDM4MS40NzZMMTIuNjg2IDE4Ny4xMzJjLTkuMzczLTkuMzczLTkuMzczLTI0LjU2OSAwLTMzLjk0MWwyMi42NjctMjIuNjY3YzkuMzU3LTkuMzU3IDI0LjUyMi05LjM3NSAzMy45MDEtLjA0TDIyNCAyODQuNTA1bDE1NC43NDUtMTU0LjAyMWM5LjM3OS05LjMzNSAyNC41NDQtOS4zMTcgMzMuOTAxLjA0bDIyLjY2NyAyMi42NjdjOS4zNzMgOS4zNzMgOS4zNzMgMjQuNTY5IDAgMzMuOTQxTDI0MC45NzEgMzgxLjQ3NmMtOS4zNzMgOS4zNzItMjQuNTY5IDkuMzcyLTMzLjk0MiAweiI+PC9wYXRoPjwvc3ZnPg=="
$imgThumpsUp = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADAAAAAwCAYAAABXAvmHAAAAAXNSR0IArs4c6QAABZlJREFUaEPNWltsFGUU/s4/uzR4DaIogUSpgkRJ2W2BYnygmiiJiWF3IS2oBF8AoaVbEMQn00QFE6DdXUVt8MF4gRSls6iJGh948QIl7RaMUkjVqBCw3Aq0QLu7c8xMO7WXnZ1/trtr962d83/n+845e+bMmSVk4TN//+774hMSTxK4lJhna5pSSKRNZsJtOjwxupnFRSGSvzNRO1gcdsWVQ0fLK8+N1T1lCrCg6Z3JcWjPM2krCTQvQ5yjAD52s7K3OVB1MRMMxwKKDkSmuwRv1phXE9EtmTgddUZDDwvewy5t57FnN51xgiktoKShwZ2ccnM9gd8AyCiNbH+Y+bog2nG1gLZ3PFPdK4MvJaDoYOhhReNGQMyVAR2zDaNNg1JxLFB1yg7LVoBXDS0F8GGuom5FkBnXhMCqVl9QTScirQCPGnkRzHuI4LKLRC6uMzhJTFWxQPB9K3xLAcXRyFpmtjyYC8JpMKtj/uDbqa6nFKCXDQONBFLyTDSlOz0TAC9r82+MjjQYJaD4YN1DWlK0ENEd44H8fxy4WySV+S3LNrQP5TVMwCP7aycUuO9szlu3cRghAseoc2Jpy9q1cfPoMAHeptCrINruEDev5kzY0uYL7hwlYO6XddNEn3ISArfmlZFjZ9wtNJ7VsnTjWf3oYAaK1XCIgaBjvP/nQF3MH3x5UIA+mPUh8VfWZpsMROmRnOhy43pisLytUTT0uEm5Xx8AjQx4myLVIA5n4DcrR3QSrxQtQtnUQqz+vgmne67Y4hKjqjUQ3G0I8Kiho2MYiW2d2Y0COvmKwv4x658b12RFNMf8wVIqOVA/VSM6AyLbuWhMTFMcNiNvkjdNpEQwc1zBVPJEw88R49Nsk7PD08lvnVuG8hlFKU2/+vsEXmv5Li0MES8nbzQUBlO1ncNsXreKvOnjRFcn1v2g4mo8/SMBg0NUrNZ/yxBPZ5Ogk5ofaStLvv8cf00eNfwbAYWyAkrunob2rvPoSfTJHhm0syubny+dQ+VPUXTH5bBZow7yqmH9YfouGTZPTZuJbfMW49SVC1IpHoqZrbIZismMC7oAvdAm2AkwySskDFMnqc4F+f4K4l4pAYunz8KbJYshRnRaPeXrf4ymLadsl82wQA8IsC2h4KOPY9XMkpRJSicip+SNBOACedRQB4EetOscW4oWYfnA3VKmc+SsbIY4N77Esm1UJyQrIh/kB9uokxuZjAj9O/HS7NLB2UYmW3YNxOq6cSPzqpEVAO+VBbGr68u9NzCpYKLl98VJn7fjREAFzTkYutedxFknw5xdJlI5dtJ27YgPtND+YU7/w6uGmwHMlzo4YORERNbJA9CIDx/z1TxmCtgAIOJEgG4rIyIX5I17GHFlm6/mXUOAsevn5J+ZPNCnE5Er8hj5SKmL8KihegLVOM2CVSZyRt4gSLti/urNpm/jX2NdqwzNRC7J61trd8I1y3w9NXyxFY1sBfNbmWTBjEbggTn45vSpjMZtOb+8Oeav2WXaDhOgv4XhKTeOMMgrB5ZvK2oVnQULLVeLOp3xvNxNCsw7vqTm5NCwpdxEFEfDfo35s/G0XieBQGxJzRcjc265SilWw2sYaMh3kYzyx8wsaE2bL/hBKi5pd0Hj4RWTIFHZ6qu2DKTtMsuj1vvA4iMi3J7PbDDzVVKwMlXZ2H4HRhL1fB6eKRRuzF93olYSiYrWJZs67IJmmwEToOxQraura1IlGK/nKhvmi+6b8cvbfi2vldqtSAswhei71CSJLcRYk8nslDKiGnog0OCKu3Y4/QGIYwEmAX0ATFBihabRC0S8wMnzhIHBzJrAEUWjT3oTyX2/lG+6ZFcujruQLGBR03tTXKL3CY2xkAmzFY1mMOEeoP/nNgC6iXE+KfgPYrQLwuGEVnDoeGBdp6wPK7t/AUlevUYaHW1LAAAAAElFTkSuQmCC"

$findings_Part0 = @'
<html><head><style>
table { border-collapse: collapse; } 	
th, td { padding: 4px; text-align: left; border: 1px solid black; vertical-align:top; }
tr:hover {background-color: #EFDEDE;} 	
p {margin-top:50px;}	
h2 {color: black}

.table-header {   background-color: #11594A; color:white; }	
.table-header-critical {   	background-color: #FF6900; color: #000000; }	
.table-header-error {   	background-color: #FFC000; color: #000000; }
.table-header-warning {   	background-color: lightblue; color: #000000; }
.table-header-unclassified {background-color: #08B3CC; color: #000000; }
.table-header-passedRule {  background-color: #006400; color: #FFFFFF; }	

.critical-info { 	background-color: red; 	color: yellow; } 	
.error-info { 	background-color: orange; 	color: white; } 	
.warning-info { 	background-color: yellow; 	color: black; } 	
.ok-info { 	background-color: green; 	color: white; } 

.table-col-hide {display: none;}

</style>
'@
$findings_Part0 += @"
<script>
  function getCollectorUrl() {
		var wholeUrl = window.location.toString();
		var hashPart = window.location.hash.toString();
		var partToReplace = '$findingsHtml_FileName' + hashPart
		var collectorFolderName = '../$collector_FolderName'
		var newValue = wholeUrl.replace(partToReplace,collectorFolderName)        
        return newValue;
    }
  function getAnalyzerUrl() {
		var wholeUrl = window.location.toString();
		var hashPart = window.location.hash.toString();
		var partToReplace = '$findingsHtml_FileName' + hashPart
		var analyzerFolderName = './'
		var newValue = wholeUrl.replace(partToReplace,analyzerFolderName)        
        return newValue;
    }
    function toggleElement(elem) {

        var x = document.getElementById(elem);

        if (x.style.display === "none") {
            x.style.display = "block";
            x.previousSibling.childNodes[0].src = "$imgNowExpanded";
        } else {
            x.style.display = "none";
            x.previousSibling.childNodes[0].src = "$imgNowCollapsed";
        }
    }

</script>

</head><body>
"@
if ($displaySapCategories) {
    $findings_Part0 = $findings_Part0.Replace(".table-col-hide {display: none;}","");
}
AppendOutputToFileInTargetFolder $findings_Part0 $findingsHtml_FileName 

$findings_PartH1 = @'
<h1 style="color:black; text-align:center">SCSM Diagnostic Tool</h1>
<div style="text-align: center;font-size: x-large;"><b><a style="color: black;background-color: yellow;" target="_blank" href="https://forms.office.com/r/QpC8qkSLVA" title="Just a single question!">Feedback &#x1F60A; &#x1F610;</a></b></div>
'@
AppendOutputToFileInTargetFolder $findings_PartH1 $findingsHtml_FileName 

#endregion

#endregion

#region Get SM env info
#region init for Sm env info
$smEnvInfoRows = @()

$smEnv = (GetStatInfoRoot).AppendChild( (CreateElementForStatInfo SmEnv)  )
$smEnv_SM = $smEnv.AppendChild(   (CreateElementForStatInfo SM)   )
$smEnv_OS = $smEnv.AppendChild(   (CreateElementForStatInfo OS)   )
$smEnv_SQLSM = $smEnv.AppendChild(   (CreateElementForStatInfo SQLSM)   )
#endregion

#region Get SM version
#region Populate some known SM versions
$SCSM_Versions = @{}
$SCSM_Versions.Add("10.22.1313.0","2022 UR2")
$SCSM_Versions.Add("10.22.1219.0","2022 RTM + Hotfix")
$SCSM_Versions.Add("10.22.1068.0","2022 RTM")
$SCSM_Versions.Add("10.19.1035.137","2019 UR4")
$SCSM_Versions.Add("10.19.1035.101","2019 UR2")
$SCSM_Versions.Add("10.19.1035.73","2019 UR1")
$SCSM_Versions.Add("10.19.1035.0","2019 RTM")
$SCSM_Versions.Add("7.5.7487.0","2016 RTM")
$SCSM_Versions.Add("7.5.7487.37","2016 UR2")
$SCSM_Versions.Add("7.5.7487.64","2016 UR3")
$SCSM_Versions.Add("7.5.7487.89","2016 UR4")
$SCSM_Versions.Add("7.5.7487.130","2016 UR5")
$SCSM_Versions.Add("7.5.7487.161","2016 UR7")
$SCSM_Versions.Add("7.5.7487.176","2016 UR8")
$SCSM_Versions.Add("7.5.7487.210","2016 UR9")
$SCSM_Versions.Add("7.5.7487.231","2016 UR10")
$SCSM_Versions.Add("7.5.3079.0","2012 R2 RTM")
$SCSM_Versions.Add("7.5.3079.61","2012 R2 UR2")
$SCSM_Versions.Add("7.5.3079.148","2012 R2 UR3")
$SCSM_Versions.Add("7.5.3079.236","2012 R2 UR4")
$SCSM_Versions.Add("7.5.3079.315","2012 R2 UR5")
$SCSM_Versions.Add("7.5.3079.367","2012 R2 UR6")
$SCSM_Versions.Add("7.5.3079.402","2012 R2 UR6.Hotfix")
$SCSM_Versions.Add("7.5.3079.442","2012 R2 UR7")
$SCSM_Versions.Add("7.5.3079.607","2012 R2 UR9")
$SCSM_Versions.Add("7.5.3079.768","2012 R2 UR14")
#endregion

#$linesIn_SCSM_Version = GetLinesFromString (GetFileContentInSourceFolder_WithAbort SCSM_Version.txt)
$linesIn_SCSM_Version = GetLinesFromString (GetFileContentInSourceFolder SCSM_Version.txt)
$searchStrForSCSMProduct = 'Microsoft System Center Service Manager'  #that should work for 2016+
$lineIn_SCSM_Version = $linesIn_SCSM_Version | Select-String -Pattern $searchStrForSCSMProduct -SimpleMatch | Out-String

if ( [string]::IsNullOrWhiteSpace($lineIn_SCSM_Version) ) {
    $searchStrForSCSMProduct = 'Microsoft System Center 2016 Service Manager'
    $lineIn_SCSM_Version = $linesIn_SCSM_Version | Select-String -Pattern $searchStrForSCSMProduct -SimpleMatch | Out-String
}
if ( [string]::IsNullOrWhiteSpace($lineIn_SCSM_Version) ) {
    $searchStrForSCSMProduct = 'Microsoft System Center 2012 R2 Service Manager'
    $lineIn_SCSM_Version = $linesIn_SCSM_Version | Select-String -Pattern $searchStrForSCSMProduct -SimpleMatch | Out-String
}
if ( [string]::IsNullOrWhiteSpace($lineIn_SCSM_Version) ) {
    $searchStrForSCSMProduct = 'Microsoft System Center 2012 - Service Manager'
    $lineIn_SCSM_Version = $linesIn_SCSM_Version | Select-String -Pattern $searchStrForSCSMProduct -SimpleMatch | Out-String
}

$SCSM_Version = $lineIn_SCSM_Version.Replace($searchStrForSCSMProduct,'').Trim()
if (-not (Is4PartVersionValid $SCSM_Version) ) {
    #region try reading from SCSM_Version.csv, if exists
        if (Test-Path (GetFileNameInSourceFolder SCSM_Version.csv) ) {
            $linesIn_SCSM_Version = ConvertFrom-Csv (GetFileContentInSourceFolder SCSM_Version.csv)
            $SCSM_Version = GetValueFromImportedCsv $linesIn_SCSM_Version Publisher "Microsoft Corporation" DisplayVersion
        }
    #endregion
}
$smEnv_SM.SetAttribute("Version", $SCSM_Version)
$SCSM_VersionUserFriendly = $SCSM_Version
if ( [string]::IsNullOrWhiteSpace( $SCSM_Versions[$SCSM_Version] ) ) {
    $SCSM_VersionUserFriendly += " found in $(CollectorLink SCSM_Version.txt). Check here for old $(GetAnchorForExternal 'https://social.technet.microsoft.com/wiki/contents/articles/4226.system-center-service-manager-list-of-build-numbers.aspx' 'Versions')"
    $smEnv_SM.SetAttribute("VersionUserFriendly", "?")
}
else {
    $SCSM_VersionUserFriendly += " ($($SCSM_Versions[$SCSM_Version]))"
    $smEnv_SM.SetAttribute("VersionUserFriendly", $SCSM_VersionUserFriendly)
}

$smEnvRow=GetEmptySmEnvRow
$smEnvRow.SmEnvInfo="Version"
$smEnvRow.SMEnvValue=$SCSM_VersionUserFriendly
$smEnvInfoRows += $smEnvRow
#endregion
#region Detect components like WF, DW, 2ndMS, Portal etc.
#$linesIn_ScsmRolesFound = GetFileContentInSourceFolder_WithAbort ScsmRolesFound.txt
$linesIn_ScsmRolesFound = GetFileContentInSourceFolder ScsmRolesFound.txt
$ScsmRolesFound = @() #bcz a machine can host multiple roles like mgmt server + Console
if ($linesIn_ScsmRolesFound.Contains("Primary/Workflow")) {$ScsmRolesFound += "WF"}
if ($linesIn_ScsmRolesFound.Contains("Secondary")) {$ScsmRolesFound += "2ndMS"}
if ($linesIn_ScsmRolesFound.Contains("DW")) {$ScsmRolesFound += "DW"}

if ($ScsmRolesFound.Length -eq 0) {
    $ScsmRolesFound += "UNK"
}
$telemetry.MainComponent = $ScsmRolesFound[0]
$smEnvRow=GetEmptySmEnvRow
$smEnvRow.SmEnvInfo="Component detected"
$smEnvRow.SMEnvValue=$ScsmRolesFound
$smEnvInfoRows += $smEnvRow
$smEnv_SM.SetAttribute("Components", $ScsmRolesFound)
#endregion
#region Get Computer Name
$Scsm_ComputerName = ""
$EnvVars1 = Import-Csv (GetFileNameInSourceFolder EnvVars.csv)
$Scsm_ComputerName = GetValueFromImportedCsv $EnvVars1 "Key" "COMPUTERNAME" "Value"

$smEnvRow=GetEmptySmEnvRow
$smEnvRow.SmEnvInfo="Computer Name"
$smEnvRow.SMEnvValue=$Scsm_ComputerName
$smEnvInfoRows += $smEnvRow
#endregion
#region Get Computer FQDN Name
$Scsm_ComputerFqdnName = ""
$Scsm_ComputerFqdnName = GetFirstLine ( GetFileContentInSourceFolder Hostname_fqdn.txt )
if ( $Scsm_ComputerFqdnName -eq "") {
    $EnvVars1 = Import-Csv (GetFileNameInSourceFolder EnvVars.csv)
    $Scsm_ComputerFqdnName = GetValueFromImportedCsv $EnvVars1 "Key" "USERDNSDOMAIN" "Value"
    $Scsm_ComputerFqdnName = "$Scsm_ComputerName.$Scsm_ComputerFqdnName"
}
$smEnvRow=GetEmptySmEnvRow
$smEnvRow.SmEnvInfo="Computer FQDN Name"
$smEnvRow.SMEnvValue=$Scsm_ComputerFqdnName
$smEnvInfoRows += $smEnvRow
#endregion
#region Get Time with TZ
$smEnvRow=GetEmptySmEnvRow
$smEnvRow.SmEnvInfo="Computer local Time + TZ"
$smEnvRow.SMEnvValue= GetLinesFromString (GetFileContentInSourceFolder Get-Date.txt)
$smEnvInfoRows += $smEnvRow
$smEnv_OS.SetAttribute("LocalTimeWithTZ", $smEnvRow.SMEnvValue)
#endregion
#region Get OS Info + Locale
$smEnvRow=GetEmptySmEnvRow
$smEnvRow.SmEnvInfo="OS Info"
$msinfo32Content = GetFileContentInSourceFolder msinfo32.txt
[string]$tmp = GetFirstLineThatStartsWith $msinfo32Content "OS Name`t" -doTrim $false
if ($tmp -eq $null) {
									   
    $smEnvRow.SMEnvValue = "?"
}
else {    
										
    $smEnvRow.SMEnvValue = $tmp.Replace("OS Name`t","")
}
$smEnv_OS.SetAttribute("Name", $smEnvRow.SMEnvValue.Trim())

$smEnvRow.SMEnvValue += "<br/>Locale: "
[string]$tmp = GetFirstLineThatStartsWith $msinfo32Content "Locale`t" -doTrim $false
if ($tmp -eq $null) {
    $smEnvRow.SMEnvValue += "?"
    $smEnv_OS.SetAttribute("Locale", "?")
}
else {
										  
    $smEnvRow.SMEnvValue += $tmp.Replace("Locale`t","")
    $smEnv_OS.SetAttribute("Locale", $tmp.Replace("Locale`t","").Trim())
}

$smEnvRow.SMEnvValue += "<br/>More in $(CollectorLink msinfo32.txt)"
$smEnvInfoRows += $smEnvRow

$smEnv_OS.SetAttribute("InternetAvailable", (IsInternetAvailable) )
#endregion
#region Get SQL Info
$smEnvRow=GetEmptySmEnvRow
$smEnvRow.SmEnvInfo="SQL Server Info"
$linesIn_SQL_Info = GetLinesFromString( GetFileContentInSourceFolder SQL_Info.csv )
if ($linesIn_SQL_Info.Count -lt 1) {
    $smEnvRow.SMEnvValue = "?"
}
else {
    $smEnvRow.SMEnvValue = $linesIn_SQL_Info[1].Substring(1)
}
$smEnv_SQLSM.SetAttribute("Version", $smEnvRow.SMEnvValue)
$smEnvRow.SMEnvValue += "<br/>More in $(CollectorLink SQL_Info.csv)"
$smEnvInfoRows += $smEnvRow
#endregion
#endregion

#region set Culture specific stuff
    $inputDateTimeUtcString = (GetFileContentInSourceFolder Get-UtcDate.txt).Trim()    
    [datetime]$inputDateTimeUtc = [datetime]::ParseExact($inputDateTimeUtcString.Trim(), "yyyy-MM-dd__HH:mm.ss.fff", $null)
    $inputDateTimeString = (GetFileContentInSourceFolder Get-Date.txt).Trim()    
    [datetime]$inputDateTime = [datetime]::ParseExact($inputDateTimeString.Trim(), "yyyy-MM-dd__HH:mm.ss.fff zzz", $null)
    
    #the below will be used later in Number and Date operations
    $sourceDateTimeFormat = (GetFileContentInSourceFolder CurrentCulture.DateTimeFormat.csv) | ConvertFrom-Csv
    $sourceNumberFormat = (GetFileContentInSourceFolder CurrentCulture.NumberFormat.csv) | ConvertFrom-Csv
#endregion

#region Init before running rules   
New-Variable -Name Result_Problems -Value @() -Force -Option AllScope
New-Variable -Name Result_OKs -Value @() -Force -Option AllScope

    $findings = (GetStatInfoRoot).AppendChild( (CreateElementForStatInfo Findings) )
    $findings_Critical = $findings.AppendChild( (CreateElementForStatInfo Critical) )
    $findings_Error = $findings.AppendChild( (CreateElementForStatInfo Error) )
    $findings_Warning = $findings.AppendChild( (CreateElementForStatInfo Warning) )
    $findings_Unclassified = $findings.AppendChild( (CreateElementForStatInfo Unclassified) ) 

    #region set SAP Categories
    $SAPCategories = @()  
    #region SAP list for Administrator Console Issues
    $pr= [cProblemCategory]::new("Console","Administrator Console Issues", $null)
    $SAPCategories += $pr
        $SAPCategories += [cProblemCategory]::new("Console\Connectivity", "Administrator Console Issues\Connection failure issues", $pr);
        $SAPCategories += [cProblemCategory]::new("Console\Display Driver", "Administrator Console Issues\Display driver issues", $pr);
        $SAPCategories += [cProblemCategory]::new("Console\Other", "Administrator Console Issues\Other", $pr);
        $SAPCategories += [cProblemCategory]::new("Console\Usage", "Administrator Console Issues\Usage issues", $pr);
    #endregion  
    #region SAP list for Authoring     #ignored because Analyzer does not handle Authoring issues (for now)
    #$pr= [cProblemCategory]::new("Authoring","Authoring", $null)    
    #endregion
    #region SAP list for Connectors
    $pr= [cProblemCategory]::new("Connector","Connectors", $null)
    $SAPCategories += $pr
        $SAPCategories += [cProblemCategory]::new("Connector\AD", "Connectors\Active Directory Connector", $pr);
        $SAPCategories += [cProblemCategory]::new("Connector\SCCM", "Connectors\Configurations Manager Connector", $pr);
        $SAPCategories += [cProblemCategory]::new("Connector\CSV Import", "Connectors\CSV import", $pr);
        $SAPCategories += [cProblemCategory]::new("Connector\Exch", "Connectors\Exchange Connector", $pr);
        $SAPCategories += [cProblemCategory]::new("Connector\SCOM Alert", "Connectors\Operations Manager Alert Connector", $pr);
        $SAPCategories += [cProblemCategory]::new("Connector\SCOM CI", "Connectors\Operations Manager Configuration Item (CI) Connector", $pr);
        $SAPCategories += [cProblemCategory]::new("Connector\SCO", "Connectors\Orchestrator Connector", $pr);
        $SAPCategories += [cProblemCategory]::new("Connector\Other", "Connectors\Other", $pr);
        $SAPCategories += [cProblemCategory]::new("Connector\VMM", "Connectors\Virtual Machine Manager Connector", $pr);
    #endregion
    #region SAP list for Data Warehouse and Reporting
    $pr= [cProblemCategory]::new("DW","Data Warehouse and Reporting", $null)
    $SAPCategories += $pr
        $SAPCategories += [cProblemCategory]::new("DW\Reg", "Data Warehouse and Reporting\Data warehouse registration or unregistration", $pr);
        $SAPCategories += [cProblemCategory]::new("DW\Perf", "Data Warehouse and Reporting\DW Server performance", $pr);
        $SAPCategories += [cProblemCategory]::new("DW\ETL", "Data Warehouse and Reporting\Extract, transform, and load job", $pr);
        $SAPCategories += [cProblemCategory]::new("DW\MPSyncJob", "Data Warehouse and Reporting\MPSyncJob", $pr);
        $SAPCategories += [cProblemCategory]::new("DW\Cube", "Data Warehouse and Reporting\Online analytical processing (OLAP) cube", $pr);
        $SAPCategories += [cProblemCategory]::new("DW\Other", "Data Warehouse and Reporting\Other", $pr);
        $SAPCategories += [cProblemCategory]::new("DW\Report", "Data Warehouse and Reporting\Reporting", $pr);
    #endregion
    #region SAP list for Self-Service Portal
    $pr= [cProblemCategory]::new("SSP","Self-Service Portal", $null)
    $SAPCategories += $pr        
        $SAPCategories += [cProblemCategory]::new("SSP\Activity", "Self-Service Portal\Activities issues", $pr);
        $SAPCategories += [cProblemCategory]::new("SSP\Announcement", "Self-Service Portal\Announcement issues", $pr);
        $SAPCategories += [cProblemCategory]::new("SSP\Certificate", "Self-Service Portal\Certificate issues", $pr);
        $SAPCategories += [cProblemCategory]::new("SSP\Approval", "Self-Service Portal\Change approval issues", $pr);
        $SAPCategories += [cProblemCategory]::new("SSP\Client Conf", "Self-Service Portal\Client configuration issues", $pr);
        $SAPCategories += [cProblemCategory]::new("SSP\Clients", "Self-Service Portal\Clients", $pr);
        $SAPCategories += [cProblemCategory]::new("SSP\Submit", "Self-Service Portal\Incident creation issues", $pr);
        $SAPCategories += [cProblemCategory]::new("SSP\KB", "Self-Service Portal\Knowledge Base article issues", $pr);
        $SAPCategories += [cProblemCategory]::new("SSP\Other", "Self-Service Portal\Other", $pr);
        $SAPCategories += [cProblemCategory]::new("SSP\Customization", "Self-Service Portal\Portal customization issues", $pr);
        $SAPCategories += [cProblemCategory]::new("SSP\Perf", "Self-Service Portal\Portal performance", $pr);
        $SAPCategories += [cProblemCategory]::new("SSP\Portals", "Self-Service Portal\Portals", $pr);
        $SAPCategories += [cProblemCategory]::new("SSP\RO", "Self-Service Portal\Request offering", $pr);
        $SAPCategories += [cProblemCategory]::new("SSP\RB", "Self-Service Portal\Runbook integration", $pr);
        $SAPCategories += [cProblemCategory]::new("SSP\SO", "Self-Service Portal\Service offering", $pr);
        $SAPCategories += [cProblemCategory]::new("SSP\SW Prov", "Self-Service Portal\Software provisioning issues", $pr);
        $SAPCategories += [cProblemCategory]::new("SSP\Website", "Self-Service Portal\Website issues", $pr);
    #endregion
    #region SAP list for Service Manager Components
    $pr= [cProblemCategory]::new("SMComp","Service Manager Components", $null)
    $SAPCategories += $pr
        $SAPCategories += [cProblemCategory]::new("SMComp\Activities", "Service Manager Components\Activities issues", $pr);
        $SAPCategories += [cProblemCategory]::new("SMComp\Business Services", "Service Manager Components\Business Services or service maps", $pr);
        $SAPCategories += [cProblemCategory]::new("SMComp\CR", "Service Manager Components\Change request issues", $pr);
        $SAPCategories += [cProblemCategory]::new("SMComp\CI", "Service Manager Components\Configuration items issues", $pr);
        $SAPCategories += [cProblemCategory]::new("SMComp\Connector", "Service Manager Components\Connector issues", $pr);
        $SAPCategories += [cProblemCategory]::new("SMComp\Grooming", "Service Manager Components\Grooming issues", $pr);
        $SAPCategories += [cProblemCategory]::new("SMComp\IR", "Service Manager Components\Incident issues", $pr);
        $SAPCategories += [cProblemCategory]::new("SMComp\KA", "Service Manager Components\Knowledge article issues", $pr);
        $SAPCategories += [cProblemCategory]::new("SMComp\MP", "Service Manager Components\Management pack issues", $pr);
        $SAPCategories += [cProblemCategory]::new("SMComp\Notification", "Service Manager Components\Notification issues", $pr);
        $SAPCategories += [cProblemCategory]::new("SMComp\Other", "Service Manager Components\Other", $pr);
        $SAPCategories += [cProblemCategory]::new("SMComp\PR", "Service Manager Components\Problem management issues", $pr);
        $SAPCategories += [cProblemCategory]::new("SMComp\Related Items", "Service Manager Components\Related items issues", $pr);
        $SAPCategories += [cProblemCategory]::new("SMComp\Task", "Service Manager Components\Task issues", $pr);
        $SAPCategories += [cProblemCategory]::new("SMComp\Template", "Service Manager Components\Template issues", $pr);
        $SAPCategories += [cProblemCategory]::new("SMComp\Workflow", "Service Manager Components\Workflow issues", $pr);
    #endregion
    #region SAP list for Service Manager Configuration and Performance
    $pr= [cProblemCategory]::new("SMConfPerf","Service Manager Configuration and Performance", $null)
    $SAPCategories += $pr
        $SAPCategories += [cProblemCategory]::new("SMConfPerf\Console Setup", "Service Manager Configuration and Performance\Administrator Console setup issues", $pr);
        $SAPCategories += [cProblemCategory]::new("SMConfPerf\DW", "Service Manager Configuration and Performance\Data warehouse setup issues", $pr);
        $SAPCategories += [cProblemCategory]::new("SMConfPerf\DCM", "Service Manager Configuration and Performance\Desired Configuration Management (DCM) issues", $pr);
        $SAPCategories += [cProblemCategory]::new("SMConfPerf\Other", "Service Manager Configuration and Performance\Other", $pr);
        $SAPCategories += [cProblemCategory]::new("SMConfPerf\Perf", "Service Manager Configuration and Performance\Performance issues", $pr);
        $SAPCategories += [cProblemCategory]::new("SMConfPerf\Security", "Service Manager Configuration and Performance\Security", $pr);
        $SAPCategories += [cProblemCategory]::new("SMConfPerf\SM Setup", "Service Manager Configuration and Performance\Service Manager setup issues", $pr);
        $SAPCategories += [cProblemCategory]::new("SMConfPerf\SSP Setup", "Service Manager Configuration and Performance\Web Portal setup issues", $pr);
    #endregion
    #region SAP list for Setup and Disaster Recovery
    $pr= [cProblemCategory]::new("SetupDR","Setup and Disaster Recovery", $null)
    $SAPCategories += $pr
        $SAPCategories += [cProblemCategory]::new("SetupDR\Admin", "Setup and Disaster Recovery\Administration space", $pr);
        $SAPCategories += [cProblemCategory]::new("SetupDR\Authentication", "Setup and Disaster Recovery\Authentication", $pr);
        $SAPCategories += [cProblemCategory]::new("SetupDR\Authoring Tool", "Setup and Disaster Recovery\Authoring Tool deployment", $pr);
        $SAPCategories += [cProblemCategory]::new("SetupDR\Console crash", "Setup and Disaster Recovery\Console crash", $pr);
        $SAPCategories += [cProblemCategory]::new("SetupDR\DW cmdlet", "Setup and Disaster Recovery\Data warehouse cmdlet", $pr);
        $SAPCategories += [cProblemCategory]::new("SetupDR\DW install", "Setup and Disaster Recovery\Data warehouse server deployment", $pr);
        $SAPCategories += [cProblemCategory]::new("SetupDR\DR", "Setup and Disaster Recovery\Disaster recovery", $pr);
        $SAPCategories += [cProblemCategory]::new("SetupDR\Encryption keys", "Setup and Disaster Recovery\Encryption keys", $pr);
        $SAPCategories += [cProblemCategory]::new("SetupDR\Standalone Component Installer", "Setup and Disaster Recovery\Standalone Component Installer", $pr);
        $SAPCategories += [cProblemCategory]::new("SetupDR\Installation: Unified Installer", "Setup and Disaster Recovery\Installation: Unified Installer", $pr);
        $SAPCategories += [cProblemCategory]::new("SetupDR\Other", "Setup and Disaster Recovery\Other", $pr);
        $SAPCategories += [cProblemCategory]::new("SetupDR\Partner solutions", "Setup and Disaster Recovery\Partner solutions", $pr);
        $SAPCategories += [cProblemCategory]::new("SetupDR\SSP install", "Setup and Disaster Recovery\Portal deployment", $pr);
        $SAPCategories += [cProblemCategory]::new("SetupDR\Run As account", "Setup and Disaster Recovery\Run As account", $pr);
        $SAPCategories += [cProblemCategory]::new("SetupDR\Security role", "Setup and Disaster Recovery\Security role", $pr);
        $SAPCategories += [cProblemCategory]::new("SetupDR\Service crash", "Setup and Disaster Recovery\Service crash", $pr);
        $SAPCategories += [cProblemCategory]::new("SetupDR\SM cmdlet", "Setup and Disaster Recovery\Service Manager cmdlet", $pr);
        $SAPCategories += [cProblemCategory]::new("SetupDR\Console install", "Setup and Disaster Recovery\Service Manager Console deployment", $pr);
        $SAPCategories += [cProblemCategory]::new("SetupDR\Console Perf", "Setup and Disaster Recovery\Service Manager Console performance", $pr);
        $SAPCategories += [cProblemCategory]::new("SetupDR\SM install", "Setup and Disaster Recovery\Service Manager Server deployment", $pr);
        $SAPCategories += [cProblemCategory]::new("SetupDR\Slow SDK startup", "Setup and Disaster Recovery\Slow Data Access Service startup", $pr);
        $SAPCategories += [cProblemCategory]::new("SetupDR\DB Perf", "Setup and Disaster Recovery\SQL Server performance", $pr);
        $SAPCategories += [cProblemCategory]::new("SetupDR\SharePoint SSP WCS install", "Setup and Disaster Recovery\Web Content Server deployment", $pr);
    #endregion
    #region SAP list for Workflows
    $pr= [cProblemCategory]::new("WF","Workflows", $null)
    $SAPCategories += $pr
        $SAPCategories += [cProblemCategory]::new("WF\CR", "Workflows\Change management", $pr);
        $SAPCategories += [cProblemCategory]::new("WF\Chargeback", "Workflows\Chargeback", $pr);
        $SAPCategories += [cProblemCategory]::new("WF\CI", "Workflows\Configuration management", $pr);
        $SAPCategories += [cProblemCategory]::new("WF\Duplicate emails", "Workflows\Duplicate email notification", $pr);
        $SAPCategories += [cProblemCategory]::new("WF\IR", "Workflows\Incident management", $pr);
        $SAPCategories += [cProblemCategory]::new("WF\MS Perf", "Workflows\Management Server performance", $pr);
        $SAPCategories += [cProblemCategory]::new("WF\Notification templates", "Workflows\Notification templates", $pr);
        $SAPCategories += [cProblemCategory]::new("WF\PR", "Workflows\Problem management", $pr);
        $SAPCategories += [cProblemCategory]::new("WF\RR", "Workflows\Release management", $pr);
        $SAPCategories += [cProblemCategory]::new("WF\SLA", "Workflows\Service level management", $pr);
        $SAPCategories += [cProblemCategory]::new("WF\SR", "Workflows\Service requests", $pr);
        $SAPCategories += [cProblemCategory]::new("WF\SMTP conf", "Workflows\SMTP channel", $pr);
        $SAPCategories += [cProblemCategory]::new("WF\Conf", "Workflows\Workflow configuration", $pr);
        $SAPCategories += [cProblemCategory]::new("WF\Perf", "Workflows\Workflow performance", $pr);
    #endregion
    #endregion 
[cSAPCategoryHelper]::SAPCategoryList = $SAPCategories

    #region setting vars to be used in all rules
    if (IsSourceAnyScsmMgmtServer) {
        #region This applies to ServiceManager and DWStagingAndConfig as well.
        $linesIn_regValues = GetFileContentInSourceFolder SystemCenter.regValues.txt

        $MainSQL_InstanceName = GetFirstLineThatStartsWith $linesIn_regValues '"DatabaseServerName"="'    
        $MainSQL_InstanceName = $MainSQL_InstanceName.Split("=")[1].Replace('"','')
        $MainSQL_DbName = GetFirstLineThatStartsWith $linesIn_regValues '"DatabaseName"="'
        $MainSQL_DbName = $MainSQL_DbName.Split("=")[1].Replace('"','')
        #endregion
    }
    if (IsSourceScsmDwMgmtServer) {
        #region To be used by subsequent DW rules
        $linesIn_regValues = GetFileContentInSourceFolder SystemCenter.regValues.txt

        $DW_Rep_SQL_InstanceName = GetFirstLineThatStartsWith $linesIn_regValues '"RepositorySQLInstance"="'    
        $DW_Rep_SQL_InstanceName = $DW_Rep_SQL_InstanceName.Split("=")[1].Replace('"','')
        $DW_Rep_SQL_DbName = GetFirstLineThatStartsWith $linesIn_regValues '"RepositoryDatabaseName"="'
        $DW_Rep_SQL_DbName = $DW_Rep_SQL_DbName.Split("=")[1].Replace('"','')

        $DW_DM_SQL_InstanceName = GetFirstLineThatStartsWith $linesIn_regValues '"DataMartSQLInstance"="'    
        $DW_DM_SQL_InstanceName = $DW_DM_SQL_InstanceName.Split("=")[1].Replace('"','')
        $DW_DM_SQL_DbName = GetFirstLineThatStartsWith $linesIn_regValues '"DataMartDatabaseName"="'
        $DW_DM_SQL_DbName = $DW_DM_SQL_DbName.Split("=")[1].Replace('"','')

        $DW_CM_SQL_InstanceName = GetFirstLineThatStartsWith $linesIn_regValues '"CMDataMartSQLInstance"="'    
        $DW_CM_SQL_InstanceName = $DW_CM_SQL_InstanceName.Split("=")[1].Replace('"','')
        $DW_CM_SQL_DbName = GetFirstLineThatStartsWith $linesIn_regValues '"CMDataMartDatabaseName"="'
        $DW_CM_SQL_DbName = $DW_CM_SQL_DbName.Split("=")[1].Replace('"','')

        $DW_OM_SQL_InstanceName = GetFirstLineThatStartsWith $linesIn_regValues '"OMDataMartSQLInstance"="'    
        $DW_OM_SQL_InstanceName = $DW_OM_SQL_InstanceName.Split("=")[1].Replace('"','')
        $DW_OM_SQL_DbName = GetFirstLineThatStartsWith $linesIn_regValues '"OMDataMartDatabaseName"="'
        $DW_OM_SQL_DbName = $DW_OM_SQL_DbName.Split("=")[1].Replace('"','')

        $SMDBInfo = ConvertFrom-Csv ( GetFileContentInSourceFolder SQL_SMDB_Info.csv )
        $SMDB_SQL_InstanceName = $SMDBInfo.SQLInstance_SMDB
        $SMDB_SQL_DbName = $SMDBInfo.SQLDatabase_SMDB

        #endregion
    }
    #endregion

#endregion

																					 
    Ram Analyze_Rules -phase Analyzer
						

#region Writing Findings.html

#region write FindingsAtAGlance
$writeSummaryOfFindings = $false # KH: Stopped to show this to prevent noise in $findingsHtml_FileName
if ($writeSummaryOfFindings) {
 #region Findings By Severity
$findings_FindingsBySeverity_Top = @'
<p><h2>Findings by Severity</h2><table>
<tr><th class="table-header">Severity</th><th class="table-header">Count</th></tr>
'@
AppendOutputToFileInTargetFolder $findings_FindingsBySeverity_Top $findingsHtml_FileName 

$findings_FindingsBySeverity_Rows = @'
<tr><td class="critical-info">Critical Errors</td><td><a href="#Critical">|CriticalErrors|</a></td></tr>
<tr><td class="error-info">Error</td><td><a href="#Errors">|Errors|</a></td></tr>
<tr><td class="warning-info">Warning</td><td><a href="#Warnings">|Warnings|</a></td></tr>
<tr><td class="ok-info">OKs</td><td><a href="#OKs">|OKs|</a></td></tr>
'@
$findings_FindingsBySeverity_Rows = $findings_FindingsBySeverity_Rows.Replace("|CriticalErrors|", $Result_CriticalErrors.Count.ToString()).Replace("|Errors|", $Result_Errors.Count.ToString()).Replace("|Warnings|",$Result_Warnings.Count.ToString()).Replace("|OKs|",$Result_OKs.Count.ToString())
AppendOutputToFileInTargetFolder $findings_FindingsBySeverity_Rows $findingsHtml_FileName 

$findings_FindingsBySeverity_Bottom = @'
</table></p>
'@
AppendOutputToFileInTargetFolder $findings_FindingsBySeverity_Bottom $findingsHtml_FileName 
 #endregion

 #region Findings By ProblemCategory
$findings_FindingsByProblemCategory_Top = @'
<p><h2>Findings by Problem Scope</h2><table>
<tr><th class="table-header">Scope</th><th class="table-header">Count</th></tr>
'@
AppendOutputToFileInTargetFolder $findings_FindingsByProblemCategory_Top $findingsHtml_FileName 

$findings_FindingsByProblemCategory_Rows = ''
$ProblemCategoryNames = [ProblemCategory].GetEnumNames() 

foreach ($ProblemCategoryName in $ProblemCategoryNames) {
    $scopeCount = $Result_Problems.Where( {
        $_.ProblemCategory.ToString() -eq $ProblemCategoryName
    } ).Count
    $scopeCount = if ($scopeCount -eq 0) {""} else {$scopeCount.ToString()}
    $findings_FindingsByProblemCategory_Rows += '<tr><td>'+ $ProblemCategoryName +'</td><td>'+ $scopeCount +'</td></tr>'
}

$findings_FindingsByProblemCategory_Rows = $findings_FindingsByProblemCategory_Rows.Replace("|CriticalErrors|", $Result_CriticalErrors.Count.ToString()).Replace("|Errors|", $Result_Errors.Count.ToString()).Replace("|Warnings|",$Result_Warnings.Count.ToString()).Replace("|OKs|",$Result_OKs.Count.ToString())
AppendOutputToFileInTargetFolder $findings_FindingsByProblemCategory_Rows $findingsHtml_FileName 

$findings_FindingsByProblemCategory_Bottom = @'
</table></p>
'@
AppendOutputToFileInTargetFolder $findings_FindingsByProblemCategory_Bottom $findingsHtml_FileName 
 #endregion
}
#endregion

#region write FindingDetails

 #region writing Problems into separate sections
 $findings.SetAttribute("TotalProblems", $Result_Problems.Count)
 $findings.SetAttribute("TotalPassedRules", $Result_OKs.Count)
 $findings.SetAttribute("TotalRules", $Result_OKs.Count + $Result_Problems.Count)
 if ($Result_Problems.Count -eq 0) {
    $problemsFoundBanner = @"
        <h2 style='text-align: left'><img style="width:20px; margin-right: 5px" src="$imgThumpsUp"/><span> Good, none of the rules could find any problem. </span><img style="width:20px; margin-right: 5px" src="$imgThumpsUp" /></h2>
"@ 
    AppendOutputToFileInTargetFolder $problemsFoundBanner $findingsHtml_FileName    
 }
 else {    
    foreach( $problemSeverity in [ProblemSeverity]::Critical, [ProblemSeverity]::Error, [ProblemSeverity]::Warning, [ProblemSeverity]::Unclassified ) {
        
        $problemCountForCurrentSeverity = 0
        foreach($Result_Problem in $Result_Problems) {
            if ($Result_Problem.ProblemSeverity -eq $problemSeverity) { 
                $problemCountForCurrentSeverity++ 
            }
        }
        $findings.SelectSingleNode($problemSeverity).SetAttribute("Count", $problemCountForCurrentSeverity)
        if ($problemCountForCurrentSeverity -gt 0) {                
            
            $severityCaption = switch ($problemSeverity) {
                Critical  { "<p><h2 onclick=""toggleElement('div-criticals');"" style=""cursor: pointer;"" title=""Toggle expand/collapse""><img style=""width:15px; margin-right: 5px"" src=""$imgNowCollapsed"" alt=""Toggle expand/collapse"" /><span style=""background-color:#FF6900; color:black"">CRITICAL PROBLEMS ($problemCountForCurrentSeverity)</span></h2><div id=""div-criticals"" style=""display:none""><br/><div style=""font-size:15px; color:black"">These are NON-ignorable errors. They MUST be fixed.</div>"; break }       
                Error     { "<p><h2 onclick=""toggleElement('div-errors');"" style=""cursor: pointer;"" title=""Toggle expand/collapse""   ><img style=""width:15px; margin-right: 5px"" src=""$imgNowCollapsed"" alt=""Toggle expand/collapse"" /><span style=""background-color:#FFC000; color:black"">ERRORS ($problemCountForCurrentSeverity)              </span></h2><div id=""div-errors"" style=""display:none"">   <br/><div style=""font-size:15px; color:black"">They contain '$(IgnoreRuleIfText)' but when not ignored, they are severe Errors.</div>" ; break }
                Warning   { "<p><h2 onclick=""toggleElement('div-warnings');"" style=""cursor: pointer;"" title=""Toggle expand/collapse"" ><img style=""width:15px; margin-right: 5px"" src=""$imgNowCollapsed"" alt=""Toggle expand/collapse"" /><span style=""background-color:lightblue; color:black"">Warnings ($problemCountForCurrentSeverity)        </span></h2><div id=""div-warnings"" style=""display:none""> <br/><div style=""font-size:15px; color:black"">They contain '$(IgnoreRuleIfText)' but when not ignored, they are not necessarily severe errors.</div>" ; break }
                Default   { "<p><h2 onclick=""toggleElement('div-unclassifieds');"" style=""cursor: pointer;""><pre>------------ !!!  UNCLASSIFIED PROBLEMS FOUND  !!!  ---------</pre></h2><div id=""div-unclassifieds""><h3>The below have wrong Severity assigned. Need to be fixed in Analyzer code.</h3>" ; break }
            }            
            $tableStyle = "border-style: double; border-color: " 
            $tableStyle += switch ($problemSeverity) {
                Critical  { "#FF6900" ; break }       
                Error     { "#FFC000" ; break }      
                Warning   { "lightblue" ; break }      
                Default   { "#006400" ; break }   
            }
            AppendOutputToFileInTargetFolder "$severityCaption<table style='$tableStyle'>" $findingsHtml_FileName

            $severityHeaderStyle = switch ($problemSeverity) {
                Critical  { "table-header-critical" ; break }       
                Error     { "table-header-error" ; break }      
                Warning   { "table-header-warning" ; break }      
                Default   { "table-header-unclassified" ; break }      
            }
            $findings_FindingDetails_Top = @"
            <tr class="$severityHeaderStyle">
<!--            <th>Severity</th> -->
            <th class="table-col-hide">Case SAP Category</th>
            <th>Rule</th>
            <th>Definition</th>
            <th>Finding</th>
            </tr>
"@   
            AppendOutputToFileInTargetFolder $findings_FindingDetails_Top $findingsHtml_FileName 

            foreach($Result_Problem in $Result_Problems) {
                if ($Result_Problem.ProblemSeverity -eq $problemSeverity) {
                    $findings_FindingDetails_Row = '<tr>'
                    #$findings_FindingDetails_Row += "<td>" + $Result_Problem.ProblemSeverity +"</td>"
                    $findings_FindingDetails_Row += "<td class='table-col-hide'>" + $Result_Problem.SAPCategories +"</td>"
                    $findings_FindingDetails_Row += "<td>" + $Result_Problem.RuleName +"</td>"
                    $findings_FindingDetails_Row += "<td>" + $Result_Problem.RuleDesc +"</td>"
                    $findings_FindingDetails_Row += "<td>" + $Result_Problem.RuleResult +"</td>"
                    $findings_FindingDetails_Row += '</tr>'
                    AppendOutputToFileInTargetFolder $findings_FindingDetails_Row $findingsHtml_FileName
                    $failedRule = $findings.SelectSingleNode($problemSeverity).AppendChild( (CreateElementForStatInfo Rule) )
                    $failedRule.SetAttribute("Name", $Result_Problem.RuleName) 
                }
            }
            AppendOutputToFileInTargetFolder '</table></div></p>' $findingsHtml_FileName             
        }
    }
}

 #endregion

 #region writing Passed Rules
 AppendOutputToFileInTargetFolder "<p><h3 onclick=""toggleElement('div-passedRules');"" style=""cursor: pointer;"" title=""Toggle expand/collapse""><img style=""width:15px; margin-right: 5px"" src=""$imgNowCollapsed"" alt=""Toggle expand/collapse"" /><span>Passed Rules ($($Result_OKs.Count))</span></h3><div id=""div-passedRules"" style=""display: none""><table>" $findingsHtml_FileName
 $findings_FindingDetails_Top = @"       
        <tr>
        <th class="table-header-passedRule">Severity</th>
        <th class="table-header-passedRule table-col-hide">Case SAP Category</th>
        <th class="table-header-passedRule">Rule</th>
        <th class="table-header-passedRule">Definition</th>
        <th class="table-header-passedRule">Finding</th>
        </tr>
"@   
AppendOutputToFileInTargetFolder $findings_FindingDetails_Top $findingsHtml_FileName 

foreach($Result_Problem in $Result_OKs) {

    $findings_FindingDetails_Row = '<tr>'
    $findings_FindingDetails_Row += "<td>" + $Result_Problem.ProblemSeverity +"</td>"
    $findings_FindingDetails_Row += "<td class='table-col-hide'>" + $Result_Problem.SAPCategories +"</td>"
    $findings_FindingDetails_Row += "<td>" + $Result_Problem.RuleName +"</td>"
    $findings_FindingDetails_Row += "<td>" + $Result_Problem.RuleDesc +"</td>"
    $findings_FindingDetails_Row += "<td>" + $Result_Problem.RuleResult +"</td>"
    $findings_FindingDetails_Row += '</tr>'
    AppendOutputToFileInTargetFolder $findings_FindingDetails_Row $findingsHtml_FileName 
}
$findings_FindingDetails_Bottom = '</table></div></p>'
AppendOutputToFileInTargetFolder $findings_FindingDetails_Bottom $findingsHtml_FileName 
 #endregion
 
#endregion
#region write ScsmEnvInfo
$findings_ScsmEnvInfo = @"
<p>
    <h3 onclick="toggleElement('div-ScsmEnvInfo');" 
        style="cursor: pointer;" 
        title="Toggle expand/collapse"
    ><img style="width:15px; margin-right: 5px" 
            src="$imgNowCollapsed" 
                alt="Toggle expand/collapse" 
    />
    <span>SCSM Environment Info</span>
    </h3><div id="div-ScsmEnvInfo" style="display: none">
        <table>
        <tr>
        <th class="table-header">Info</th>
        <th class="table-header">Value</th>
        </tr>
"@
foreach($smEnvInfoRow in $smEnvInfoRows) {
    $findings_ScsmEnvInfo += "<tr><td>$($smEnvInfoRow.SmEnvInfo)</td><td>$($smEnvInfoRow.SmEnvValue)</td></tr>" 
}

#Check CollectorIssues
$findings.SetAttribute("CollectorHadIssues",0)
$collectorTranscriptFileName = (Get-ChildItem -Path $inputFolder -Filter Transcript*.txt).FullName
$collectorTranscriptContent = [System.IO.File]::ReadAllText($collectorTranscriptFileName)
$collectorIssuesString = ( GetSubstringFromString $collectorTranscriptContent $collectorStartingText $collectorEndingText )
if (-not [string]::IsNullOrWhiteSpace($collectorIssuesString)) {
    $telemetry.CollectorIssues = 1
    $findings_ScsmEnvInfo += "<tr><td>Collector had issues.<br/>This can cause 'false positive' analysis results!</td><td>Check in $(CollectorLink (Get-ChildItem -Path $inputFolder -Filter Transcript*.txt).Name)</td></tr>"
    $findings.SetAttribute("CollectorHadIssues",1)
}

$findings_ScsmEnvInfo+= "</table></div></p>"

AppendOutputToFileInTargetFolder $findings_ScsmEnvInfo $findingsHtml_FileName 
#endregion

#region write AnalysisInfo...

$findings_AnalysisInfo = @"
<p>
    <h3 onclick="toggleElement('div-AnalysisInfo');" style="cursor: pointer" title="Toggle expand/collapse"
    ><img style="width:15px; margin-right: 5px" src="$imgNowCollapsed" alt="Toggle expand/collapse" />
    <span>Diagnostic Tool Info</span>
    </h3><div id='div-AnalysisInfo' style='display: none'>
            <table>
                <tr><th class="table-header">Info</th><th class="table-header">Value</th></tr>
                <tr><td>Collected files</td><td>|CollectorFolder|</td></tr>
               <!-- <tr><td>Collector original zip location</td><td>|CollectorZip|</td></tr> -->
                <tr><td>Diagnostic Version</td><td>|CollectorVersion|</td></tr>
                <tr><td>Diagnostic Date</td><td>|AnalysisDate|</td></tr>
                <tr><td>Run Id</td><td>$( (GetStatInfoRoot).GetAttribute("SmdtRunId") )</td></tr>
                |AnalyzerIssues|
            </table>
        </div>
</p>
"@
$findings_AnalysisInfo = $findings_AnalysisInfo.Replace("|CollectorFolder|",$(CollectorLink '' 'open Collector folder'))
#$findings_AnalysisInfo = $findings_AnalysisInfo.Replace("|CollectorZip|",$collectorResultZipPath)
$findings_AnalysisInfo = $findings_AnalysisInfo.Replace("|CollectorVersion|",$inputVersion)
$findings_AnalysisInfo = $findings_AnalysisInfo.Replace("|AnalysisDate|",$(Get-Date).ToString("yyyy-MM-dd__HH:mm.ss.fff zzz"))
#$findings_AnalysisInfo = $findings_AnalysisInfo.Replace("|AnalyzerVersion|", $analyzerVersion)
#closing the table for $findings_AnalysisInfo has been moved to the ENDING section right after stop-transcript
#endregion

#endregion

#region The ENDING Section

#cd (Split-Path $MyInvocation.MyCommand.Definition)
Write-Host ""
$completionDateTime = (Get-Date).ToString("yyyy-MM-dd__HH.mm.ss.fff")  
Write-Host "$analyzerEndingText $completionDateTime. (local time)"
$script:SQLResultSetCounter = $null

(GetStatInfoRoot).SetAttribute("SmdtRunFinish", (AddTzToDateTimeString $completionDateTime) )
AddTimingsToStatInfo
(GetStatInfoRoot).SetAttribute("SmdtResultZipName", [System.IO.Path]::GetFileName($resultingZipFile_FullPath).Replace( $inputPrefix, $inputPrefix + "_" + $script:RoleFoundAbbr ) )
(GetStatInfoRoot).SetAttribute("SmdtRanAsSigned", (AmIRunningAsSigned) )
(GetStatInfoRoot).SetAttribute("SmdtRunDomainHash", (GetHashOfString (GetComputerDomainObjectGuid).ToString().ToLower()) )

#region Setting SCSM Health Status but only if SMST Eula is accepted
if ((IsSourceScsmWfMgmtServer)) {
    $TargetMS = "localhost"
}
elseif ((IsSourceScsmDwMgmtServer)) {
    $TargetMS = $SMDBInfo.SDKServer_SMDB
}
else {
    $TargetMS = $null
}
if ($TargetMS) {

    #region checking Eula for SCSM.Support.Tools (Smst)
    $SmstEulaAccepted = $false
    $SmstMainCore_MP = Get-SCSMManagementPack -Name SCSM.Support.Tools.Main.Core -ComputerName $TargetMS
    if ($SmstMainCore_MP) {
        $SmstMain_Data = Get-SCSMClassInstance -Class (Get-SCSMClass -Name SCSM.Support.Tools.Main.Data -ComputerName $TargetMS) -ComputerName $TargetMS 
        $findings.SetAttribute("SmstMpbVersion",  $SmstMainCore_MP.Version.ToString())
        $findings.SetAttribute("SmstMpbImportedAt",  $SmstMain_Data.'#TimeAdded'.ToString("yyyy-MM-dd__HH.mm.ss.fff zzz"))    
        if ($SmstMain_Data.EulaApprovedAt) {
            $SmstEulaAccepted = $true
            $findings.SetAttribute("SmstEulaApprovedAt", $SmstMain_Data.EulaApprovedAt.ToString("yyyy-MM-dd__HH.mm.ss.fff zzz"))
        }
    }
    #endregion

    $HealthStatus_MP = Get-SCSMManagementPack -Name SCSM.Support.Tools.HealthStatus.Core -ComputerName $TargetMS
    if ($HealthStatus_MP -and $SmstEulaAccepted) {

        #region mandatory part before doing any update on instances of HealthStatus.WF or HealthStatus.DW
        $HealthStatus_Overall = Get-SCSMClassInstance -Class (Get-SCSMClass -Name SCSM.Support.Tools.HealthStatus.Overall -ComputerName $TargetMS) -ComputerName $TargetMS

        $HealthStatus_WF = Get-SCSMClassInstance -Class (Get-SCSMClass -Name SCSM.Support.Tools.HealthStatus.WF -ComputerName $TargetMS) -ComputerName $TargetMS        
        $HealthStatus_rsClassWF = Get-SCSMRelationshipClass -Name SCSM.Support.Tools.HealthStatus.OverallToWF -ComputerName $TargetMS
        if (-not (Get-SCSMRelationshipInstance -SourceInstance $HealthStatus_Overall -ComputerName $TargetMS | ? { $_.TargetObject -eq $HealthStatus_WF -and (-not $_.IsDeleted) }) ) {
            New-SCRelationshipInstance -RelationshipClass $HealthStatus_rsClassWF -Source $HealthStatus_Overall -Target $HealthStatus_WF -ComputerName $TargetMS
        }

        $HealthStatus_DW = Get-SCSMClassInstance -Class (Get-SCSMClass -Name SCSM.Support.Tools.HealthStatus.DW -ComputerName $TargetMS) -ComputerName $TargetMS
        $HealthStatus_rsClassDW = Get-SCSMRelationshipClass -Name SCSM.Support.Tools.HealthStatus.OverallToDW -ComputerName $TargetMS
        if (-not (Get-SCSMRelationshipInstance -SourceInstance $HealthStatus_Overall -ComputerName $TargetMS | ? { $_.TargetObject -eq $HealthStatus_DW -and (-not $_.IsDeleted) }) ) {
            New-SCRelationshipInstance -RelationshipClass $HealthStatus_rsClassDW -Source $HealthStatus_Overall -Target $HealthStatus_DW -ComputerName $TargetMS
        }
        #endregion

        $enumSeverity_Critical = $HealthStatus_MP.EntityTypes.GetEnumerations("SCSM.Support.Tools.HealthStatus.Enum.Severity.Critical")[0]
        $enumSeverity_Error = $HealthStatus_MP.EntityTypes.GetEnumerations("SCSM.Support.Tools.HealthStatus.Enum.Severity.Error")[0]
        $enumSeverity_Warning = $HealthStatus_MP.EntityTypes.GetEnumerations("SCSM.Support.Tools.HealthStatus.Enum.Severity.Warning")[0]
        $enumSeverity_Unknown = $HealthStatus_MP.EntityTypes.GetEnumerations("SCSM.Support.Tools.HealthStatus.Enum.Severity.Unknown")[0] 
        $enumSeverity_Good = $HealthStatus_MP.EntityTypes.GetEnumerations("SCSM.Support.Tools.HealthStatus.Enum.Severity.Good")[0]
    
        $enumTriggerMethod_Manual = $HealthStatus_MP.EntityTypes.GetEnumerations("SCSM.Support.Tools.HealthStatus.Enum.TriggerMethod.Manual")[0]
        $enumTriggerMethod_Schedule = $HealthStatus_MP.EntityTypes.GetEnumerations("SCSM.Support.Tools.HealthStatus.Enum.TriggerMethod.Schedule")[0]

        $findings_MaxSeverity = $enumSeverity_Good        
        if ($findings_Critical.GetAttribute("Count") -ne "0") { $findings_MaxSeverity = $enumSeverity_Critical }
        elseif ($findings_Error.GetAttribute("Count") -ne "0") { $findings_MaxSeverity = $enumSeverity_Error }
        elseif ($findings_Warning.GetAttribute("Count") -ne "0") { $findings_MaxSeverity = $enumSeverity_Warning }
        elseif ($findings_Unclassified.GetAttribute("Count") -ne "0") { $findings_MaxSeverity = $enumSeverity_Unknown }

        if ((IsSourceScsmWfMgmtServer)) {
            $HealthStatus_WForDW = $HealthStatus_WF
        }
        else {
            $HealthStatus_WForDW = $HealthStatus_DW
        }

        $HealthStatus_WForDW.MaxSeverity = $findings_MaxSeverity.Id 
        $HealthStatus_WForDW.ServerName = $env:COMPUTERNAME
        $HealthStatus_WForDW.ResultingZipFileAtFullPath = $resultingZipFile_FullPath.Replace( $inputPrefix, $inputPrefix + "_" + $script:RoleFoundAbbr )
        $HealthStatus_WForDW.LastRun = [datetime]::Now #(Get-Date)
        $HealthStatus_WForDW.TriggerMethod = if ($Script:MyInvocation.UnboundArguments.Contains("-startedByRule")) { $enumTriggerMethod_Schedule.Id } else { $enumTriggerMethod_Manual.Id }
        $HealthStatus_WForDW.PatchedVersion = $SCSM_Version
        $HealthStatus_WForDW | Update-SCSMClassInstance

        $HealthStatus_Overall.LastChanged = [datetime]::Now
		$HealthStatus_Overall | Update-SCSMClassInstance
        
        $findings.SetAttribute("SmstHealthStatusVersion", $HealthStatus_MP.Version.ToString())
        $findings.SetAttribute("SmstHealthStatus_MaxSeverity", $findings_MaxSeverity.Name.Replace("SCSM.Support.Tools.HealthStatus.Enum.Severity.",""))
    }
}
#endregion

Stop-Transcript | out-null

#Check AnalyzerIssues
$analyzerTranscriptContent = [System.IO.File]::ReadAllText("$resultFolder\Transcript.txt")
$analyzerIssuesString = ( GetSubstringFromString $analyzerTranscriptContent $analyzerStartingText $analyzerEndingText )
if (-not [string]::IsNullOrWhiteSpace($analyzerIssuesString)) {
    $telemetry.AnalyzerIssues = 1
   # $findings_AnalysisInfo = $findings_AnalysisInfo.Replace("|AnalyzerIssues|", "<tr><td>Analyzer had issues!</td><td>Check in $(CollectorLink '../Analyzer/Transcript.txt' 'Transcript.txt')</td></tr>")
    $findings_AnalysisInfo = $findings_AnalysisInfo.Replace("|AnalyzerIssues|", "<tr><td>Analyzer had issues!</td><td>Check in $(AnalyzerLink 'Transcript.txt')</td></tr>")
    $findings.SetAttribute("AnalyzerHadIssues","1")
}
else {
    $findings_AnalysisInfo = $findings_AnalysisInfo.Replace("|AnalyzerIssues|","")
    $findings.SetAttribute("AnalyzerHadIssues","0")
}
AppendOutputToFileInTargetFolder $findings_AnalysisInfo $findingsHtml_FileName 
AppendOutputToFileInTargetFolder '</body></html>' $findingsHtml_FileName  

$readableText = GetFileContentInTargetFolder $findingsHtml_FileName
$encodedBytes = [System.Text.Encoding]::UTF8.GetBytes($readableText)
$encodedText = [System.Convert]::ToBase64String($encodedBytes)
AppendOutputToFileInTargetFolder $encodedText Findings.txt

$ShowTheFindingsPS1Content = GetShowTheFindingsPS1Content
$ShowTheFindingsPS1Content = $ShowTheFindingsPS1Content.Replace("# SMDTSIGN begins here #", "# SIG # Begin signature block")
$ShowTheFindingsPS1Content = $ShowTheFindingsPS1Content.Replace("# SMDTSIGN ends here #",   "# SIG # End signature block")

Set-Content -Path (Join-Path -Path (Split-Path $resultFolder -Parent) -ChildPath $findingsPS1_FileName ) -Value $ShowTheFindingsPS1Content
DeleteFileInTargetFolder $findingsHtml_FileName

#WriteTelemetry
AppendOutputToFileInTargetFolder (GetStatInfo).OuterXml StatInfo.xml
$sentByForStatInfo = "Run"
if ( $Script:MyInvocation.UnboundArguments.Contains("-startedByRule") ) { 
    $sentByForStatInfo = "Rule" 
} 
LogStatInfo (GetStatInfo) $sentByForStatInfo

#$ProgressPreference = 'Continue'
if ($removeCollectorResultZipFile) {
    Remove-Item $collectorResultZipPath
}

if (-not $debugmode) {
if ($compressTheResults) {
    Write-Host "Now compressing..." -ForegroundColor Yellow

    $resultingZipFile_FullPath = $resultingZipFile_FullPath.Replace( $inputPrefix, $inputPrefix + "_" + $script:RoleFoundAbbr )

    if ( $PSVersionTable.PSVersion.Major -lt 4 ) { 
        Compress-ZipFile  (Split-Path $resultFolder -Parent) $resultingZipFile_FullPath 
    }
    else {
        MakeNewZipFile (Split-Path $resultFolder -Parent) $resultingZipFile_FullPath
    } 
   
    Remove-Item -Path (Split-Path $resultFolder -Parent) -Force -Recurse > $null
}
}

#endregion

return $resultingZipFile_FullPath

}
