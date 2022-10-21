function Check_ScomAgent() {

    $line1 = GetFirstLineThatStartsWith (GetFileContentInSourceFolder AgentMGs.regValues.txt) 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Agent Management Groups\'
    $line2 = GetFirstLineThatStartsWith (GetFileContentInSourceFolder AgentMGs.regValues.txt) 'NetworkName    REG_SZ'
    
    $dataRow = GetEmptyResultRow
    $dataRow.RuleName="SCOM Agent"
    $dataRow.RuleDesc="Scsm mgmt server should never be monitored by SCOM as an 'Agent'. Instead, 'Agentless' monitoring can be used."
    $dataRow.RuleResult="No SCOM Agent found."
    if (IsSourceScsmWfMgmtServer) { $dataRow.SAPCategories = "wf*" }
    if (IsSourceScsmDwMgmtServer) { $dataRow.SAPCategories = "dw*" }     
    $dataRow.ProblemSeverity=[ProblemSeverity]::Critical

    if ($line1.Length -eq 0 -and $line2.Length -eq 0) { $Result_OKs += $dataRow }
    else {        
        $dataRow.RuleResult = "SCOM Agent found in $(CollectorLink AgentMGs.regValues.txt). Search for 'Microsoft Monitoring Agent' in $(GetAnchorForExternal 'https://techcommunity.microsoft.com/t5/System-Center-Blog/Troubleshooting-Service-Manager-work-item-Incident-Change/ba-p/351821' KB)"
        $Result_Problems += $dataRow
    }
}