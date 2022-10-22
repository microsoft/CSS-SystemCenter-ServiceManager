function Check_MgmtServerHW() {
    $cpuCount = 0
    $EnvVars1 = Import-Csv (GetFileNameInSourceFolder EnvVars.csv)
    [decimal]$cpuCount = GetValueFromImportedCsv $EnvVars1 "Key" "NUMBER_OF_PROCESSORS" "Value"

    $totalRamInMB = 0
    [decimal]$totalRamInMB = GetFileContentInSourceFolder TotalRAM.txt

    $dataRow = GetEmptyResultRow
    $dataRow.RuleName="Mgmt Server HW"
    $dataRow.RuleDesc="Must have min: 4 CPU, 8000 MB RAM"
    $dataRow.RuleResult="Actual: $cpuCount CPU, $totalRamInMB MB RAM" 
    if (IsSourceScsmWfMgmtServer) { $dataRow.SAPCategories =  "wf\*perf*", "s*\*perf*"}
    if (IsSourceScsmDwMgmtServer) { $dataRow.SAPCategories = "dw\*" } 
    if (IsSourceScsmSecondaryMgmtServer) { $dataRow.SAPCategories =  "s*\*perf*"}
    $dataRow.ProblemSeverity=[ProblemSeverity]::Critical

    if ($cpuCount -ge 4  -and  $totalRamInMB -ge 8000) { $Result_OKs += $dataRow }
    else {        
        $dataRow.RuleResult += " $(GetAnchorForExternal 'https://docs.microsoft.com/en-us/system-center/scsm/system-requirements?view=sc-sm-2019#hardware' KB)"        
        $Result_Problems += $dataRow
    }
}