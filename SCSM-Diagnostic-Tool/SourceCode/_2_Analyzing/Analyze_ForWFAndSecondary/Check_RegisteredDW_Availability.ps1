function Check_RegisteredDW_Availability() {

    $registeredDwSDK =  GetFileContentInSourceFolder Test_RegisteredDW_SDK.txt

    if ($registeredDwSDK -eq $null) { # no DW registered, therefore no need to run this rule.
        return
    }

    $dataRow = GetEmptyResultRow
    $dataRow.RuleName="DW availability"
    $dataRow.RuleDesc="The registered Data Warehouse should be responsive. A simple test result is in $(CollectorLink Test_RegisteredDW_SDK.txt)."
    if (IsSourceAnyScsmMgmtServer) { $dataRow.SAPCategories =  "dw\*"}
    $dataRow.ProblemSeverity=[ProblemSeverity]::Critical

    if ( $registeredDwSDK.Contains("Exception") ) {
        
        if ( $registeredDwSDK.Contains("LinkId=117146") ) {
            $dataRow.RuleResult="The evaluation copy of the DW has expired. Please $(GetAnchorForExternal 'https://learn.microsoft.com/en-us/system-center/scsm/release-notes-sm?view=sc-sm-2019#manual-steps-to-activate-data-warehouse-server' 'activate')."
        }
        else {
            $dataRow.RuleResult="The DW responded with error:<br/>$registeredDwSDK"
        }
        $Result_Problems += $dataRow
    }
    else {
        $dataRow.RuleResult="The DW responded normally."
        $Result_OKs += $dataRow
    }
}