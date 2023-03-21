function Collect_SCSMRunAsAccounts() {
    AppendOutputToFileInTargetFolder (Get-SCSMRunAsAccount) "Get-SCSMRunAsAccount.txt"

    AppendOutputToFileInTargetFolder (Get-SCSMRunAsAccount | ConvertTo-Csv) "Get-SCSMRunAsAccount.csv"
}