function Collect_NonScsmSpecificMachineInfo() {
    
    Ram Collect_Processes # We intentionally collect all process info before collecting anything else, in order to exclude Collector's overhead.
    Collect_MSINFO32 # we start msinfo32 immediately as a background job, because it can take long

    Ram Collect_DotNetFWInfo_35
    Ram Collect_DotNetFWInfo_4
    Ram Collect_DateTime
    Ram Collect_EnvironmentVariables
    Ram Collect_Hotfix    
    Ram Collect_ProgramsInfo
    Ram Collect_LanguageInfo
    Ram Collect_RAMInfo
    Ram Collect_ServiceInfo
    Ram Collect_PowerShellInfo
    Ram Collect_HostFqdn
    Ram Collect_Netstat    
    Ram Collect_LocalSecurityPolicy
    Ram Collect_TimeDiffBetweenDC
    Ram Collect_TLS
    Ram Collect_OSRegionSettings
    Ram Collect_NonSMEventLogs

    Ram Collect_ConfigFilesInSmFolder
}