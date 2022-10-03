function Collect_Test_BetweenDWMSandSQL() {
    AppendOutputToFileInTargetFolder (Test-NetConnection -ComputerName (GetMachineNameFromSqlInstance $SQLInstance_SCSMDW) -Port (GetPortFromSqlInstance $SQLInstance_SCSMDW)) Telnet_FromSMDW_ToSQL.txt 
    AppendOutputToFileInTargetFolder (Test-Connection -ComputerName (GetMachineNameFromSqlInstance $SQLInstance_SCSMDW)) Ping_FromSMDW_ToSQL.txt
}