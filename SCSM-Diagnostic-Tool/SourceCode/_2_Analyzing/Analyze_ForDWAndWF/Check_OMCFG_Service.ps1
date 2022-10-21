function Check_OMCFG_Service() {

    $linesIn_get_service = ConvertFrom-Csv (GetSanitizedCsv (GetFileContentInSourceFolder get-service.csv)) 
    $OmCfgLine = GetValueFromImportedCsv $linesIn_get_service "name" "OMCFG" "Name"
    $OmCfgService_StartMode = GetValueFromImportedCsv $linesIn_get_service "name" "OMCFG" "StartMode"
    $OmCfgService_State = GetValueFromImportedCsv $linesIn_get_service "name" "OMCFG" "State"   
    
    $dataRow = GetEmptyResultRow
    $dataRow.RuleName="OMCFG Service"
    $dataRow.RuleDesc="System Center Management Configuration Service (OMCFG) must be Running and Automatic started."
    $dataRow.RuleResult="OMCFG is Running and Automatic."    
    if (IsSourceScsmWfMgmtServer) { $dataRow.SAPCategories = "wf*"}
    if (IsSourceScsmDwMgmtServer) { $dataRow.SAPCategories = "dw**" }     
    $dataRow.ProblemSeverity=[ProblemSeverity]::Critical

    if ($OmCfgLine -and $OmCfgService_State -eq "Running" -and $OmCfgService_StartMode -eq "Auto" ) { $Result_OKs += $dataRow }
    else {        
        $dataRow.RuleResult = 'The OMCFG Service is either NOT Running or NOT set as Automatic or is not installed. ' + (CollectorLink get-service.csv)
        $Result_Problems += $dataRow
    }
}