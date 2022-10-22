function Collect_SCSMSettings() {
    AppendOutputToFileInTargetFolder (Get-SCSMSetting)  "Get-SCSMSetting.txt"
}