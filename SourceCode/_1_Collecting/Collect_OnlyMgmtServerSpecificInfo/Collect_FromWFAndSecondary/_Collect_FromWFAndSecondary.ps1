function Collect_FromWFAndSecondary() {
#region DO NOT REMOVE THIS! Exit immediately if script is NOT running on a WF or Secondary server
if (-not (IsThisScsmMgmtServer)) {
    return
}
#endregion

# Collects info that is specific to only WF and Secondary Management Servers

    Collect_SCSMRolesFound
    Collect_SCSMSettings
    Collect_SCOMCIConnectorAllowList
    Collect_Connectors
    Collect_NotificationChannel
    Collect_EmailTemplates
    Collect_Workflows
    Collect_EmailSendingRules
    Collect_ConnectorEclLogSettings
    Collect_TimeDiffBetweenMSandSQL
    Collect_MPs    
    Collect_SqlErrorLogFiles
    Collect_Test_BetweenMSandSQL 
    Collect_Test_BetweenMSandDWMS

    Collect_SQL_MS_Shared
    Collect_SQL_MS_Specific

    Collect_RegisteredDWEnvironmentInfo
}