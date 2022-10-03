function Collect_ConnectorEclLogSettings() {
    AppendOutputToFileInTargetFolder (Get-SCSMClassInstance -Class (Get-SCSMClass -Name "System.GlobalSetting.ConnectorEclLogSettings")) "ConnectorEclLogSettings.txt"
}