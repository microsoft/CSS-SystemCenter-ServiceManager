function Check_LocalOMSDK_Availability() {

    $localOMSDK_Response =  GetFileContentInSourceFolder Test_LocalOMSDK_Response.txt

    $dataRow = GetEmptyResultRow
    $dataRow.RuleName="SCSM reachable"
    $dataRow.RuleDesc="The local Data Access Service should be reachable by consoles. A simple test result is in $(CollectorLink Test_LocalOMSDK_Response.txt)."
    if (IsSourceAnyScsmMgmtServer) { $dataRow.SAPCategories =  "*"}
    $dataRow.ProblemSeverity=[ProblemSeverity]::Critical

    if ($localOMSDK_Response -eq $null -or $localOMSDK_Response -eq "" -or $localOMSDK_Response.Contains("Exception") ) {
        
        if ( $localOMSDK_Response.Contains("LinkId=117146") ) {
            $dataRow.RuleResult="The evaluation copy of this SCSM installation has expired. Please "
            if (IsSourceScsmDwMgmtServer) {
                $dataRow.RuleResult +="$(GetAnchorForExternal 'https://learn.microsoft.com/en-us/system-center/scsm/release-notes-sm?view=sc-sm-2019#manual-steps-to-activate-data-warehouse-server' 'activate')."
            }
            else {
                $dataRow.RuleResult +="$(GetAnchorForExternal 'https://learn.microsoft.com/en-us/system-center/scsm/sm-license?view=sc-sm-2019' 'activate')."
            }
        }
        else {
            $dataRow.RuleResult="The local OMSDK service responded with error:<br/>$localOMSDK_Response"
        }
        $Result_Problems += $dataRow
    }
    else {
        $dataRow.RuleResult="The local SCSM is reachable."
        $Result_OKs += $dataRow
    }
}