function Check_SQLServerHW() {
    $cpuCount = 0
    $linesIn_SQL_Info = GetLinesFromString (GetFileContentInSourceFolder SQL_Info.csv)
    $linesIn_SQL_Info = $linesIn_SQL_Info | Select-String -Pattern '"Product",' -SimpleMatch -Context 0,1  | Out-String -Width 8000 
    $linesIn_SQL_Info = $linesIn_SQL_Info.Replace(">","")
    $linesIn_SQL_Info = GetLinesFromString $linesIn_SQL_Info 
    $SQL_Info = ConvertFrom-Csv $linesIn_SQL_Info 
    [decimal]$cpuCount = $SQL_Info.Processors

    $totalRamInMB = 0
    [decimal]$totalRamInMB = $SQL_Info.PhysicalMemory

    $linesIn_SQL_sp_configure = ConvertFrom-Csv  ( GetSanitizedCsv  ( GetFileContentInSourceFolder SQL_sp_configure.csv ) '"xp_cmdshell' ) 
    [decimal]$totalRamInMB_Configured = GetValueFromImportedCsv $linesIn_SQL_sp_configure "name" "max server memory (MB)" "run_value"

    #if user was not sysadmin then "max server memory (MB)" is 0, therefore we'll ignore it
    if ($totalRamInMB_Configured -ne 0 -and ($totalRamInMB_Configured -lt $totalRamInMB) ) { $totalRamInMB = $totalRamInMB_Configured}

    $dataRow = GetEmptyResultRow
    $dataRow.RuleName="SQL Server HW"
    $dataRow.RuleDesc="Must have min: 8 CPU, 8000 MB RAM"
    $dataRow.RuleResult="Actual: $cpuCount CPU, $totalRamInMB MB RAM"
    if (IsSourceScsmWfMgmtServer) { $dataRow.SAPCategories =  "wf\*perf*", "s*\*perf*"}
    if (IsSourceScsmDwMgmtServer) { $dataRow.SAPCategories = "dw\*" } 
    if (IsSourceScsmSecondaryMgmtServer) { $dataRow.SAPCategories =  "s*\*perf*"} 
    $dataRow.ProblemSeverity=[ProblemSeverity]::Critical

    if ($cpuCount -ge 8  -and  $totalRamInMB -ge 8000) { $Result_OKs += $dataRow }
    else {        
        $dataRow.RuleResult += " $(GetAnchorForExternal 'https://docs.microsoft.com/en-us/system-center/scsm/system-requirements?view=sc-sm-2019#hardware' KB)"        
        $Result_Problems += $dataRow
    }
}