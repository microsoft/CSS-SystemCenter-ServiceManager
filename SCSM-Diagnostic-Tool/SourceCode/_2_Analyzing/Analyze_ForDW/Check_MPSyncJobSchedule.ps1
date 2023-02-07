function Check_MPSyncJobSchedule() {

    $GetSCDWJobSchedule = ConvertFrom-Csv (GetFileContentInSourceFolder Get-SCDWJobSchedule.csv)
    $jobSchedule_MpSyncJob = $GetSCDWJobSchedule | ? { $_.Name -eq "MPSyncJob" }

    $dataRow = GetEmptyResultRow
    $dataRow.RuleName="Schedule of MPSyncJob"
    $dataRow.SAPCategories= "*mpsync*"

    if (-not $jobSchedule_MpSyncJob) {
        $dataRow.ProblemSeverity=[ProblemSeverity]::Critical
        $dataRow.RuleDesc= "The Schedule of MPSyncJob must exist."
        $dataRow.RuleResult = @"
Looks like the Schedule of MPSyncJob is MISSING! Check in the files below:><pre> 
$(CollectorLink SQL_DeploySequenceView.csv DeploySequenceView)
$(CollectorLink SQL_DeploySequenceStaging.csv DeploySequenceStaging)
$(CollectorLink SQL_DeployItemStaging.csv DeployItemStaging)
$(CollectorLink Get-SCDWJob.txt Get-SCDWJob)
$(CollectorLink Get-SCDWJobSchedule.txt Get-SCDWJobSchedule)
$(CollectorLink OperationsManager.evtx 'OperationsManager event log')</pre>
"@
        $Result_Problems += $dataRow 
    }
    else {
        $dataRow.ProblemSeverity=[ProblemSeverity]::Warning
        $dataRow.RuleDesc= "The 'Schedule' of MPSyncJob is normally enabled by default."

        if ($jobSchedule_MpSyncJob.ScheduleEnabled -eq $true) {
            $dataRow.RuleResult = "It is enabled."
            $Result_OKs += $dataRow 
        }
        else {    
            $dataRow.RuleResult = "The 'Schedule' of MPSyncJob is disabled. $(IgnoreRuleIfText) MPSyncJob has been disabled intentionally according to the first bullet listed at $(GetAnchorForExternal 'https://techcommunity.microsoft.com/t5/system-center-blog/system-center-service-manager-scsm-authoring-management-pack/ba-p/351868' 'this article')"
            $Result_Problems += $dataRow 
        }
    }
}