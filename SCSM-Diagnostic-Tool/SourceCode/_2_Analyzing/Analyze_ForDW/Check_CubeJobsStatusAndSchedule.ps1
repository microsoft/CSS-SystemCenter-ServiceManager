function Check_CubeJobsStatusAndSchedule() {
#check Cube Jobs Count, Status and Schedules. 
$GetSCDWJob = ConvertFrom-Csv (GetFileContentInSourceFolder Get-SCDWJob.csv)
$CubeJobs = $GetSCDWJob | ? { $_.CategoryName -eq "CubeProcessing" }

$GetSCDWJobSchedule = ConvertFrom-Csv (GetFileContentInSourceFolder Get-SCDWJobSchedule.csv)
$cubeJobsSchedules = $GetSCDWJobSchedule | ? { $_.CategoryName -eq "CubeProcessing" }

    $dataRow = GetEmptyResultRow
    $dataRow.RuleName="DW Cube Jobs Status and Schedule"
    $dataRow.RuleDesc="Cube MPs can be removed if Cubes do not want to be used. If so, no Cube jobs will exist. Otherwise, there must be at least 6 cube jobs. All of them must be Running or Not Started."
    $dataRow.SAPCategories= "*cube*"

    if ($CubeJobs.Count -eq 0) { 
        $dataRow.RuleResult="No cube jobs exist. $(IgnoreRuleIfText) cube MPs were intentionally removed from SM side. Otherwise, this looks like a cube deployment problem. Check in the files below:<pre>
$(CollectorLink Get-SCDWJob.txt Get-SCDWJob)
$(CollectorLink Get-SCDWJob_NumberOfBatches_5.txt 'Get-SCDWJob -NumberOfBatches 5')
$(CollectorLink Get-SCDWJobSchedule.txt Get-SCDWJobSchedule)
$(CollectorLink SQL_DeploySequenceView.csv DeploySequenceView)
$(CollectorLink SQL_DeploySequenceStaging.csv DeploySequenceStaging)
$(CollectorLink SQL_DeployItemStaging.csv DeployItemStaging)
$(CollectorLink SQL_InfraBatch.csv infra.Batch)
$(CollectorLink SQL_InfraWorkItem.csv infra.WorkItem)
$(CollectorLink SQL_LockDetails.csv LockDetails)
$(CollectorLink OperationsManager.evtx 'OperationsManager event log')</pre>
"
        $dataRow.ProblemSeverity=[ProblemSeverity]::Warning 
        $Result_Problems += $dataRow
    }
    elseif ($CubeJobs.Count -lt 6) { 
        $dataRow.RuleResult="Cube jobs count is between 1 and 5. $(IgnoreRuleIfText) cube deployments are still in progress. Otherwise, this looks like a cube deployment problem. Check in the files below:<pre>
$(CollectorLink Get-SCDWJob.txt Get-SCDWJob)
$(CollectorLink Get-SCDWJob_NumberOfBatches_5.txt 'Get-SCDWJob -NumberOfBatches 5')
$(CollectorLink Get-SCDWJobSchedule.txt Get-SCDWJobSchedule)
$(CollectorLink SQL_DeploySequenceView.csv DeploySequenceView)
$(CollectorLink SQL_DeploySequenceStaging.csv DeploySequenceStaging)
$(CollectorLink SQL_DeployItemStaging.csv DeployItemStaging)
$(CollectorLink SQL_InfraBatch.csv infra.Batch)
$(CollectorLink SQL_InfraWorkItem.csv infra.WorkItem)
$(CollectorLink SQL_LockDetails.csv LockDetails)
$(CollectorLink OperationsManager.evtx 'OperationsManager event log')</pre>"
        $dataRow.ProblemSeverity=[ProblemSeverity]::Error 
        $Result_Problems += $dataRow
    }
    else {

        if ( ($CubeJobs | ? { $_.Status -in ("Running","Not Started") } ).Count -eq $CubeJobs.Count `
            -and ($cubeJobsSchedules | ? { $_.ScheduleEnabled -eq $true } ).Count -eq $cubeJobsSchedules.Count `
            -and  $cubeJobsSchedules.Count -eq $CubeJobs.Count
        ) { 
            $dataRow.RuleResult="All Cube jobs look fine."
            $dataRow.ProblemSeverity=[ProblemSeverity]::Error
            $Result_OKs += $dataRow 
        }
        elseif ( ($CubeJobs | ? { $_.Status -in ("Running","Not Started") } ).Count -ne $CubeJobs.Count ) {
            $dataRow.RuleResult = "At least one Cube batch is not in status 'Running' or 'Not Started'. $(IgnoreRuleIfText) cubes are not in use. Check in the files below:<pre>
$(CollectorLink Get-SCDWJob.txt Get-SCDWJob)
$(CollectorLink Get-SCDWJob_NumberOfBatches_5.txt 'Get-SCDWJob -NumberOfBatches 5')
$(CollectorLink Get-SCDWJobSchedule.txt Get-SCDWJobSchedule)
$(CollectorLink SQL_DeploySequenceView.csv DeploySequenceView)
$(CollectorLink SQL_DeploySequenceStaging.csv DeploySequenceStaging)
$(CollectorLink SQL_DeployItemStaging.csv DeployItemStaging)
$(CollectorLink SQL_InfraBatch.csv infra.Batch)
$(CollectorLink SQL_InfraWorkItem.csv infra.WorkItem)
$(CollectorLink SQL_LockDetails.csv LockDetails)
$(CollectorLink OperationsManager.evtx 'OperationsManager event log')</pre>"
            $dataRow.ProblemSeverity=[ProblemSeverity]::Error
            $Result_Problems += $dataRow
        }
        elseif ( ($cubeJobsSchedules | ? { $_.ScheduleEnabled -eq $true } ).Count -ne $cubeJobsSchedules.Count ) {
            $dataRow.RuleResult = "At least one Cube 'Schedule' is DISABLED in $(CollectorLink Get-SCDWJobSchedule.txt Get-SCDWJobSchedule). $(IgnoreRuleIfText) they are intentionally disabled. Otherwise, run the below to enable all cube Job Schedules:<pre>"+
            'Foreach($job in get-scdwjob) { if ($job.CategoryName -eq "CubeProcessing") {Enable-scdwjobSchedule -jobname $job.name;} } </pre>'
            $dataRow.ProblemSeverity=[ProblemSeverity]::Warning
            $Result_Problems += $dataRow
        }
        elseif (  $cubeJobsSchedules.Count -ne $CubeJobs.Count ) {
            $dataRow.RuleResult = "At least one Cube 'Schedule' is MISSING. $(IgnoreRuleIfText) cubes are not in use. Check in the files below:<pre>
$(CollectorLink Get-SCDWJobSchedule.txt Get-SCDWJobSchedule)
$(CollectorLink SQL_DeploySequenceView.csv DeploySequenceView)
$(CollectorLink SQL_DeploySequenceStaging.csv DeploySequenceStaging)
$(CollectorLink SQL_DeployItemStaging.csv DeployItemStaging)
$(CollectorLink Get-SCDWJob.txt Get-SCDWJob)
$(CollectorLink Get-SCDWJob_NumberOfBatches_5.txt 'Get-SCDWJob -NumberOfBatches 5')
$(CollectorLink SQL_InfraBatch.csv infra.Batch)
$(CollectorLink SQL_InfraWorkItem.csv infra.WorkItem)
$(CollectorLink SQL_LockDetails.csv LockDetails)
$(CollectorLink OperationsManager.evtx 'OperationsManager event log')</pre>"
            $dataRow.ProblemSeverity=[ProblemSeverity]::Error
            $Result_Problems += $dataRow
        }
    }
}