function Check_WorkflowsMinutesBehind() {
 $tolerance_MinutesBehind = 15

    $dataRow = GetEmptyResultRow
    $dataRow.RuleName="Workflows Minutes Behind"
    $dataRow.RuleDesc=@"
This rule checks if workflows are lagging for more than $tolerance_MinutesBehind minutes. More in this $(GetAnchorForExternal 'https://techcommunity.microsoft.com/t5/system-center-blog/troubleshooting-workflow-performance-and-delays/ba-p/347510' KB) article.
<br/>All WF lagging info is in $(CollectorLink SQL_WorkflowMinutesBehind.csv)
"@
    $dataRow.RuleResult="No workflows are lagging."
    $dataRow.SAPCategories = "wf*" 
    $dataRow.ProblemSeverity=[ProblemSeverity]::Error

    $WfMinutesBehindIsHigh = $true

    $linesIn_SQL_WorkflowMinutesBehind = ConvertFrom-Csv (GetSanitizedCsv ( GetFileContentInSourceFolder SQL_WorkflowMinutesBehind.csv ) ) 
    $max_MinutesBehind = [long]::MaxValue
    [long]::TryParse($linesIn_SQL_WorkflowMinutesBehind[0]."Minutes Behind", [ref] $max_MinutesBehind) | Out-Null
    $WfMinutesBehindIsHigh = ($max_MinutesBehind -gt $tolerance_MinutesBehind)

    if (-not $WfMinutesBehindIsHigh ) { 
        $dataRow.RuleResult += " Max minutes: $max_MinutesBehind"
        $Result_OKs += $dataRow 
    }   
    else {        
        $dataRow.RuleResult = @" 
        Looks like workflows are lagging for more than $max_MinutesBehind minutes. $(IgnoreRuleIfText) if a same 'lagging' rule exists in $(CollectorLink SQL_WorkflowMinutesBehind_Original.csv) with a lower Minutes Behind value.
"@
        $Result_Problems += $dataRow
    } 
}