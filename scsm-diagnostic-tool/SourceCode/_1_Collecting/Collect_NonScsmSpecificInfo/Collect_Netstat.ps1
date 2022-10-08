function Collect_Netstat() {
    AppendOutputToFileInTargetFolder (netstat /abof) "netstat_abof.txt"
}