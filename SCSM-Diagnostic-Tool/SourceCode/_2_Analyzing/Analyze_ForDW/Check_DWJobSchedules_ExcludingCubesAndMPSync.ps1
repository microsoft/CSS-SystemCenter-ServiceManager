function Check_DWJobSchedules_ExcludingCubesAndMPSync() {
#check DW Job Schedules (excl Cubes & MPSync). Schedules count should match with jobs count.
$GetSCDWJobSchedule = ConvertFrom-Csv (GetFileContentInSourceFolder Get-SCDWJobSchedule.csv)
$jobSchedules_Wocubes = $GetSCDWJobSchedule | ? { $_.CategoryName -ne "CubeProcessing" -and $_.Name -ne "MPSyncJob" }

$GetSCDWJob = ConvertFrom-Csv (GetFileContentInSourceFolder Get-SCDWJob.csv)
$jobs_Wocubes = $GetSCDWJob | ? { $_.CategoryName -ne "CubeProcessing" -and $_.Name -ne "MPSyncJob" }

    $dataRow = GetEmptyResultRow
    $dataRow.RuleName="DW ETL Job Schedules (excl Cubes & MPSyncJob)"
    $dataRow.RuleDesc="The 'Schedules' for DWMaintenance, Extract*, Transform.Common and Load.* jobs must be Enabled. $(CollectorLink Get-SCDWJobSchedule.txt Get-SCDWJobSchedule)"
    $dataRow.SAPCategories= "*etl*" , "*mpsync*"
    $dataRow.ProblemSeverity=[ProblemSeverity]::Critical

    $dataRow.RuleResult = [string]::Empty
    if ( $jobSchedules_Wocubes.count -ne $jobs_Wocubes.Count ) {
        $dataRow.RuleResult += @"
At least one Job Schedule is MISSING! Check in the files below:><pre> 
$(CollectorLink SQL_DeploySequenceView.csv DeploySequenceView)
$(CollectorLink SQL_DeploySequenceStaging.csv DeploySequenceStaging)
$(CollectorLink SQL_DeployItemStaging.csv DeployItemStaging)
$(CollectorLink Get-SCDWJob.txt Get-SCDWJob)
$(CollectorLink Get-SCDWJobSchedule.txt Get-SCDWJobSchedule)
$(CollectorLink OperationsManager.evtx 'OperationsManager event log')</pre>
"@
    }
    elseif ( ($jobSchedules_Wocubes | ? { $_.ScheduleEnabled -eq $true } ).Count -ne $jobSchedules_Wocubes.Count) {
        $dataRow.RuleResult += "
At least one Job Schedule is DISABLED! Confirm if they are intentionally disabled. $(CollectorLink Get-SCDWJobSchedule.txt Get-SCDWJobSchedule)"+'
The below can enable all required Job Schedules (excl Cubes & MPSyncJob):<pre>
Foreach($job in get-scdwjob) { if ($job.CategoryName -ne "CubeProcessing" -and $job.Name -ne "MPSyncJob") {Enable-scdwjobSchedule -jobname $job.name;} }<pre>'
    }
    
    if ($dataRow.RuleResult -eq [string]::Empty) {
        $dataRow.RuleResult="All schedules (except Cubes) are enabled."
        $Result_OKs += $dataRow
    }
    else { $Result_Problems += $dataRow }
}