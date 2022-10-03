function Check_HealthService() {

    $linesIn_get_service = ConvertFrom-Csv (GetSanitizedCsv (GetFileContentInSourceFolder get-service.csv)) 
    $HsLine = GetValueFromImportedCsv $linesIn_get_service "name" "HealthService" "Name"
    $HsService_StartMode = GetValueFromImportedCsv $linesIn_get_service "name" "HealthService" "StartMode"
    $HsService_State = GetValueFromImportedCsv $linesIn_get_service "name" "HealthService" "State"   
    
    $dataRow = GetEmptyResultRow
    $dataRow.RuleName="HealthService"
    $dataRow.RuleDesc="Microsoft Monitoring Agent (HealthService) must be Running and Automatic started."
    $dataRow.RuleResult="HealthService is Running and Automatic."    
    if (IsSourceScsmWfMgmtServer) { $dataRow.SAPCategories = "wf*" }
    if (IsSourceScsmDwMgmtServer) { $dataRow.SAPCategories = "dw*" }     
    $dataRow.ProblemSeverity=[ProblemSeverity]::Critical

    if ($HsLine -and $HsService_State -eq "Running" -and $HsService_StartMode -eq "Auto" ) { $Result_OKs += $dataRow }
    else {        
        $dataRow.RuleResult = 'The HealthService is either NOT Running or NOT set as Automatic or is not installed. ' + (CollectorLink get-service.csv)
        $Result_Problems += $dataRow
    }
}