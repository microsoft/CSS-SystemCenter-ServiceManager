function Collect_FromWFAndSecondary() {
#region DO NOT REMOVE THIS! Exit immediately if script is NOT running on a WF or Secondary server
if (-not (IsThisScsmMgmtServer)) {
    return
}
#endregion

# Collects info that is specific to only WF and Secondary Management Servers

    Ram Collect_SCSMRolesFound
    Ram Collect_SCSMSettings
    Ram Collect_SCOMCIConnectorAllowList
    Ram Collect_Connectors
    Ram Collect_NotificationChannel
    Ram Collect_EmailTemplates
    Ram Collect_Workflows
    Ram Collect_EmailSendingRules
    Ram Collect_ConnectorEclLogSettings
    Ram Collect_TimeDiffBetweenMSandSQL
    Ram Collect_MPs    
#    Collect_SqlErrorLogFiles   # can take very long time. 
    Ram Collect_Test_BetweenMSandSQL 
    Ram Collect_Test_BetweenMSandDWMS

    Collect_SQL_MS_Shared
    Collect_SQL_MS_Specific

    Ram Collect_RegisteredDWEnvironmentInfo
}