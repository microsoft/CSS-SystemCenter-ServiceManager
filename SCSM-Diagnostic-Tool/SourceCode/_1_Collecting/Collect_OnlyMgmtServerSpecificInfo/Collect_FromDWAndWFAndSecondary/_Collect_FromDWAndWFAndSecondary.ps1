function Collect_FromDWAndWFAndSecondary() {
#region DO NOT REMOVE THIS! Exit immediately if script is NOT running on a WF or Secondary or DW mgmt server
if (-not (IsThisAnyScsmMgmtServer)) {
    return
}
#endregion

# Collects info that is specific to all DW and WF and Secondary Management Servers

    Collect_OMEventLog   
    Collect_SystemCenterRegValues
    Collect_SystemCenterRegPermissions
    Collect_MGRegistryValues
    Collect_SCSMVersion
    Collect_ScomAgent
    Collect_SPNs
    Collect_Test_LocalOMSDK
    Collect_Test_LocalOMSDK_Response
    Collect_ConnectedSDKUsersCount
    Collect_WindowsErrorReporting

    Collect_HealthServiceStateFolder
    Collect_SCSMInstallationFilesInfo
    Collect_SCSMSetupLogFiles

    Collect_SMTraceFiles
    Collect_OMTraceFiles

    Collect_SCSMRunAsAccounts
    Collect_SCSMUserRoles
}