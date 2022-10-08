function Check_OMSDK_Service() {
    $linesIn_get_service = ConvertFrom-Csv (GetSanitizedCsv (GetFileContentInSourceFolder get-service.csv)) 
    $OmSdkLine = GetValueFromImportedCsv $linesIn_get_service "name" "OMSDK" "Name"
    $OmSdkService_StartMode = GetValueFromImportedCsv $linesIn_get_service "name" "OMSDK" "StartMode"
    $OmSdkService_State = GetValueFromImportedCsv $linesIn_get_service "name" "OMSDK" "State"   
    
    $dataRow = GetEmptyResultRow
    $dataRow.RuleName="OMSDK Service"
    $dataRow.RuleDesc="System Center Data Access Service (OMSDK) must be Running and Automatic started."
    $dataRow.RuleResult="OMSDK is Running and Automatic."    
    if (IsSourceScsmWfMgmtServer) { $dataRow.SAPCategories = "s*" , "wf*" }
    if (IsSourceScsmDwMgmtServer) { $dataRow.SAPCategories = "dw*" } 
    if (IsSourceScsmSecondaryMgmtServer) { $dataRow.SAPCategories = "s*"}   
    $dataRow.ProblemSeverity=[ProblemSeverity]::Critical

    if ($OmSdkLine -and $OmSdkService_State -eq "Running" -and $OmSdkService_StartMode -eq "Auto" ) { $Result_OKs += $dataRow }
    else {        
        $dataRow.RuleResult = 'The OMSDK Service is either NOT Running or NOT set as Automatic or is not installed. ' + (CollectorLink get-service.csv)
        $Result_Problems += $dataRow
    }
}