function Check_ScomAgent() {

    $line1 = GetFirstLineThatStartsWith (GetFileContentInSourceFolder AgentMGs.regValues.txt) 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Agent Management Groups\'
    $line2 = GetFirstLineThatStartsWith (GetFileContentInSourceFolder AgentMGs.regValues.txt) 'NetworkName    REG_SZ'
    
    $dataRow = GetEmptyResultRow
    $dataRow.RuleName="Monitored by SCOM"
    $dataRow.RuleDesc="Primary and DW SCSM mgmt servers should never be monitored by SCOM as an 'Agent'. Instead, 'Agentless' monitoring can be used, as mentioned in $(GetAnchorForExternal 'https://www.microsoft.com/en-us/download/details.aspx?id=101605' 'Management Pack guide for System Center Service Manger.pdf')."
    $dataRow.RuleResult="Good. Not monitored by SCOM as an 'Agent'."
    if (IsSourceScsmWfMgmtServer) { $dataRow.SAPCategories = "wf*" }
    if (IsSourceScsmDwMgmtServer) { $dataRow.SAPCategories = "dw*" }     
    $dataRow.ProblemSeverity=[ProblemSeverity]::Critical

    if ($line1.Length -eq 0 -and $line2.Length -eq 0) { $Result_OKs += $dataRow }
    else {        
        $dataRow.RuleResult = "As seen in $(CollectorLink AgentMGs.regValues.txt), looks like that this mgmt server is monitored by SCOM as an 'Agent'. For all details, search in $(GetAnchorForExternal 'https://techcommunity.microsoft.com/t5/System-Center-Blog/Troubleshooting-Service-Manager-work-item-Incident-Change/ba-p/351821' 'this article') for 'Microsoft Monitoring Agent'"
        $Result_Problems += $dataRow
    }
}