function Collect_TimeDiffBetweenDC() {
    $compNameToCheckTimeDiff = ($env:LOGONSERVER).Replace("\\","")
    $result = Run2ndOnlyIf1stSucceeds {
        InvokeCommand -computerName $compNameToCheckTimeDiff -scriptBlock {Get-Date}
        }{
        New-TimeSpan -Start (Get-Date) -End $resultOf1 
    }
    AppendOutputToFileInTargetFolder ( $result ) "TimeDiff_BtwDC.txt"
    AppendOutputToFileInTargetFolder ( w32tm.exe /stripchart /dataonly /samples:1 /computer:$compNameToCheckTimeDiff 2>&1 ) "TimeDiff_BtwDC_viaWin32tm.txt"
}