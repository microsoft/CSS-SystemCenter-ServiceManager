function Check_DWMPDeploymentStatus() {
#Check DW MP Deployment Status
$DwMPs = ConvertFrom-Csv (GetSanitizedCsv (GetFileContentInSourceFolder SQL_DeploySequenceView.csv)) 

    $dataRow = GetEmptyResultRow
    $dataRow.RuleName="DW MP Deployment Status"
    $dataRow.RuleDesc="All DW MPs should have Deployment Status of Completed. $(CollectorLink SQL_DeploySequenceView.csv 'MP Deployment Status')"
    $dataRow.RuleResult="All MPs are deployed to the DW successfully."
    $dataRow.SAPCategories= "*etl*" , "*Mpsync*"
    $dataRow.ProblemSeverity=[ProblemSeverity]::Error

    if ( $DwMPs.Count -eq 0 ) { $Result_OKs += $dataRow }
    else {        
        $dataRow.RuleResult = "At least one MP deployment has not Completed. $(IgnoreRuleIfText) MPSyncJob is still in progress. Otherwise, check in the files below:<pre>
$(CollectorLink SQL_DeploySequenceView.csv DeploySequenceView)
$(CollectorLink SQL_DeploySequenceStaging.csv DeploySequenceStaging)
$(CollectorLink SQL_DeployItemStaging.csv DeployItemStaging)
$(CollectorLink SQL_SynchronizationJobDetails.csv 'Synchronization Job Details')
$(CollectorLink Get-SCDWJob.txt Get-SCDWJob)
$(CollectorLink Get-SCDWJob_NumberOfBatches_5.txt 'Get-SCDWJob -NumberOfBatches 5')
$(CollectorLink SQL_InfraBatch.csv infra.Batch)
$(CollectorLink SQL_InfraWorkItem.csv infra.WorkItem)
$(CollectorLink SQL_LockDetails.csv LockDetails)
$(CollectorLink OperationsManager.evtx 'OperationsManager event log')</pre>"

        $dataRow.RuleResult += "</br></br>As the most stable solution, you may consider to restore all DW databases back to a date that was before the problem had started.<br/>However, in order to prevent data loss in the DW, the backup date should NOT be earlier than the 'Data Retention Days' of Work Items in the SM database"
        $smDbDataRetentionInfo = ConvertFrom-Csv ( GetSanitizedCsv (GetFileContentInSourceFolder SQL_FromSMDB_DataRetention.csv ) )
        if ($smDbDataRetentionInfo -and $smDbDataRetentionInfo.Count -gt 0) {
	        $smDbDataRetentionDays = ($smDbDataRetentionInfo | Select-Object -First 1).Days
	        [timespan]$ts = [timespan]::new($smDbDataRetentionDays,0,0,0,0)
	        $smDbDataRetentionDate = (Get-Date).Subtract($ts)	
	        $dataRow.RuleResult += ", which corresponds to $smDbDataRetentionDate."	
        }
        else {
	        $dataRow.RuleResult += "."
        } 
        $dataRow.RuleResult += " Please consult your SQL Server admin team for available backups."

        $Result_Problems += $dataRow
    }
}