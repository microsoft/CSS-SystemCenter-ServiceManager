function Collect_Test_BetweenMSandSQL() {
    AppendOutputToFileInTargetFolder (Test-NetConnection -ComputerName (GetMachineNameFromSqlInstance $SQLInstance_SCSM) -Port (GetPortFromSqlInstance $SQLInstance_SCSM)) Telnet_FromSM_ToSQL.txt  
    AppendOutputToFileInTargetFolder (Test-Connection -ComputerName (GetMachineNameFromSqlInstance $SQLInstance_SCSM) | ft -Wrap -Autosize ) Ping_FromSM_ToSQL.txt 
}