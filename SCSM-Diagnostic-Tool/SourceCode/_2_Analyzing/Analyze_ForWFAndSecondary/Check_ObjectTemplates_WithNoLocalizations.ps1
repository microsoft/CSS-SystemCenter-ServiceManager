function Check_ObjectTemplates_WithNoLocalizations() {

    $dataRow = GetEmptyResultRow
    $dataRow.RuleName="Templates with no localizations"
    $dataRow.RuleDesc=@"
This rule checks if Templates exist that do not have any localized string. This would cause Connector (e.g. Exchange Connector) Wizard to crash the Console (bug 936430).
"@
    $dataRow.RuleResult="No such templates found."
    $dataRow.SAPCategories = "Console" 
    $dataRow.ProblemSeverity=[ProblemSeverity]::Error

    $linesIn_SQL_ObjectTemplates_WithMissingLocalizations = ConvertFrom-Csv (GetSanitizedCsv ( GetFileContentInSourceFolder SQL_ObjectTemplates_WithMissingLocalizations.csv ) ) 

    if ( $linesIn_SQL_ObjectTemplates_WithMissingLocalizations -eq $null) { 
        $Result_OKs += $dataRow 
    }   
    else {        
        $dataRow.RuleResult = @" 
        Looks like problematic templates found. Please check in $(CollectorLink SQL_ObjectTemplates_WithMissingLocalizations.csv). $(IgnoreRuleIfText) no Exchange Connector exists. However, it is strongly suggested to add localized string values to these templates to avoid problems in the future.
"@
        $Result_Problems += $dataRow
    } 
}