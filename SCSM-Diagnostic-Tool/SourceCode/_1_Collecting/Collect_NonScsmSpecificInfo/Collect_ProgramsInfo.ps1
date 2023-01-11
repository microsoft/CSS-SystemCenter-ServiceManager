function Collect_ProgramsInfo() {
    Start_Async -code { Get-WmiObject -Class Win32_Product | Select-Object Version, Name, InstallDate | ft } -outputFileName "ProgramVersions.txt" 
}
