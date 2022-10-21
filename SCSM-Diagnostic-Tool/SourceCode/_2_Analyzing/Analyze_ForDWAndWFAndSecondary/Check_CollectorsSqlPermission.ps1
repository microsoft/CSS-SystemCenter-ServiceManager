function Check_CollectorsSqlPermission() {
    $dataRow = GetEmptyResultRow
    $dataRow.RuleName="This Tool's SQL Permission"
    $dataRow.RuleDesc= "The SCSM Diagnostic Tool must have at least SELECT permission on the target DB. Otherwise, this Analysis should be considered as useless."
    $dataRow.ProblemSeverity=[ProblemSeverity]::Critical    

    $linesIn_tmpFile = ConvertFrom-Csv  ( GetSanitizedCsv  ( GetFileContentInSourceFolder SQL_MOMManagementGroupInfo.csv ) ) 
    if ([string]::IsNullOrWhiteSpace( $linesIn_tmpFile)) {
        $dataRow.RuleResult="This Analysis is <h1>'USELESS'.</H1><br/> Do <b><u>NOT</u></b> rely on the findings of this Analysis report.<br/>As an example, you can check in $(CollectorLink SQL_MOMManagementGroupInfo.csv) to confirm that the user account which ran this Tool was *NOT* able to read from a table in the DB."   
        $Result_Problems += $dataRow
    }
    else {
        $dataRow.RuleResult="Looks good. As an example, you can check in $(CollectorLink SQL_MOMManagementGroupInfo.csv) to verify if the user account that ran this Tool was able to read from a table in the DB."
        $Result_OKs += $dataRow
    }    
}