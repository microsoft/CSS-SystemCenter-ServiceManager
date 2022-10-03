function Collect_DWJobSchedules() {
    AppendOutputToFileInTargetFolder (Get-SCDWJobSchedule) "Get-SCDWJobSchedule.txt"
    AppendOutputToFileInTargetFolder ( (Get-SCDWJobSchedule) | ConvertTo-Csv )  "Get-SCDWJobSchedule.csv" 
}