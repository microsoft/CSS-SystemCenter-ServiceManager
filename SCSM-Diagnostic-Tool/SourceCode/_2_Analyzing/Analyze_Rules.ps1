function Analyze_Rules() {

Analyze_ForDWAndWFAndSecondary
Analyze_ForWFAndSecondary
Analyze_ForDWAndWF
Analyze_ForWF
Analyze_ForDW
Analyze_ForSecondary
Analyze_ForConsole
Analyze_ForPortal
Analyze_ForALL

#region Navigate through all collected files and share finding+suggestions (optional: they can be later moved up to their related section )

 #region Checking folders
  #ERRORLOG -> #TODO
  #Health Service State -> to be consumed by engineer manually, if needed
  #LocaleMetaData -> to be used while processing event logs
  #MPXml -> to be consumed by engineer manually, if needed
  #OpsMgrTrace -> to be consumed by engineer manually, if needed
  #SCSM_SetupLogFiles -> #TODO
  #SMTrace -> to be consumed by engineer manually, if needed
  #TLS -> #TODO
 #endregion

 #region Checking files, which are not procesed YET

 #Application.evtx -> first get last SCSM restart datetime (based on events in OM log) then check here  #todo
 #ConnectorEclLogSettings.txt -> #TODO
 #DotNetFwV3.5.txt -> no need to check this file #todo: or may be just check if 3.5 is installed
 #DotNetFwV4.txt -> should be >= 4.5.1 but ideally better to have >= 4.7 or even 4.8, code like below would help #todo
    <#
    

Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full' |
Get-ItemProperty -name Version,Release -EA 0 |
Select  @{
  name="Version"
  expression={
      switch -regex ($_.Release) {
        "378389" { [Version]"4.5" }
        "378675|378758" { [Version]"4.5.1" }
        "379893" { [Version]"4.5.2" }
        "393295|393297" { [Version]"4.6" }
        "394254|394271" { [Version]"4.6.1" }
        "394802|394806" { [Version]"4.6.2" }
        "460798|460805" { [Version]"4.7"  }
        "461308|461310" { [Version]"4.7.1" }
       "461808|461814"{ [Version]4.7.2 }
        "528040|528049|528372" { [Version]"4.8"}       
      }
    }
} 

    #>
 #EmailSendingRules.txt -> #TODO  

 #Get-Process_OnlyActiveOnes.txt -> #TODO
 #Get-Process_Top10_ByCPU.txt -> #TODO
 #Get-Process_Top10_ByWorkingSet.txt -> #TODO
 #Get-Process_WithAllDetails.txt -> #TODO
 #Get-Process_WithCurrentCPU.txt -> #TODO

 #Get-SCDWInfraLocation.txt -> #TODO
 #Get-SCDWJob.csv -> #TODO
 #Get-SCDWJob.txt -> #TODO
 #Get-SCDWJob_NumberOfBatches_5.txt -> #TODO
 #Get-SCDWJobSchedule.csv -> #TODO
 #Get-SCDWJobSchedule.txt -> #TODO
 #Get-SCSMAllowList.txt -> #TODO
 #Get-SCSMChannel.txt -> #TODO
 #Get-SCSMConnector.txt -> #TODO
 #Get-SCSMEmailTemplate.txt -> #TODO
 #Get-SCSMRunAsAccount.txt -> #TODO
 #Get-SCSMSetting.txt -> #TODO
 #Get-SCSMUserRole_WithAllDetails.csv -> #TODO
 #Get-SCSMWorkflow.txt -> #TODO
 #Get-UtcDate.txt -> #TODO
 #IsRunningAsElevated.txt -> #TODO
 #LanguageInfo.txt -> #TODO
 #LocalSecurityPolicy_UserRightsAssignment.txt -> #TODO
 #MachineStartTime.txt -> #TODO
 #msinfo32.txt -> #TODO
 #netstat_abof.txt -> #TODO
 #OperationsManager.evtx -> #TODO
 #Ping_FromSM_ToDW.txt -> #TODO
 #Ping_FromSM_ToSQL.txt -> #TODO
 #Ping_FromSMDW_ToSQL.txt -> #TODO
 #Ping_localhost_5724.txt -> #TODO
 #ProgramVersions.txt -> #TODO
 #PSCompatibleVersions.txt -> #TODO
 #PSVersionTable.txt -> #TODO
 #SCSM_Files.csv -> #TODO
 #SCSM_Version.txt -> #TODO
 #ScsmRolesFound.txt -> #TODO
 #ServerManagementGroups.regValues.txt -> #TODO
 #spnHS.txt -> #TODO
 #spnSDK.txt -> #TODO
 #spnX.txt -> #TODO
 #SQL_AdvancedTypeProjections.csv -> #TODO
 #SQL_BackupInfo.csv -> #TODO
 #SQL_CurrentlyRunningQueries.csv -> #TODO
 #SQL_database_scoped_configurations_IfGe2016.csv -> #TODO
 #SQL_DatabaseFiles.csv -> #TODO
 #SQL_Databases.csv -> #TODO
 #SQL_Date.csv -> #TODO
 #SQL_Dbcc_Useroptions.csv -> #TODO
 #SQL_DbUsersInfo.csv -> #TODO
 #SQL_DCM.csv -> #TODO
 #SQL_DelayedImplicitPermissions.csv -> #TODO
 #SQL_DeployItemStaging.csv -> #TODO
 #SQL_DeploySequenceStaging.csv -> #TODO
 #SQL_DeploySequenceView.csv -> #TODO
 #SQL_dm_os_schedulers.csv -> #TODO
 #SQL_dm_os_sys_info.csv -> #TODO
 #SQL_dm_os_wait_stats.csv -> #TODO
 #SQL_DW_DataSources.csv -> #TODO
 #SQL_DwDMDataRetention.csv -> #TODO
 #SQL_DWEtlConfiguration_CMDWDataMart.csv -> #TODO
 #SQL_DWEtlConfiguration_DWDataMart.csv -> #TODO
 #SQL_DWEtlConfiguration_DWRep.csv -> #TODO
 #SQL_DWEtlConfiguration_OMDWDataMart.csv -> #TODO
 #SQL_DWEtlWarehouseEntityGroomingHistory_CMDWDataMart.csv -> #TODO
 #SQL_DWEtlWarehouseEntityGroomingHistory_DWDataMart.csv -> #TODO
 #SQL_DWEtlWarehouseEntityGroomingHistory_DWRep.csv -> #TODO
 #SQL_DWEtlWarehouseEntityGroomingHistory_OMDWDataMart.csv -> #TODO
 #SQL_DWEtlWarehouseEntityGroomingInfo_CMDWDataMart.csv -> #TODO
 #SQL_DWEtlWarehouseEntityGroomingInfo_DWDataMart.csv -> #TODO
 #SQL_DWEtlWarehouseEntityGroomingInfo_DWRep.csv -> #TODO
 #SQL_DWEtlWarehouseEntityGroomingInfo_OMDWDataMart.csv -> #TODO
 #SQL_DWFactConstraintsIssue_CMDWDatamart.csv -> #TODO
 #SQL_DWFactConstraintsIssue_CMDWDatamart_ForDebugging.csv -> #TODO
 #SQL_DWFactConstraintsIssue_DWDatamart.csv -> #TODO
 #SQL_DWFactConstraintsIssue_DWDatamart_ForDebugging.csv -> #TODO
 #SQL_DWFactConstraintsIssue_DWRep.csv -> #TODO
 #SQL_DWFactConstraintsIssue_DWRep_ForDebugging.csv -> #TODO
 #SQL_DWFactConstraintsIssue_OMDWDatamart.csv -> #TODO
 #SQL_DWFactConstraintsIssue_OMDWDatamart_ForDebugging.csv -> #TODO
 #SQL_DWFactEntityUpgradeIssue_CMDWDataMart.csv -> #TODO
 #SQL_DWFactEntityUpgradeIssue_DWDataMart.csv -> #TODO
 #SQL_DWFactEntityUpgradeIssue_DWRep.csv -> #TODO
 #SQL_DWFactEntityUpgradeIssue_OMDWDataMart.csv -> #TODO
 #SQL_etl.WarehouseColumn.csv -> #TODO
 #SQL_etl.WarehouseEntity.csv -> #TODO
 #SQL_etl.WarehouseModule.csv -> #TODO
 #SQL_etl.WarehouseModuleDependency.csv -> #TODO
 #SQL_etl.WarehouseModuleDependency_Combined.csv -> #TODO
 #SQL_Event1209.csv -> #TODO
 #SQL_FKIssuesInDW_CMDWDatamart.csv -> #TODO
 #SQL_FKIssuesInDW_DWDatamart.csv -> #TODO
 #SQL_FKIssuesInDW_OMDWDatamart.csv -> #TODO
 #SQL_ForRFH_430445.csv -> #TODO
 #SQL_FragmentationInfo.csv -> #TODO
 #SQL_FromSMDB_MOMManagementGroupInfo.csv -> #TODO
 #SQL_FromSMDB_PatchInfo.csv -> #TODO
 #SQL_FromSMDB_WorkItemsCount.csv -> #TODO
 #SQL_FromSMDB_WorkItemsCount_ByMonth.csv -> #TODO
 #SQL_Get-SCSMUserRole.csv -> #TODO
 #SQL_GroomingConfiguration.csv -> #TODO
 #SQL_GroomingConfiguration_Log.csv -> #TODO
 #SQL_Indexes.csv -> #TODO
 #SQL_indexes_CMDWDataMart.csv -> #TODO
 #SQL_indexes_DWDataMart.csv -> #TODO
 #SQL_indexes_DWRep.csv -> #TODO
 #SQL_indexes_OMDWDataMart.csv -> #TODO
 #SQL_information_schema_columns.csv -> #TODO
 #SQL_information_schema_columns_CMDWDataMart.csv -> #TODO
 #SQL_information_schema_columns_DWDataMart.csv -> #TODO
 #SQL_information_schema_columns_DWRep.csv -> #TODO
 #SQL_information_schema_columns_OMDWDataMart.csv -> #TODO
 #SQL_InfraBatch.csv -> #TODO
 #SQL_InfraBatch_Recent20000.csv -> #TODO
 #SQL_InfraBatchHistory_Recent20000.csv -> #TODO
 #SQL_InfraProcess.csv -> #TODO
 #SQL_InfraProcessHistory.csv -> #TODO
 #SQL_InfraWorkItem.csv -> #TODO
 #SQL_InfraWorkItem_Recent20000.csv -> #TODO
 #SQL_InfraWorkItemDAG.csv -> #TODO
 #SQL_InfraWorkItemHistory_Recent20000.csv -> #TODO
 #SQL_LockDetails.csv -> #TODO
 #SQL_LoginsInfo.csv -> #TODO
 #SQL_ManagedType.csv -> #TODO
 #SQL_ManagedTypeProperty.csv -> #TODO
 #SQL_ManagementPack.csv -> #TODO
 #SQL_ManagementPackHistory.csv -> #TODO
 #SQL_NewestWorkItemsInDW.csv -> #TODO
 #SQL_NotificationTemplate.csv -> #TODO
 #SQL_OldestWorkItemsInDW.csv -> #TODO
 #SQL_PartitionAndGroomingSettings.csv -> #TODO
 #SQL_PatchInfo.csv -> #TODO
 #SQL_Queues.csv -> #TODO
 #SQL_RegisteredDwInfo.csv -> #TODO
 #SQL_Rules.csv -> #TODO
 #SQL_ScsmMonitoringMP_Grooming.csv -> #TODO
 #SQL_ScsmMonitoringMP_Lfx.csv -> #TODO
 #SQL_ScsmMonitoringMP_Workflows.csv -> #TODO
 #SQL_SMDB_Info.txt -> #TODO
 #SQL_sp_helplogins.csv -> #TODO
 #SQL_SSAS_Info.csv -> #TODO
 #SQL_SSRS_Info.csv -> #TODO
 #SQL_SynchronizationJobDetails.csv -> #TODO
 #SQL_TableSizeInfo_CMDWDataMart.csv -> #TODO
 #SQL_TableSizeInfo_DWDataMart.csv -> #TODO
 #SQL_TableSizeInfo_DWRepository.csv -> #TODO
 #SQL_TableSizeInfo_OMDWDataMart.csv -> #TODO
 #SQL_UsersWithMissingImpliedPermissionsOnReviewActivities.csv -> #TODO
 #SQL_UsersWithMissingImpliedPermissionsOnWorkItems.csv -> #TODO
 #SQL_WF_and_2ndaryMS.csv -> #TODO
 #SQL_WorkItemsCount.csv -> #TODO
 #SQL_WorkItemsCount_ByMonth.csv -> #TODO
 #SQL_WorkItemsInDW_ByMonth.csv -> #TODO
 #SsasCubes.txt -> #TODO
 #SsasDataSources.txt -> #TODO
 #SsasDataSourceViews.txt -> #TODO
 #SsasDB.txt -> #TODO
 #SsasDimensions.txt -> #TODO
 #Ssrs-AllItems.csv -> #TODO
 #Ssrs-TestUrl.txt -> #TODO
 #Ssrs-version.txt -> #TODO
 #System.evtx -> #TODO
 #SystemCenter.regPermissions.txt -> #TODO
 #SystemCenter.regValues.txt -> #TODO
 #Telnet_FromSM_ToDW.txt -> #TODO
 #Telnet_FromSM_ToSQL.txt -> #TODO
 #Telnet_FromSMDW_ToSQL.txt -> #TODO
 #Telnet_localhost_5724.txt -> #TODO
 #TotalRAM.txt -> #TODO
 #Transcript*.txt -> #TODO
 #WER.regValues.txt -> #TODO
 #WER_Files.txt -> #TODO

 #endregion

#endregion

}