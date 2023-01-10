function Check_MPSyncJobConnectivity() {
$linesIn_ForMPSyncJob_Telnet_FromDW_ToSMSDK = GetFileContentInSourceFolder ForMPSyncJob_Telnet_FromDW_ToSMSDK.txt 
 $canMPSyncJobConnect = (GetLinesFromString ($linesIn_ForMPSyncJob_Telnet_FromDW_ToSMSDK)) -like 'TcpTestSucceeded*:*True'

    $dataRow = GetEmptyResultRow
    $dataRow.RuleName="MPSyncJob Connectivity"
    $dataRow.RuleDesc="The MPSyncJob must be able to connect to the designated (mostly Primary) Management Server's OMSDK service. $(CollectorLink 'ForMPSyncJob_Telnet_FromDW_ToSMSDK.txt' Telnet)"
    $dataRow.RuleResult="Network connection test succeeded."
    $dataRow.SAPCategories = "dw*" 
    $dataRow.ProblemSeverity=[ProblemSeverity]::Error

    if ( $canMPSyncJobConnect ) { $Result_OKs += $dataRow }   
    else {        
        $dataRow.RuleResult = "Looks like TCP port 5724 test failed. Check in $(CollectorLink 'ForMPSyncJob_Telnet_FromDW_ToSMSDK.txt'). $(IgnoreRuleIfText) MPSyncJob is not needed, maybe like in FIM/MIM."
        $Result_Problems += $dataRow
    }    
}