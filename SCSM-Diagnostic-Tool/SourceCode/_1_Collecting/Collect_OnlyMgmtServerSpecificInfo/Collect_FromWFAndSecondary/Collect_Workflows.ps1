function Collect_Workflows() {
    AppendOutputToFileInTargetFolder (Get-SCSMWorkflow | fl *) "Get-SCSMWorkflow.txt"
}