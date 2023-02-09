function Analyze_ForDW() {
#region DO NOT REMOVE THIS! Exit immediately if script does NOT run on a DW mgmt server.
if (-not (IsSourceScsmDwMgmtServer)) {
    return
}
#endregion

#Rules for SCSM DW server only 

    Check_DWJobStatus_ExcludingCubes
    Check_DWJobSchedules_ExcludingCubesAndMPSync
    Check_CubeJobsStatusAndSchedule
    Check_MPSyncJob_Progress
    Check_DWMPDeploymentStatus
    Check_DWData_IsUpTodate
    Check_DateFormatOfExtractJobsSQLAccount
    Check_MPSyncJobConnectivity
    Check_MPSyncJobSchedule
    Check_GoodDWDbBackupAvailability
}
