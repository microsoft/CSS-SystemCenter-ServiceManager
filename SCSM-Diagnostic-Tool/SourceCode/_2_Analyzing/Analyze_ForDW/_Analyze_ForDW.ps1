function Analyze_ForDW() {
#region DO NOT REMOVE THIS! Exit immediately if script does NOT run on a DW mgmt server.
if (-not (IsSourceScsmDwMgmtServer)) {
    return
}
#endregion

#Rules for SCSM DW server only 

 #region Get DB info, to be used by subsequent rules
    $linesIn_regValues = GetFileContentInSourceFolder SystemCenter.regValues.txt

    $DW_Rep_SQL_InstanceName = GetFirstLineThatStartsWith $linesIn_regValues '"RepositorySQLInstance"="'    
    $DW_Rep_SQL_InstanceName = $DW_Rep_SQL_InstanceName.Split("=")[1].Replace('"','')
    $DW_Rep_SQL_DbName = GetFirstLineThatStartsWith $linesIn_regValues '"RepositoryDatabaseName"="'
    $DW_Rep_SQL_DbName = $DW_Rep_SQL_DbName.Split("=")[1].Replace('"','')

    $DW_DM_SQL_InstanceName = GetFirstLineThatStartsWith $linesIn_regValues '"DataMartSQLInstance"="'    
    $DW_DM_SQL_InstanceName = $DW_DM_SQL_InstanceName.Split("=")[1].Replace('"','')
    $DW_DM_SQL_DbName = GetFirstLineThatStartsWith $linesIn_regValues '"DataMartDatabaseName"="'
    $DW_DM_SQL_DbName = $DW_DM_SQL_DbName.Split("=")[1].Replace('"','')

    $DW_CM_SQL_InstanceName = GetFirstLineThatStartsWith $linesIn_regValues '"CMDataMartSQLInstance"="'    
    $DW_CM_SQL_InstanceName = $DW_CM_SQL_InstanceName.Split("=")[1].Replace('"','')
    $DW_CM_SQL_DbName = GetFirstLineThatStartsWith $linesIn_regValues '"CMDataMartDatabaseName"="'
    $DW_CM_SQL_DbName = $DW_CM_SQL_DbName.Split("=")[1].Replace('"','')

    $DW_OM_SQL_InstanceName = GetFirstLineThatStartsWith $linesIn_regValues '"OMDataMartSQLInstance"="'    
    $DW_OM_SQL_InstanceName = $DW_OM_SQL_InstanceName.Split("=")[1].Replace('"','')
    $DW_OM_SQL_DbName = GetFirstLineThatStartsWith $linesIn_regValues '"OMDataMartDatabaseName"="'
    $DW_OM_SQL_DbName = $DW_OM_SQL_DbName.Split("=")[1].Replace('"','')
    #endregion

    Check_DWJobStatus_ExcludingCubes
    Check_DWJobSchedules_ExcludingCubes
    Check_CubeJobsStatusAndSchedule
    Check_MPSyncJob_Progress
    Check_DWMPDeploymentStatus
    Check_DWData_IsUpTodate
    Check_DateFormatOfExtractJobsSQLAccount
    Check_MPSyncJobConnectivity
}
