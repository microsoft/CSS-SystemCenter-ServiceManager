function Collect_Connectors() {
    AppendOutputToFileInTargetFolder (Get-SCSMConnector | fl *) "Get-SCSMConnector.txt"
}