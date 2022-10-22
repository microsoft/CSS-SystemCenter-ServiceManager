function Collect_ServiceInfo() {
    AppendOutputToFileInTargetFolder (gwmi win32_service | Select-Object Name, StartMode, State, DisplayName, StartName, pathname | ConvertTo-Csv -NoTypeInformation ) Get-Service.csv
}