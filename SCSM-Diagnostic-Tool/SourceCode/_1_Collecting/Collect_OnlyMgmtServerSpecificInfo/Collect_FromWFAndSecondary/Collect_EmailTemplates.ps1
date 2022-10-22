function Collect_EmailTemplates() {
    AppendOutputToFileInTargetFolder (Get-SCSMEmailTemplate | fl) "Get-SCSMEmailTemplate.txt"
}