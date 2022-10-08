function Collect_SCOMCIConnectorAllowList() {
    AppendOutputToFileInTargetFolder (Get-SCSMAllowList) "Get-SCSMAllowList.txt"
}