function Collect_SCSMRunAsAccounts() {
    AppendOutputToFileInTargetFolder (Get-SCSMRunAsAccount) "Get-SCSMRunAsAccount.txt"
}