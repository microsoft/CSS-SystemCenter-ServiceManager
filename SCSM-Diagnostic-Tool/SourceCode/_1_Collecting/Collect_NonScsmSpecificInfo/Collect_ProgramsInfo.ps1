function Collect_ProgramsInfo() {
    AppendOutputToFileInTargetFolder (Get-WmiObject -Class Win32_Product | Select-Object Version, Name, InstallDate ) "ProgramVersions.txt"
}
