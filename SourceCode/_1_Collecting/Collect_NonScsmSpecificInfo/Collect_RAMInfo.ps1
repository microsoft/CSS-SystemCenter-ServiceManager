function Collect_RAMInfo() {    
    
    [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.VisualBasic") | Out-Null
    [long]$totalRamMB = ( [Microsoft.VisualBasic.Devices.ComputerInfo]::new().TotalPhysicalMemory / 1mb )
    AppendOutputToFileInTargetFolder $totalRamMB TotalRAM.txt

}