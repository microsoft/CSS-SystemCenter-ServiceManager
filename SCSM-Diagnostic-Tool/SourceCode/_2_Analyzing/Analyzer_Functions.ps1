#region  function definitions added by Analyzer
function GetFileContentInSourceFolder($fileName, $subFolderName) {
    if ($subFolderName) {
        $fileName = Join-Path $subFolderName $fileName    
    }

    Get-Content -Path (Join-Path -Path $inputFolder -ChildPath $fileName) | Out-String    
}
function GetFileNameInSourceFolder($fileName) {
    return Join-Path -Path $inputFolder -ChildPath $fileName
}
<#
function GetFileContentInSourceFolder_WithAbort ($fileName, $subFolderName) {
    $result = GetFileContentInSourceFolder $fileName $subFolderName
   
    if (-not $result) {
        DisplayErrorText "$fileName  does not exist in Collector zip! Aborting ..."
        StopExecuting
    }
    $result
}
#>
function GetLinesFromString_WithTrimOption($inputString, $doTrim) {
    $lines = $inputString.Split( [Environment]::NewLine, [Stringsplitoptions]::RemoveEmptyEntries )
    if (-not $doTrim) { 
        return $lines 
    }
    else {
        [string[]]$result = @()
        foreach( $line in $lines ) {
            $result += $line.Trim()
        }
        return $result
    }
}
function GetLinesFromString($inputString, $doTrim=$true) {
    GetLinesFromString_WithTrimOption $inputString $doTrim    
}
function IsSourceAnyScsmMgmtServer() { #includes WF, Secondary and DW 
    ((IsSourceScsmMgmtServer) -or (IsSourceScsmDwMgmtServer))
}
function IsSourceScsmMgmtServer() {  #includes WF, Secondary, excluding DW
    ((IsSourceScsmWfMgmtServer) -or (IsSourceScsmSecondaryMgmtServer))
}
function IsSourceScsmDwMgmtServer() {
    $ScsmRolesFound.Contains("DW")
}
function IsSourceScsmWfMgmtServer() {
    $ScsmRolesFound.Contains("WF")
}
function IsSourceScsmSecondaryMgmtServer() {
    $ScsmRolesFound.Contains("2ndMS")
}

function HasSourceScsmConsoleInstalled() {
    return $false #todo
}
function HasSourceScsmPortalInstalled() {
    return $false #todo
}

function GetSanitizedCsv($strInput, $getAllNonEmptyLinesBeforeThisValue) {
    if (-not $getAllNonEmptyLinesBeforeThisValue) { $getAllNonEmptyLinesBeforeThisValue = '/*------------------------'}

    $sb = [System.Text.StringBuilder]::new()
    $lines = GetLinesFromString $strInput

    foreach($line in $lines) {
        if ($line.StartsWith($getAllNonEmptyLinesBeforeThisValue)) {break;}
        [void]$sb.AppendLine($line)
    }
    $sb.ToString()
}
function GetValueFromImportedCsv($psObject1, $columnNameToSearchIn, $valueToSearch, $columnNameWithValueToReturn) {
#this is just a helper function to filter a single object from a list based on equality and return only the first one.
#it returns the same like:   ($psObject1 | ? { $_.<$columnNameToSearchIn> -eq <$valueToSearch> } | Select-Object <$columnNameWithValueToReturn> -First 1 ).<$columnNameWithValueToReturn> 

    foreach($row in $psObject1.GetEnumerator()) {
       
            if ( ($row | Select-Object -ExpandProperty $columnNameToSearchIn) -eq $valueToSearch) {
                $row | Select-Object -ExpandProperty $columnNameWithValueToReturn
                break
            }   
    }
}
function GetFirstLineThatStartsWith($strInput, $valueToSearch, $doTrim=$true) {
    foreach($line in (GetLinesFromString $strInput $doTrim)) {        
        if ($line.StartsWith($valueToSearch,[System.StringComparison]::InvariantCultureIgnoreCase)) { $line;  break; }
    }
}
function GetFirstLineThatIsEqualTo($strInput, $valueToSearch) {
    foreach($line in (GetLinesFromString $strInput)) {        
        if ($line.Equals($valueToSearch,[System.StringComparison]::InvariantCultureIgnoreCase)) { $line;  break; }
    }
}
function GetFirstLineThatContains($strInput, $valueToSearch) {
    foreach($line in (GetLinesFromString $strInput)) {        
        if ( $line.ToLower().Contains($valueToSearch.ToLower()) ) { $line;  break; }
    }
}
function GetFirstLine($strInput) {
    if ($strInput.Length -eq 0) { $strInput;return; }
    [string[]]$tmp = GetLinesFromString $strInput
    $tmp[0]
}
function GetSubstringFromString([string]$content, [string]$startingText, [string]$endingText, [bool]$includeStartingText=$false, [bool]$includeEndingText=$false) {

    if ([string]::IsNullOrWhiteSpace($content)) { return ""; }
    if ([string]::IsNullOrWhiteSpace($startingText)) { return ""; }
    if ([string]::IsNullOrWhiteSpace($endingText)) { return ""; }

    $startingLoc = $content.IndexOf($startingText)
    if ($startingLoc -eq -1) { return ""; }
    if (-not $includeStartingText) { $startingLoc += $startingText.Length }

    $endingLoc = $content.IndexOf($endingText)
    if ($endingLoc -eq -1) { return ""; }
    if ($includeEndingText) { $endingLoc += $endingText.Length }

    $distance = $endingLoc - $startingLoc
    if ($distance -lt 0) { return ""; }

    $content.Substring($startingLoc, $distance)    
}

