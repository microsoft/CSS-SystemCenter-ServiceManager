function Collect_Processes() {
    if ( $PSVersionTable.PSVersion.Major -ge 3 ) { 
        $processWithAllInfo = Get-Process -IncludeUserName | ? {$_.Id -ne 0 }| select *,CurrentCPU 
    }
    else {
        $processWithAllInfo = Get-Process | ? {$_.Id -ne 0 }| select *,CurrentCPU 
    }

    $PID_CurrentCPU=Get-WmiObject Win32_PerfFormattedData_PerfProc_Process | ? {$_.IDProcess -ne 0 } | select IDProcess, @{ Name = 'PercentProcessorTime';  Expression = {$_.PercentProcessorTime / ($env:NUMBER_OF_PROCESSORS) }} 
    foreach($p in $processWithAllInfo) {  $p.CurrentCPU = ( $PID_CurrentCPU | ? {$_.IDProcess -eq $p.Id}  ).PercentProcessorTime }  
    AppendOutputToFileInTargetFolder (  $processWithAllInfo | select Handles, WS, CurrentCPU, Id, UserName, ProcessName | ft -Wrap ) Get-Process_WithCurrentCPU.txt
    AppendOutputToFileInTargetFolder (  $processWithAllInfo ) Get-Process_WithAllDetails.txt
    AppendOutputToFileInTargetFolder (  $processWithAllInfo | ? {$_.Name -eq "System" } | Select StartTime ) MachineStartTime.txt
    AppendOutputToFileInTargetFolder (  $processWithAllInfo | ? {$_.Id -ne 0  -and  $_.CurrentCPU -gt 0} | select Id,Name,CurrentCPU )  Get-Process_OnlyActiveOnes.txt
    AppendOutputToFileInTargetFolder (  $processWithAllInfo | ? {$_.Id -ne 0} | Sort-Object -Property CurrentCPU -Descending | select Id,Name,CurrentCPU -First 10  )  Get-Process_Top10_ByCPU.txt
    AppendOutputToFileInTargetFolder (  $processWithAllInfo | ? {$_.Id -ne 0} | Sort-Object -Property WS -Descending | select Id,Name,WS -First 10  )  Get-Process_Top10_ByWorkingSet.txt
}