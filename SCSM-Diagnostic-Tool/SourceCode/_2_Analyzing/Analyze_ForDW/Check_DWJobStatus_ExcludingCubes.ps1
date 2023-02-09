function Check_DWJobStatus_ExcludingCubes() {
#check DW Job Status (excl Cubes). This would inheritently check job existence, too.

$GetSCDWJob = ConvertFrom-Csv (GetFileContentInSourceFolder Get-SCDWJob.csv)

$DWMaintenance = $GetSCDWJob | ? { $_.Name -eq "DWMaintenance"}
$MPSyncJob = $GetSCDWJob | ? { $_.Name -eq "MPSyncJob"}
$Extract_DW = $GetSCDWJob | ? { $_.Name -like "Extract_DW_*"}
$Extract_Others = $GetSCDWJob | ? { $_.CategoryName -eq "Extract" -and -not ($_.Name -like "Extract_DW_*") }
$TransformCommon = $GetSCDWJob | ? { $_.Name -eq "Transform.Common"}
$LoadCommon = $GetSCDWJob | ? { $_.Name -eq "Load.Common"}
$Load_Others = $GetSCDWJob | ? { $_.CategoryName -eq "Load" -and -not ($_.Name -eq "Load.Common") }

    $dataRow = GetEmptyResultRow
    $dataRow.RuleName="DW Jobs Status (excl Cubes)"
    $dataRow.RuleDesc="The batches for DWMaintenance, MPSyncJob, (at least) 2 Extract*, Transform.Common and Load.* must be Running or Not Started. $(CollectorLink Get-SCDWJob.txt Get-SCDWJob)"
    $dataRow.RuleResult="All ETL jobs look fine."
    $dataRow.SAPCategories= "*etl*" , "*mpsync*"
    $dataRow.ProblemSeverity=[ProblemSeverity]::Critical

    if ($DWMaintenance.Status -in ("Running","Not Started") `
        -and $MPSyncJob.Status -in ("Running","Not Started") `
        -and $Extract_DW.Status -in ("Running","Not Started") `
        -and ($Extract_Others | ? { $_.Status -in ("Running","Not Started") } ).Count -eq $Extract_Others.Count `
        -and $TransformCommon.Status -in ("Running","Not Started") `
        -and $LoadCommon.Status -in ("Running","Not Started")  `
        -and ($Load_Others | ? { $_.Status -in ("Running","Not Started") } ).Count -eq $Load_Others.Count 
    ) { $Result_OKs += $dataRow }
    else {        
        $dataRow.RuleResult = @"
At least one batch is not in status: 'Running' or 'Not Started'. Check in the files below:<pre>
$(CollectorLink Get-SCDWJob.txt Get-SCDWJob)
$(CollectorLink SQL_DeploySequenceView.csv DeploySequenceView)
$(CollectorLink SQL_DeploySequenceStaging.csv DeploySequenceStaging)
$(CollectorLink SQL_DeployItemStaging.csv DeployItemStaging)
$(CollectorLink Get-SCDWJob_NumberOfBatches_5.txt 'Get-SCDWJob -NumberOfBatches 5')
$(CollectorLink SQL_InfraBatch.csv infra.Batch)
$(CollectorLink SQL_InfraWorkItem.csv infra.WorkItem)
$(CollectorLink SQL_LockDetails.csv LockDetails)
$(CollectorLink OperationsManager.evtx 'OperationsManager event log')</pre>
"@
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