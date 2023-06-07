function Analyze_ForDWAndWFAndSecondary() {
#region DO NOT REMOVE THIS! Exit immediately if script does NOT run on a DW or WF or Secondary mgmt server.
if (-not (IsSourceAnyScsmMgmtServer)) {
    return
}
#endregion

 #Rules for All SCSM mgmt servers => WF + Secondary + DW

    Check_CollectorsSqlPermission
    Check_MgmtServerHW
    Check_SQLServerHW
    Check_SqlBroker
    Check_SqlCLR
    Check_SPNs
    Check_OMSDK_Service
    Check_LocalOMSDK_Availability
    Check_ConnectedSDKUsers
    Check_TimeDiffBetweenMSAndSQL

 #Below are not necessarily "rules"

    GetForStatInfo_SMEnv_SM
} 
