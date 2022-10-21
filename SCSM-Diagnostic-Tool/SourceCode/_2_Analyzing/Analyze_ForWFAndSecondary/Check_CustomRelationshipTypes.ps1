function Check_CustomRelationshipTypes() {
 $dataRow = GetEmptyResultRow
    $dataRow.RuleName="Custom Relationship Types"
    $dataRow.RuleDesc=@"
    Custom Relationship Types with MaxCardinality=1 Targets should be excluded, if they are really not needed. Otherwise, WFs can lag and Consoles can face slowness. Please correlate with 'ECL row count' rule.
<br/>More detailed info in the Appendix of this $(GetAnchorForExternal 'https://techcommunity.microsoft.com/t5/system-center-blog/troubleshooting-workflow-performance-and-delays/ba-p/347510' 'KB article.')
<br/>Query results are in $(CollectorLink SQL_TroubleshootingWorkflowPerformanceandDelays.csv)
"@
    $dataRow.SAPCategories = "wf*" 
    $dataRow.RuleResult = @"
    Non-excluded Custom Relationship Types have been found. Please correlate with 'ECL row count' rule, because ECL table can get bigger because of this issue. It has to be confirmed, if they really need to be excluded. If so, run the below SQL script to fix this issue.
    <br/>$(IgnoreRuleIfText) currently no WF slowness exists, but it's strongly recommended to fix this before getting into issues.<br/>
"@
    $dataRow.ProblemSeverity=[ProblemSeverity]::Error

    $linesIn_SQL_TroubleshootingWorkflowPerformanceandDelays = ConvertFrom-Csv (GetSanitizedCsv ( GetFileContentInSourceFolder SQL_TroubleshootingWorkflowPerformanceandDelays.csv) ) 
    $IncorrectRowcount = 0
    $itemsToInsert = ""
    foreach($row in $linesIn_SQL_TroubleshootingWorkflowPerformanceandDelays) {
        if ($row.CountOfSourcesForSameTarget -eq '!') {
            $itemsToInsert+=",('$($row.RelationshipTypeId)','$($row.RelatedEntityId)')<br/>" 
            $IncorrectRowcount++
        }
    }
    if ($IncorrectRowcount -gt 0) {
        $itemsToInsert = $itemsToInsert.Remove(0,1)
    }

    if ($IncorrectRowcount -eq 0) {
        $dataRow.RuleResult="No incorrect Custom Relationship Types found."
        $Result_OKs += $dataRow 
    }
    else {
        $dataRow.RuleResult += "<br/>INSERT INTO ExcludedRelatedEntityChangeLog (RelationshipTypeId, TargetTypeId) VALUES<br/> $itemsToInsert"
        $Result_Problems += $dataRow
    }
}