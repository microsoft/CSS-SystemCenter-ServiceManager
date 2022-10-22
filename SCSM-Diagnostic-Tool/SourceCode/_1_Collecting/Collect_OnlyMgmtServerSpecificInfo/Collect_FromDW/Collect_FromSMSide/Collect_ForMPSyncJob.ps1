function Collect_ForMPSyncJob() {
    AppendOutputToFileInTargetFolder (Test-NetConnection -ComputerName ($SMDBInfo.SDKServer_SMDB) -Port 5724) ForMPSyncJob_Telnet_FromDW_ToSMSDK.txt
}