function Check_ConnectedSDKUsers() {
    $linesIn_ConnectedSDKUsers = GetLinesFromString (GetFileContentInSourceFolder ConnectedSDKUsers.txt) 
    $actualSDKClientConnections = [int]($linesIn_ConnectedSDKUsers[3])

    $maxAllowedSDKClientConnectionsPerSDKService = 30

    $dataRow = GetEmptyResultRow
    $dataRow.RuleName="Client connections to SDK Service"
    $dataRow.RuleDesc="Ideally the OMSDK service should not handle more than $maxAllowedSDKClientConnectionsPerSDKService SDK Client connections. An SDK Client can be Console, Portal, PowerShell, Runbook etc. $(CollectorLink ConnectedSDKUsers.txt)"
    $dataRow.RuleResult="Actual SDK Client connections count: $($actualSDKClientConnections.ToString())"
    if (IsSourceScsmMgmtServer) { $dataRow.SAPCategories = "s*\*perf*" , "wf*\*perf*" }
    if (IsSourceScsmDwMgmtServer) { $dataRow.SAPCategories ="dw*\*perf*"} 
    
    $dataRow.ProblemSeverity=[ProblemSeverity]::Warning

    if ( $actualSDKClientConnections -le $maxAllowedSDKClientConnectionsPerSDKService ) { $Result_OKs += $dataRow }
    else {        
        $dataRow.RuleResult += "<br/>Can be investigated further in $(CollectorLink netstat_abof.txt).<br/>$(IgnoreRuleIfText) if Performance of the SDK Service is NOT the main issue."
        $Result_Problems += $dataRow
    }
}
