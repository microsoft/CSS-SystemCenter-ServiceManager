function Collect_Test_BetweenMSandDWMS() {
    $RegisteredDwMSName=(Try-Invoke-SqlCmd -SQLInstance $SQLInstance_SCSM -SQLDatabase $SQLDatabase_SCSM -Query 'select Server_48B308F9_CF0E_0F74_83E1_0AEB1B58E2FA as DWMSName from MT_Microsoft$SystemCenter$ResourceAccessLayer$DwSdkResourceStore').Tables[0].DWMSName
    if ($RegisteredDwMSName) {
        AppendOutputToFileInTargetFolder (Test-NetConnection -ComputerName $RegisteredDwMSName -Port 5724) Telnet_FromSM_ToDW.txt
        AppendOutputToFileInTargetFolder (Test-Connection -ComputerName $RegisteredDwMSName | ft -Wrap -Autosize) Ping_FromSM_ToDW.txt
    }
}