function Collect_NotificationChannel() {
    AppendOutputToFileInTargetFolder (Get-SCSMChannel | fl *) "Get-SCSMChannel.txt"
	AppendOutputToFileInTargetFolder (Get-SCSMChannel | Select-Object -ExpandProperty ConfigurationSources | Select-Object -Property SequenceNumber, Authentication | Sort-Object -Property SequenceNumber) "Get-SCSMChannel_WithAuthentication.txt"
}