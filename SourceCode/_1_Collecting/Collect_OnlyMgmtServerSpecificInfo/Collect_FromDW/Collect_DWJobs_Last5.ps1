function Collect_DWJobs_Last5() {
    $dwjobsNOB = Get-SCDWJob -NumberOfBatches 5 | select BatchId,Name,Status,CategoryName,StartTime,EndTime,IsEnabled,Duration
    foreach($dwjobNOB in $dwjobsNOB) {
        if ($dwjobNOB.Starttime -and $dwjobNOB.Endtime) {            
            $dwjobNOB.Duration = Get-UserFriendlyTimeSpane ($dwjobNOB.EndTime - $dwjobNOB.StartTime)
        }        
    }
    AppendOutputToFileInTargetFolder ($dwjobsNOB | Sort-Object -Property Name | ft )  "Get-SCDWJob_NumberOfBatches_5.txt"
}