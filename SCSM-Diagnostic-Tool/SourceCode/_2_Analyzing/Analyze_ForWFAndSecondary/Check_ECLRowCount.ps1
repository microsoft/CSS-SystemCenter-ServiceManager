function Check_ECLRowCount() {
[long]$tolerance_EclRowcountInMillions = 20

    $dataRow = GetEmptyResultRow
    $dataRow.RuleName="ECL row count"
    $dataRow.RuleDesc=@"
The EntityChangeLog (ECL) table should have < $tolerance_EclRowcountInMillions million rows. Otherwise, WFs can lag and Consoles can face slowness.
<br/>Row count for all tables are in $(CollectorLink SQL_TableSizeInfo.csv)
"@
    $dataRow.SAPCategories = "wf*" 
    $dataRow.ProblemSeverity=[ProblemSeverity]::Critical

    $linesIn_SQL_TableSizeInfo = ConvertFrom-Csv (GetSanitizedCsv ( GetFileContentInSourceFolder SQL_TableSizeInfo.csv) ) 
    [long]$EclRowcount = ($linesIn_SQL_TableSizeInfo | ? { ($_.Name -eq "[dbo].[EntityChangeLog]") -or ($_.Name -eq "EntityChangeLog") }).rows
    $dataRow.RuleResult="ECL rowcount is $(WithThousandSeparators $EclRowcount)."

    if ($EclRowcount -le $tolerance_EclRowcountInMillions*1000000) {
        $Result_OKs += $dataRow 
    }
    else {
        $Result_Problems += $dataRow
    }
}