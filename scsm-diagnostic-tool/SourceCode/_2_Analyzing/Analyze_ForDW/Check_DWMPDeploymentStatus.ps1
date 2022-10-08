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
        $Result_Problems += $dataRow
    }
}