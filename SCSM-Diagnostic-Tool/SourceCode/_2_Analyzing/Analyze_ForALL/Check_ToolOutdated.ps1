function Check_ToolOutdated() {

    $toolSelfUpdateDays = 14

    $dataRow = GetEmptyResultRow
    $dataRow.RuleName="Tool up-to-date"
    $dataRow.RuleDesc="This SCSM Diagnostic Tool is designed to update itself with new Rules. If for any reason (no internet etc.) it couldn't self-update in the last $toolSelfUpdateDays days, then there's probably a newer version at $(GetAnchorForExternal 'https://aka.ms/scsm-diagnostic-tool')."
    $dataRow.ProblemSeverity=[ProblemSeverity]::Warning
    
    $scriptLastUpdatedNdaysAgo = ( (Get-Date) - ((Get-ChildItem -Path $scriptFilePath).LastWriteTime) ).Days
    
    if ($scriptLastUpdatedNdaysAgo -gt $toolSelfUpdateDays) {
        $dataRow.RuleResult = "Please replace '$scriptFilePath' with the latest version from $(GetAnchorForExternal 'https://aka.ms/scsm-diagnostic-tool'). <br/>$(IgnoreRuleIfText) explicitly asked by Microsoft Support to run this specific version."
        $Result_Problems += $dataRow
    }
    else {
        $dataRow.RuleResult += "This tool was updated $scriptLastUpdatedNdaysAgo days ago."
        $Result_OKs += $dataRow 
    }
   
}

