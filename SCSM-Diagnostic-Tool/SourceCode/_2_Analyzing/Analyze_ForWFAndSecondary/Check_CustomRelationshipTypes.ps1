function Check_CustomRelationshipTypes() {
 $dataRow = GetEmptyResultRow
    $dataRow.RuleName="Custom Relationship Types"
    $dataRow.RuleDesc=@"
    Custom Relationship Types with MaxCardinality=1 Targets should be excluded, if they are really not needed. Otherwise, WFs can lag and Consoles can face slowness. This rule is correlated with the 'ECL row count' rule.
<br/>More detailed info at Appendix section in this $(GetAnchorForExternal 'https://techcommunity.microsoft.com/t5/system-center-blog/troubleshooting-workflow-performance-and-delays/ba-p/347510' 'Doc.')
<br/>Query results are in $(CollectorLink SQL_TroubleshootingWorkflowPerformanceandDelays.csv)
"@
    $dataRow.SAPCategories = "wf*" 

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

    [cData]$eclResult = GetRuleFromAllRules "ECL row count"
    $dataRow.ProblemSeverity= $eclResult.ProblemSeverity

    if ($IncorrectRowcount -eq 0) {
        $dataRow.RuleResult="No problematic Custom Relationship Types found."
        $Result_OKs += $dataRow 
    }
    else {
        $dataRow.RuleResult = "Non-excluded Custom Relationship Types have been found. "
        if ( (RulePassed "ECL row count") ) {
            $dataRow.RuleResult += "However, as the 'ECL row count' rule has passed, this rule will also pass for now. But it's strongly recommended to fix this, before getting into issues. "
            $Result_OKs += $dataRow 
        }
        else {
            $dataRow.RuleResult += "This can be the reason why the ECL table is so big. "
            $Result_Problems += $dataRow
        }
        $dataRow.RuleResult += "Run the below SQL script to fix this issue.<br/>INSERT INTO ExcludedRelatedEntityChangeLog (RelationshipTypeId, TargetTypeId) VALUES<br/> $itemsToInsert"
    }
}