class cProblemCategory
{
    [ValidateNotNullOrEmpty()][string]$Name
    [ValidateNotNullOrEmpty()][string]$DisplayName
    [cProblemCategory]$Parent

    cProblemCategory(
        [string]$Name,
        [string]$DisplayName,
        [cProblemCategory]$Parent
    ){
        $this.Name = $Name
        $this.DisplayName = $DisplayName
        $this.Parent = $Parent
    }

    [string]ToString(){
        return ("{0}" -f $this.DisplayName)
    }
}

class cSAPCategoryHelper
{
    static [cProblemCategory[]]$SAPCategoryList

    static [cProblemCategory[]]GetSAPCategory($categoryName) {
        #return  $Global:SAPCategories.Where( { $_.Name -like $categoryName } )
        return  [cSAPCategoryHelper]::SAPCategoryList.Where( { $_.Name -like $categoryName } )
    }
    static [cProblemCategory[]]GetSAPCategory_ByDisplayName($categoryDisplayName) {
        #return  $Global:SAPCategories.Where( { $_.DisplayName -like $categoryDisplayName } )
        return  [cSAPCategoryHelper]::SAPCategoryList.Where( { $_.DisplayName -like $categoryDisplayName } )
    }
}
<#
[Flags()] enum ProblemCategory { # todo: absolete, delete
    Console = 1
    Authoring = 2
    Connectors = 4
    DWAndReporting = 8
    Portal = 16
    SMComponents = 32
    SMConfigurationAndPerformance = 64
    SetupAndDisasterRecovery = 128
    Workflows = 256
    Unclassified = 512 
}
#>
[Flags()] enum ProblemSeverity { 
    Critical = 1
    Error = 2
    Warning = 4    
    Unclassified = 1024 
}
class cData
{
    [string]$RuleName
    [string]$RuleDesc
    [string]$RuleResult
  #  [ProblemCategory]$ProblemCategory  # todo: absolete, delete
    [ProblemSeverity]$ProblemSeverity

    [cProblemCategory[]]$ProblemCategories

