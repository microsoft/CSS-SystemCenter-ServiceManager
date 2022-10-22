function Collect_SCSMVersion() {
    AppendOutputToFileInTargetFolder (GP HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*  | ?{$_.DisplayName -like "*Service Manager*"} | FT DisplayName, DisplayVersion -Autosize) "SCSM_Version.txt"
    AppendOutputToFileInTargetFolder (GP HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*  | ?{$_.DisplayName -like "*Service Manager*"} | Select-Object DisplayName, DisplayVersion, Publisher | ConvertTo-Csv) "SCSM_Version.csv"
}