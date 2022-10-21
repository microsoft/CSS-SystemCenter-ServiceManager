function Collect_NotificationChannel() {
    AppendOutputToFileInTargetFolder (Get-SCSMChannel | fl *) "Get-SCSMChannel.txt"
}