    cData(){
        $this | Add-Member -Name SAPCategories -MemberType ScriptProperty -Value {    # This is the getter
           
            $result = [string]::Empty
            foreach($SAPCategory in $this.ProblemCategories) {
                $result += "<li>$SAPCategory</li>"
            }
            return $result

        } -SecondValue {                                                              # This is the setter
            param([string[]]$valueList)
            
            foreach($value in $valueList) {
                $tmp = [cSAPCategoryHelper]::GetSAPCategory_ByDisplayName($value)
                if ($tmp.Length -eq 0) {
                    $tmp = [cSAPCategoryHelper]::GetSAPCategory($value)
                }
                if ($tmp.Length -eq 0) {
                    $tmp =  [cProblemCategory]::new("#UNDEFINED_SAP#","#UNDEFINED_SAP#",$null)
                }                
                $this.ProblemCategories +=  $tmp                
            }

        } -Force
    }
}
function GetEmptyResultRow() {

    return [cData]$dataRow = New-Object cData -Property @{
        RuleName=""
        RuleDesc=""
        RuleResult=""
    #    ProblemCategory=[ProblemCategory]::Unclassified  # todo: absolete, delete
        ProblemSeverity=[ProblemSeverity]::Unclassified

        ProblemCategories=$null
    }
}
function GetEmptySmEnvRow() {
    return [pscustomobject]$smEnvRow = [pscustomobject]@{SmEnvInfo="";SmEnvValue="";}
}
<#
function StopExecuting() {
    WriteTelemetry
    CleanUpTempFolders
    Read-Host " "
    Exit
}
#>
function DisplayErrorText($errorString) {
    Write-Host -ForegroundColor $errorForegroundColor -BackgroundColor $errorBackgroundColor $errorString
}
function CleanUpTempFolders() {   #todo  
    try {  Stop-Transcript | out-null } catch {}
   # if ($resultFolder -ne $null) { Remove-Item $resultFolder -Recurse }
}
function CollectorLink( [string]$tagUrl, [string]$tagDisplayName ) {
    if ([string]::IsNullOrEmpty($tagDisplayName.Trim())) {
        $tagDisplayName = $tagUrl
    }
    $result = GetAnchorForCollector $tagUrl $tagDisplayName
    $result
}
function GetAnchorForCollector([string]$tagUrl, [string]$tagDisplayName) {
    if ($useProtocolHandler_OpenDefAppByFileExt) {
         "<a href=""#"" onclick=""javascript: window.open('OpenDefAppByFileExt:'+getCollectorUrl()+'/$tagUrl','_blank');return false;"">$tagDisplayName</a>"
    }
    else {
         "<a href=""#"" onclick=""javascript: window.open(''+getCollectorUrl()+'/$tagUrl','_blank');return false;"">$tagDisplayName</a>"
    }
}
function AnalyzerLink( [string]$tagUrl, [string]$tagDisplayName ) {
    if ([string]::IsNullOrEmpty($tagDisplayName.Trim())) {
        $tagDisplayName = $tagUrl
    }
    $result = GetAnchorForAnalyzer $tagUrl $tagDisplayName
    $result
}
function GetAnchorForAnalyzer([string]$tagUrl, [string]$tagDisplayName) {
    if ($useProtocolHandler_OpenDefAppByFileExt) {
         "<a href=""#"" onclick=""javascript: window.open('OpenDefAppByFileExt:'+getAnalyzerUrl()+'/$tagUrl','_blank');return false;"">$tagDisplayName</a>"
    }
    else {
         "<a href=""#"" onclick=""javascript: window.open(''+getAnalyzerUrl()+'/$tagUrl','_blank');return false;"">$tagDisplayName</a>"
    }
}
function GetAnchorForExternal([string]$tagUrl, [string]$tagDisplayName) {
    if ([string]::IsNullOrEmpty($tagDisplayName.Trim())) {
        $tagDisplayName = $tagUrl
    }
    "<a target='_blank' href='$tagUrl'>$tagDisplayName</a>"
}
function IgnoreRuleIfText() {
    '<b>Ignore this rule if</b>'
}

