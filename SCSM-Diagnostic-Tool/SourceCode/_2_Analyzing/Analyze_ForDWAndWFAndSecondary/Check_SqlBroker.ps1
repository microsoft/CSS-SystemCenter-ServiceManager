function Check_SqlBroker() {
#region check SQL Broker

    $linesIn_SQL_Databases = ConvertFrom-Csv (GetSanitizedCsv (GetFileContentInSourceFolder SQL_Databases.csv)) 
    $isBrokerEnabled = GetValueFromImportedCsv $linesIn_SQL_Databases "name" $MainSQL_DbName "is_broker_enabled"
    
    $dataRow = GetEmptyResultRow
    $dataRow.RuleName="SQL DB Broker"
    $dataRow.RuleDesc="Broker must be ENABLED"
    $dataRow.RuleResult="Broker at<br/> Instance: $MainSQL_InstanceName<br/> DB: $MainSQL_DbName<br/> is "
    if (IsSourceScsmWfMgmtServer) { $dataRow.SAPCategories = "wf\*" , "s*\*" }
    if (IsSourceScsmDwMgmtServer) { $dataRow.SAPCategories = "*etl*","*mpsync*" } 
    if (IsSourceScsmSecondaryMgmtServer) { $dataRow.SAPCategories = "Console\Usage" } 
    $dataRow.ProblemSeverity=[ProblemSeverity]::Critical

    if ($isBrokerEnabled -eq "True") {
        $dataRow.RuleResult += "enabled."
        $Result_OKs += $dataRow
    }
    else {       
        $dataRow.RuleResult += "NOT enabled! $(CollectorLink SQL_Databases.csv)" 
        $dataRow.RuleResult += "More details in this <a $(GetAnchorForExternal 'https://social.technet.microsoft.com/Forums/systemcenter/en-US/f16680c3-e906-4704-8d67-22c71c53472b/service-manager-db-sql-server-broker?forum=systemcenterservicemanager' Doc)."
        $dataRow.RuleResult += ' <br/>ACTION: Enable SQL DB Broker by running this SQL. Caution: This will disconnect all SQL connections to that DB. Better to stop all SM services before.'
$tmp = @"
<pre>
    ALTER DATABASE $MainSQL_DbName SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    ALTER DATABASE $MainSQL_DbName SET ENABLE_BROKER;
    ALTER DATABASE $MainSQL_DbName SET MULTI_USER;</pre>
"@
        $dataRow.RuleResult +=  $tmp
        $Result_Problems += $dataRow
    }
#endregion
}