function Check_SqlCLRonRegisteredDWSql() {
# check if 'clr enabled' is 1 on the registered DW SQL instance

    $registeredDwInfo = ConvertFrom-Csv ( GetSanitizedCsv  ( GetFileContentInSourceFolder SQL_RegisteredDwInfo.csv ) )

    if ($registeredDwInfo.'DW mgmt server name' -eq $null) { # no DW registered, therefore no need to run this rule.
        return
    }

    $linesIn_SQL_sp_configure_FromRegisteredDwSQL = ConvertFrom-Csv  ( GetSanitizedCsv  ( GetFileContentInSourceFolder SQL_sp_configure_FromRegisteredDwSQL.csv ) '"xp_cmdshell' ) 
    [int]$clrEnabledOnRegisteredDwSQL = GetValueFromImportedCsv $linesIn_SQL_sp_configure_FromRegisteredDwSQL "name" "clr enabled" "run_value"

    $dataRow = GetEmptyResultRow
    $dataRow.RuleName="SQL CLR on registered DW/SQL"
    $dataRow.RuleDesc="CLR must be enabled on the registered Data Warehouse SQL instance. Otherwise, the Setup can fail or Console can crash, please check OperationsManager event log. The value of 'clr enabled' is in $(CollectorLink SQL_sp_configure_FromRegisteredDwSQL.csv)."
    $dataRow.RuleResult="Actual: $clrEnabledOnRegisteredDwSQL"
    if (IsSourceAnyScsmMgmtServer) { $dataRow.SAPCategories =  "Console\*", "SMConfPerf\SM Setup"}
    $dataRow.ProblemSeverity=[ProblemSeverity]::Critical

    if ($clrEnabledOnRegisteredDwSQL -eq 1) { $Result_OKs += $dataRow }
    else {            
        $dataRow.ProblemSeverity=[ProblemSeverity]::Critical
        $dataRow.RuleResult += @"
        <br/>Run the below with SQL admin permissions:<pre>        
        sp_configure 'clr enabled', 1
        go
        reconfigure<pre>
"@            
        $Result_Problems += $dataRow
    }
}