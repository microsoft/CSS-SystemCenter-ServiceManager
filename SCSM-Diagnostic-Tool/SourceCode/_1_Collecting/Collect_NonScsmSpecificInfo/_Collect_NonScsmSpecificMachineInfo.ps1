function Collect_NonScsmSpecificMachineInfo() {
    
    Collect_Processes # We intentionally collect all process info before collecting anything else, in order to exclude Collector's overhead.
    Collect_MSINFO32 # we start msinfo32 immediately as a background job, because it can take long

    Collect_DotNetFWInfo_35
    Collect_DotNetFWInfo_4
    Collect_DateTime
    Collect_EnvironmentVariables
    Collect_Hotfix    
    Collect_ProgramsInfo
    Collect_LanguageInfo
    Collect_RAMInfo
    Collect_ServiceInfo
    Collect_PowerShellInfo
    Collect_HostFqdn
    Collect_Netstat    
    Collect_LocalSecurityPolicy
    Collect_TimeDiffBetweenDC
    Collect_TLS
    Collect_OSRegionSettings
    Collect_NonSMEventLogs
}