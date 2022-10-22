function Check_ConnectorStatus() {
$dataRow = GetEmptyResultRow
    $dataRow.RuleName="Connector Status"
    $dataRow.RuleDesc=@"
Enabled connectors should have Status = 'Finished Success'. $(CollectorLink SQL_Connectors.csv)
"@
    $dataRow.RuleResult="Below are the Connectors which are enabled but have NOT completed with success. $(IgnoreRuleIfText) they were executing while Collector was running."
    $dataRow.SAPCategories = "Connector*" 
    $dataRow.ProblemSeverity=[ProblemSeverity]::Warning
    
    $linesIn_SQL_Connectors = ConvertFrom-Csv (GetSanitizedCsv ( GetFileContentInSourceFolder SQL_Connectors.csv) ) 
    $anyConnectorFailed = $false
    foreach($row in $linesIn_SQL_Connectors) {
        if ($row.Enabled -eq 'TRUE' -and $row.Status -ne 'Finished Success') {
            $dataRow.RuleResult += "<li>$($row.Name)</li>"
            $anyConnectorFailed = $true
        }
    }

    if (-not $anyConnectorFailed ) { 
        $dataRow.RuleResult="Connectors have completed successfully."
        $Result_OKs += $dataRow 
    }   
    else {
        $Result_Problems += $dataRow
    } 
 }