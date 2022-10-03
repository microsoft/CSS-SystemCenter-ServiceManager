function Collect_TimeDiffBetweenDWMSandSQL() {
    #Getting the time diff directly (if possible)
    $compNameToCheckTimeDiff = (GetMachineNameFromSqlInstance $SQLInstance_SCSMDW)
    $result = Run2ndOnlyIf1stSucceeds {
        InvokeCommand -computerName $compNameToCheckTimeDiff -scriptBlock {Get-Date}
        }{
        New-TimeSpan -Start (Get-Date) -End $resultOf1 
    }
    AppendOutputToFileInTargetFolder ( $result ) "TimeDiff_BtwMS_AndSQL.txt"

    # additionally, getting the time diff via win32tm
    AppendOutputToFileInTargetFolder ( w32tm.exe /stripchart /dataonly /samples:1 /computer:$compNameToCheckTimeDiff ) "TimeDiff_BtwMS_AndSQL_viaWin32tm.txt"
}