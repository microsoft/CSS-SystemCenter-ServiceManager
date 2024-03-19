function Check_ObjectTemplates_WithNoLocalizations() {

    $dataRow = GetEmptyResultRow
    $dataRow.RuleName="IR and SR Templates with no localizations"
    $dataRow.RuleDesc=@"
This rule checks if Templates (only if based on Incident or Service Request) exist that do not have any localized Name or Description value. This would crash the Console (bug 936430) when attempting to create a new Exchange Connector or when opening an existing one.
"@
    $dataRow.RuleResult="No such templates found."
    $dataRow.SAPCategories = "Console" 

    $connectors = ConvertFrom-Csv (GetSanitizedCsv (GetFileContentInSourceFolder SQL_Connectors.csv) )
    $exchangeConnectors = $connectors | ? { $_.'Data Provider Name' -eq "Exchange Connector"}
    if ($exchangeConnectors.Count -eq 0) {
        $dataRow.ProblemSeverity=[ProblemSeverity]::Warning
    }
    else {
        $dataRow.ProblemSeverity=[ProblemSeverity]::Error
    }

    $linesIn_SQL_ObjectTemplates_WithMissingLocalizations = ConvertFrom-Csv (GetSanitizedCsv ( GetFileContentInSourceFolder SQL_ObjectTemplates_WithMissingLocalizations.csv ) ) 

    if ( $linesIn_SQL_ObjectTemplates_WithMissingLocalizations -eq $null) { 
        $Result_OKs += $dataRow 
    }   
    else {        
        $dataRow.RuleResult = @" 
        Looks like problematic templates found. To resolve this issue, please do the following steps:
<br/>	1. Open $(CollectorLink SQL_ObjectTemplates_WithMissingLocalizations.csv).
<br/>	2. Copy the value of the 1st column "Template Name to be edited".
<br/>	3. Open the SM console and navigate to Library/Templates.
<br/>	4. Find/Filter the template (like "Template.59d3859b0aca4bd0aec5f64e3b6059e2") and click Properties.
<br/>	5. Make a modification in the Name or Description fields.
<br/>	6. Uncheck the "When I click OK, open the template form" checkbox at the very end. Don't worry if you forget to uncheck.
<br/>	7. Click the OK button.
<br/>   Repeat steps 2-7 for each row in $(CollectorLink SQL_ObjectTemplates_WithMissingLocalizations.csv).
"@

        if ($exchangeConnectors.Count -eq 0) {
             $dataRow.RuleResult += @" 
<br/>        
<br/>   $(IgnoreRuleIfText) you do not plan to create an Exchange Connector. However, it is strongly recommended to do the steps mentioned above, in order to avoid problems in the future.
"@
        }
        $Result_Problems += $dataRow
    } 
}