function Collect_DWJobs() {
    $dwjobs = Get-SCDWJob | select BatchId,Name,Status,CategoryName,StartTime,EndTime,IsEnabled,Duration
    foreach($dwjob in $dwjobs) {
        if ($dwjob.Starttime -and $dwjob.Endtime) {            
            $dwjob.Duration = Get-UserFriendlyTimeSpane ($dwjob.EndTime - $dwjob.StartTime)  #"{0:dd}D.{0:hh}H:{0:mm}M" -f ($dwjob.EndTime - $dwjob.StartTime)
        }        
    }
    AppendOutputToFileInTargetFolder ($dwjobs | Sort-Object -Property Name | ft )  "Get-SCDWJob.txt" 
    AppendOutputToFileInTargetFolder ($dwjobs | Sort-Object -Property Name | ConvertTo-Csv )  "Get-SCDWJob.csv" 
}