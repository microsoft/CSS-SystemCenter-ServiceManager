function Collect_FromDWAndWFAndSecondary() {
#region DO NOT REMOVE THIS! Exit immediately if script is NOT running on a WF or Secondary or DW mgmt server
if (-not (IsThisAnyScsmMgmtServer)) {
    return
}
#endregion

# Collects info that is specific to all DW and WF and Secondary Management Servers

    Ram Collect_OMEventLog   
    Ram Collect_SystemCenterRegValues
    Ram Collect_SystemCenterRegPermissions
    Ram Collect_MGRegistryValues
    Ram Collect_SCSMVersion
    Ram Collect_ScomAgent
    Ram Collect_SPNs
    Ram Collect_Test_LocalOMSDK
    Ram Collect_Test_LocalOMSDK_Response
    Ram Collect_ConnectedSDKUsersCount
    Ram Collect_WindowsErrorReporting

    Ram Collect_HealthServiceStateFolder
    Ram Collect_SCSMInstallationFilesInfo
    Ram Collect_SCSMSetupLogFiles

    Ram Collect_SMTraceFiles
    Ram Collect_OMTraceFiles

    Ram Collect_SCSMRunAsAccounts
    Collect_SCSMUserRoles_Async
    

    Ram Collect_SCSMFilesInfoFromSeveralPlaces
}