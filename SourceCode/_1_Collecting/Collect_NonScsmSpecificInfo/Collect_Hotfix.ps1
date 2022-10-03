function Collect_Hotfix() {
    AppendOutputToFileInTargetFolder (Get-HotFix | Format-table -Wrap -AutoSize)  "Get-Hotfix.txt"
}