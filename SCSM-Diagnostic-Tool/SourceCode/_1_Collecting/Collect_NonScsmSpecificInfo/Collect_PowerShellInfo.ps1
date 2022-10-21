function Collect_PowerShellInfo() {
    AppendOutputToFileInTargetFolder ($PSVersionTable) "PSVersionTable.txt"
    AppendOutputToFileInTargetFolder ($PSVersionTable.PSCompatibleVersions) "PSCompatibleVersions.txt"   
    AppendOutputToFileInTargetFolder ( Get-ExecutionPolicy -List ) Get-ExecutionPolicy_List.txt
    AppendOutputToFileInTargetFolder "Elevated: $(IsRunningAsElevated)" IsRunningAsElevated.txt
}