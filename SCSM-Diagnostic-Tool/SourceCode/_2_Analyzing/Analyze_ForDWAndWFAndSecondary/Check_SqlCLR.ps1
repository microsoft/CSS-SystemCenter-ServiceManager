function Check_SqlCLR() {
# check if 'clr enabled' is 1 on the SQL instance

    $linesIn_SQL_sp_configure = ConvertFrom-Csv  ( GetSanitizedCsv  ( GetFileContentInSourceFolder SQL_sp_configure.csv ) '"xp_cmdshell' ) 
    [int]$clrEnabled = GetValueFromImportedCsv $linesIn_SQL_sp_configure "name" "clr enabled" "run_value"

    $dataRow = GetEmptyResultRow
    $dataRow.RuleName="SQL CLR"
    $dataRow.RuleDesc="CLR must be enabled on the SQL instance that is hosting the ServiceManager database. Otherwise, the Setup can fail or Console can crash, please check OperationsManager event log. The value of 'clr enabled' is in $(CollectorLink SQL_sp_configure.csv)."
    $dataRow.RuleResult="Actual: $clrEnabled"
    if (IsSourceAnyScsmMgmtServer) { $dataRow.SAPCategories =  "Console\*", "SMConfPerf\SM Setup"}
    $dataRow.ProblemSeverity=[ProblemSeverity]::Critical

    if ($clrEnabled -eq 1) { $Result_OKs += $dataRow }
    else {        
        $dataRow.RuleResult += @"
<br/>Run the below with SQL admin permissions:<pre>        
sp_configure 'clr enabled', 1
go
reconfigure<pre>
"@
        $Result_Problems += $dataRow
    }
}