function Collect_NotificationChannel() {
    AppendOutputToFileInTargetFolder (Get-SCSMChannel | fl *) "Get-SCSMChannel.txt"
    AppendOutputToFileInTargetFolder (Get-SCSMChannel | ConvertTo-Csv) "Get-SCSMChannel.csv"
	AppendOutputToFileInTargetFolder (Get-SCSMChannel | Select-Object -ExpandProperty ConfigurationSources | Select-Object -Property SequenceNumber, Authentication | Sort-Object -Property SequenceNumber | ConvertTo-Csv) "Get-SCSMChannel_WithAuthentication.csv"
}