#the properties sequence in class Telemetry is VERY IMPORTANT !! Don't change/delete them. If new data is needed, just add to the end.
class Telemetry {
    [int]$IssuesFound    #calculated in WriteTelemetry()
    [string]$User	#set in GetEmptyTelemetryRow()
    [string]$AnalyzerVersion	#set in WriteTelemetry()
    [string]$AnalysisID	#set as the Collector file name
    [string]$Start_DateTimeUtc	#set in GetEmptyTelemetryRow() and then again later when not aborted and rules starts running
    [int]$Start_Method #obsolete
    [int]$End_Result #calculated in WriteTelemetry()
    [string]$End_DateTimeUtc	#set in WriteTelemetry(), means either the time of abortion or successful completion
    [string]$Abort_Reason	#obsolete
    [string]$MainComponent	#set
    [int]$HasConsole #will be set later if Collector brings in Console specific data, otherwise default 0	 #todo
    [int]$HasPortal	#will be set later if Collector brings in Portal specific data, otherwise default 0 #todo
    [int]$DurationInSeconds	#calculated in WriteTelemetry()
    [string]$CollectorVersion	#set in WriteTelemetry()
    [int]$CriticalCount	#set in WriteTelemetry()
    [int]$ErrorCount	#set in WriteTelemetry()
    [int]$WarningCount	#set in WriteTelemetry()
    [int]$AnalyzerIssues	#set just after stopping transcript
    [int]$CollectorIssues #set, just before writing the Analysis Info section
    [string]$SMFullVersion #set in WriteTelemetry()
    [int]$CollectorVersionOld #obsolete
    [int]$IsOneDriveEnabled #obsolete
    [int]$AnalyzerStartedFromOneDrive #obsolete
    [int]$IsProtocolHandlerInstalled  #set in WriteTelemetry()
}
function GetEmptyTelemetryRow() {

    return [Telemetry]$TelemetryRow = New-Object Telemetry -Property @{
        Start_DateTimeUtc = ((Get-Date).ToUniversalTime())
       # User = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name  #todo
    }
}
function IsOneDriveEnabled([bool]$showText=$false) {
    return $false #obsolete   
}
function DoesAnalyzerShortcutExist([bool]$showText=$false) {
    return $false #obsolete
}
function WriteTelemetry() {
    
    #region Write computed telemetry properties
        $telemetry.AnalyzerVersion = $analyzerVersion
        $telemetry.End_Result = if ( $telemetry.Abort_Reason -gt 0 ) { 1 } 
        $telemetry.End_DateTimeUtc = (Get-Date).ToUniversalTime()
        $telemetry.DurationInSeconds = ([datetime]$telemetry.End_DateTimeUtc).Subtract(([datetime]$telemetry.Start_DateTimeUtc)).TotalSeconds
        $telemetry.CollectorVersion = $inputVersion

        foreach($Result_Problem in $Result_Problems) {
            if ($Result_Problem.ProblemSeverity -eq [ProblemSeverity]::Critical) {
                $telemetry.CriticalCount++ 
            }
            elseif ($Result_Problem.ProblemSeverity -eq [ProblemSeverity]::Error) {
                $telemetry.ErrorCount++ 
            }
            elseif ($Result_Problem.ProblemSeverity -eq [ProblemSeverity]::Warning) { 
                $telemetry.WarningCount++ 
            }
            else { $telemetry.CriticalCount++ } #=>  [ProblemSeverity]::Unclassified
        }
        $telemetry.IssuesFound = if ($telemetry.CriticalCount + $telemetry.ErrorCount + $telemetry.WarningCount -eq 0) {0} else {1}
        $telemetry.SMFullVersion = $SCSM_Version  
        $telemetry.Start_DateTimeUtc = ([datetime]$telemetry.Start_DateTimeUtc).ToString("yyyy-MM-dd HH:mm:ss") #better to read in Excel
        $telemetry.End_DateTimeUtc = ([datetime]$telemetry.End_DateTimeUtc).ToString("yyyy-MM-dd HH:mm:ss") #better to read in Excel
        #$telemetry.IsOneDriveEnabled = if ( IsOneDriveEnabled ) { 1 } else { 0 }  #obsolete
        $telemetry.IsProtocolHandlerInstalled = if ( $useProtocolHandler_OpenDefAppByFileExt ) { 1 } else { 0 }

    #endregion
    $newTelemetryContent = [string]::Join("`t",  $telemetry.PSObject.Properties.Value )

    if (-not $debugmode) {
        $telemetryFilePath = "" #todo
    } else {
        $telemetryFilePath = "" #todo [System.IO.Path]::Combine($currentPS1Path, "Extra\Telemetry")
    }

    do {
        $newTelemetryFileName = [System.IO.Path]::Combine( $telemetryFilePath , "run_"+ ((Get-Date).ToUniversalTime().ToString("yyyy-MM-dd__HH.mm.ss.fff")+".txt"))
    } while (Test-Path $newTelemetryFileName)

    # Add-Content -Path $newTelemetryFileName -Value $newTelemetryContent #todo
}
function ParseSqlDate([string]$dateString) {
    [datetime]$result = [datetime]::ParseExact($dateString, "$($sourceDateTimeFormat.ShortDatePattern) $($sourceDateTimeFormat.LongTimePattern)" ,$null)
    $result
}
function Is4PartVersionValid([string]$inputStr) {
$result = $true
    try {
        [Int32[]]$inputVersionParts = $inputStr.Split(".")
        if ($inputVersionParts.Count -ne 4) {
            $result = $false
        } 
        if (($inputVersionParts | Measure-Object -Sum).Sum -eq 0) {
            $result = $false
        } 
    }
    catch {
        $result = $false
    }
$result
}

function GetRuleFromArray([string]$ruleName, [cData[]]$dataRows) {
    foreach($dataRow in $dataRows) {
        if ($dataRow.RuleName -eq $ruleName) {
            return $dataRow
        }
    }
    return $null;
}

function GetRuleFromPassedRules([string]$ruleName) {
    GetRuleFromArray $ruleName $Result_OKs
}
function GetRuleFromFailedRules([string]$ruleName) {
    GetRuleFromArray $ruleName $Result_Problems
}

function RulePassed([string]$ruleName) {
    if ( (GetRuleFromPassedRules $ruleName) ) {
        return $true
    }
    elseif ( (GetRuleFromFailedRules $ruleName) ) {
        return $false
    }
    else {
        return $null # Rule has not run yet or such rule is not defined
    }
}

function DoesFileExistInSourceFolder($fileName, $subFolderName) {
    if ($subFolderName) {
        $fileName = Join-Path $subFolderName $fileName    
    }

    Test-Path -Path (Join-Path -Path $inputFolder -ChildPath $fileName)    
}


#endregion
