function Collect_SQL_DWStagingAndConfig() {
    $SQL_SCSM_DW =@{}
    $SQL_SCSM_DW['SQL_InfraBatch'] = @'
select p.ProcessName, b.StatusId, * 
from infra.Batch b inner join infra.Process p on b.ProcessId = p.ProcessId
	inner join infra.ProcessCategory pc on p.ProcessCategoryId=pc.ProcessCategoryId 
where b.StatusId!=6 and b.StatusId!=3
'@
    $SQL_SCSM_DW['SQL_InfraWorkItem'] = @'
select pm.VertexName, wi.StatusId as WIStatus,b.StatusId as BatchStatus, p.ProcessName,p.ProcessDescription,ErrorSummary,* 
from Infra.WorkItem wi
	inner join infra.ProcessModule pm on wi.ProcessModuleId=pm.ProcessModuleId
	inner join infra.Batch b on wi.BatchId = b.BatchId
	inner join infra.Process p on b.ProcessId = p.ProcessId
where wi.StatusId !=6 and wi.StatusId!=3
 order by 14 desc
'@
    $SQL_SCSM_DW['SQL_InfraWorkItem_ForActiveBatches'] = @'
select pm.VertexName, wi.StatusId as WIStatus,b.StatusId as BatchStatus, p.ProcessName,p.ProcessDescription,ErrorSummary,* 
from Infra.WorkItem wi
	inner join infra.ProcessModule pm on wi.ProcessModuleId=pm.ProcessModuleId
	inner join infra.Batch b on wi.BatchId = b.BatchId
	inner join infra.Process p on b.ProcessId = p.ProcessId
where b.StatusId not in (3,6)
order by 14 desc
'@
    $SQL_SCSM_DW['SQL_InfraWorkItemDAG'] = @'
select dag.BatchId, p.ProcessName, b.StatusId as BatchStatus, dag.WorkItemId, wi.StatusId as WIStatus, pm.VertexName, dag.ParentWorkItemId as WaitsForParentWI, wiP.StatusId as ParentWIStatus, pmP.VertexName as WaitsForParentVertexName
from infra.WorkItemDAG dag
inner join infra.Batch b on dag.Batchid=b.BatchId inner join infra.Process p on b.ProcessId = p.ProcessId
inner join infra.WorkItem wi on dag.WorkItemId = wi.WorkItemId inner join infra.ProcessModule pm on wi.ProcessModuleId = pm.ProcessModuleId
inner join infra.WorkItem wiP on dag.ParentWorkItemId = wiP.WorkItemId inner join infra.ProcessModule pmP on wiP.ProcessModuleId = pmP.ProcessModuleId
where dag.BatchId in (select BatchId from infra.Batch where StatusId != 3) order by dag.BatchId, pm.ModuleLevel desc
'@
    $SQL_SCSM_DW['SQL_LockDetails'] = @'
Select * from lockdetails
'@
    $SQL_SCSM_DW['SQL_DeploySequenceView'] = @'
select * from DeploySequenceView where DeploymentStatusId!=6
'@
    $SQL_SCSM_DW['SQL_DeploySequenceStaging'] = @'
select * from DeploySequenceStaging
'@
    $SQL_SCSM_DW['SQL_DeployItemStaging'] = @'
select statusid, outcome,* from DeployItemStaging where StatusId!=6 order by 1
'@
    $SQL_SCSM_DW['SQL_InfraProcess'] = @'
select * from infra.Process order by ProcessId
'@
    $SQL_SCSM_DW['SQL_InfraProcessHistory'] = @'
select * from infra.ProcessHistory order by ProcessId
'@
    $SQL_SCSM_DW['SQL_InfraBatch_Recent20000'] = @'
select top 20000 p.ProcessName,b.* from infra.Batch b left join infra.Process p on b.ProcessId=p.ProcessId order by b.BatchId desc
'@
    $SQL_SCSM_DW['SQL_InfraBatchHistory_Recent20000'] = @'
select top 20000 p.ProcessName,bh.* from infra.BatchHistory bh left join infra.Process p on bh.ProcessId=p.ProcessId order by bh.BatchId desc
'@
    $SQL_SCSM_DW['SQL_InfraWorkItem_Recent20000'] = @'
select top 20000 pm.VertexName,p.ProcessName,wi.* from infra.WorkItem wi left join infra.ProcessModule pm on wi.ProcessModuleId=pm.ProcessModuleId left join infra.Process p on pm.ProcessId=p.ProcessId order by wi.WorkItemId desc
'@
    $SQL_SCSM_DW['SQL_InfraWorkItemHistory_Recent20000'] = @'
select top 20000 pm.VertexName,p.ProcessName,wih.* from infra.WorkItemHistory wih left join infra.ProcessModule pm on wih.ProcessModuleId=pm.ProcessModuleId left join infra.Process p on pm.ProcessId=p.ProcessId order by wih.WorkItemId desc
'@
    $SQL_SCSM_DW['SQL_SSRS_Info'] = @'
select DataService_98B2DDF9_D9FD_9297_85D3_FCF36F1D016B as SsrsUrl from MT_Microsoft$SystemCenter$ResourceAccessLayer$SrsResourceStore
'@
    $SQL_SCSM_DW['SQL_SSAS_Info'] = @'
select Server_48B308F9_CF0E_0F74_83E1_0AEB1B58E2FA as SsasServerName,DataService_98B2DDF9_D9FD_9297_85D3_FCF36F1D016B as SsasDBName from MT_Microsoft$SystemCenter$ResourceAccessLayer$ASResourceStore
'@
    $SQL_SCSM_DW['SQL_etl.WarehouseEntity'] = @'
select * from etl.WarehouseEntity
'@
    $SQL_SCSM_DW['SQL_etl.WarehouseColumn'] = @'
select * from etl.WarehouseColumn
'@
    $SQL_SCSM_DW['SQL_etl.WarehouseModule'] = @'
select * from etl.WarehouseModule
'@
    $SQL_SCSM_DW['SQL_etl.WarehouseModuleDependency'] = @'
select * from etl.WarehouseModuleDependency
'@
    $SQL_SCSM_DW['SQL_etl.WarehouseModuleDependency_Combined'] = @'
select wm.ModuleName,we.WarehouseEntityName ,* 
from etl.WarehouseModuleDependency wmd
left join etl.WarehouseEntity we on wmd.WarehouseEntityId=we.WarehouseEntityId
left join etl.WarehouseModule wm on wmd.ModuleId=wm.ModuleId
left join etl.WarehouseModuleType wmt on wm.ModuleTypeId=wmt.ModuleTypeId
left join etl.Source s on we.SourceId=s.SourceId
left join etl.WarehouseEntityType wet on we.WarehouseEntityTypeId=wet.WarehouseEntityTypeId
order by 1,2
'@
    $SQL_SCSM_DW['SQL_DW_DataSources'] = @'
select DataSourceName_AC09B683_AE61_BDCA_6383_2007DB60859D as DataSourceName
,lt_DST.LTValue as DataSourceType
,DateRegistered_E3D84601_0917_3E29_5524_74CDFDEDB077 as DateRegistered
,lt_RegStatus.LTValue as RegistrationStatus
,ds.DatabaseServer_CD2D9C2A_39C2_CE05_D84C_AC42E429D191 as SqlInstance
,ds.Database_D59DC40A_E438_1A05_C231_E3BD50E5DD44 as DbName
,ds.SdkServer_0E227991_743F_4854_FF8B_273C1688DFEB as SDKServerName
,DS.* 
from MTV_Microsoft$SystemCenter$DataWarehouse$CMDBSource DS
left join LocalizedText lt_DST on DS.DatasourceType_284CCCB2_4410_14D1_B5F9_7469B26FB5C5 = lt_DST.LTStringId and lt_DST.LanguageCode='ENU' and lt_DST.LTStringType=1
left join LocalizedText lt_RegStatus on DS.RegistrationStatus_7B26B8DE_F3D4_6CF3_5280_60DCD1CE3DDB = lt_RegStatus.LTStringId and lt_RegStatus.LanguageCode='ENU' and lt_RegStatus.LTStringType=1
'@
    $SQL_SCSM_DW['SQL_SynchronizationJobDetails'] = @'
--This shows the Job Progress values and Synchronization details list of MPSyncJob in Console DW/Jobs/MpSyncJob
DECLARE @Path TABLE
(
S uniqueidentifier,
CS int,
T0 uniqueidentifier,
CT0 int,
T1 uniqueidentifier,
CT1 int
);
INSERT INTO @Path
SELECT [PC].[S],0 AS CS,[PC].[T0],1 AS CT0,[PC].[T1],2 AS CT1
FROM (SELECT [S].[BaseManagedEntityId] AS [S],0 AS CS,[R0].[TargetEntityId] AS [T0],1 AS CRT0,[R1].[TargetEntityId] AS [T1],2 AS CRT1
FROM dbo.TypedManagedEntity AS S 
 LEFT OUTER JOIN dbo.Relationship AS R0 
     ON (R0.[SourceEntityId] = S.[BaseManagedEntityId]
     AND R0.[RelationshipTypeId] = (select RelationshipTypeId from RelationshipType rst where RelationshipTypeName='SynchronizationForSourceManagementPack') 
     AND R0.[IsDeleted] = 0)
 LEFT OUTER JOIN dbo.Relationship AS R1 
     ON (R1.[SourceEntityId] = S.[BaseManagedEntityId]
     AND R1.[RelationshipTypeId] = (select RelationshipTypeId from RelationshipType rst where RelationshipTypeName='SynchronizationForSource') 
     AND R1.[IsDeleted] = 0)
WHERE (S.[ManagedTypeId] = (select ManagedTypeId from ManagedType where TypeName = 'Microsoft.SystemCenter.DataWarehouse.SynchronizationLog') 
     AND S.[IsDeleted] = 0)) AS PC OPTION (KEEP PLAN)
declare @BatchId int, @DataSource nvarchar(max), @ManagementPack nvarchar(max), @Status nvarchar(max), @MPVersion nvarchar(max), @key nvarchar(max)
declare @Result Table (BatchId int, DataSource nvarchar(max), ManagementPack nvarchar(max), Status nvarchar(max), MPVersion nvarchar(max), [key] nvarchar(max))
declare c cursor local FORWARD_ONLY READ_ONLY for
	SELECT 
	SLOG.BatchId_AD2C9445_8EFE_29BB_C0B9_D2D5A3CF9FF1 as BatchId
	,DwDataSource.DataSourceName_AC09B683_AE61_BDCA_6383_2007DB60859D as DataSource
	,MP.ManagementPackName_BC9C558E_DA29_B720_4A0F_FEF17184671F as ManagementPack
	,lt.LTValue as Status
	,mp.ManagementPackVersion_81B2EA0C_5781_76A5_298B_52EE32A8C93F as MPVersion
	,cast(DwDataSource.DataSourceName_AC09B683_AE61_BDCA_6383_2007DB60859D as nvarchar(max))+cast(MP.ManagementPackId_11A9EC2C_EA14_2995_9F96_CEE1C71F28F6 as nvarchar(max)) as [key]  
	FROM @Path AS PC 
	inner join dbo.MTV_Microsoft$SystemCenter$DataWarehouse$SynchronizationLog AS SLog on PC.S = SLOG.BaseManagedEntityId
	inner join LocalizedText lt on SLog.Action_E1ADF345_0F5E_E972_EB9A_1A4056B66E66 = lt.LTStringId and LTStringType=1 and lt.LanguageCode='ENU'
	inner join  MTV_Microsoft$SystemCenter$DataWarehouse$ManagementPack as MP on PC.T0 = MP.BaseManagedEntityId
	inner join MTV_Microsoft$SystemCenter$DataWarehouse$CMDBSource as DwDataSource on PC.T1 = DwDataSource.BaseManagedEntityId
	order by 4,3,2
open c; while 1=1 begin; fetch c into @BatchId, @DataSource, @ManagementPack, @Status, @MPVersion, @key ; if @@FETCH_STATUS<>0 break;

	if (select count(*) from @Result where [key] = @key) > 0
    begin
        declare @thisbatchid int = @BatchId
        declare @existingbatchid int; select @existingbatchid=BatchId from @Result where [key] = @key

        if (@thisbatchid > @existingbatchid)
        begin            
			delete @Result where [key] = @key
			insert into @Result Select @BatchId, @DataSource, @ManagementPack, @Status, @MPVersion, @key
        end
        else if (@thisbatchid = @existingbatchid)
        begin                                                                     
            
                if @Status = 'Associated' or @Status = 'Disassociated'                
                begin
                    delete @Result where [key] = @key
					insert into @Result Select @BatchId, @DataSource, @ManagementPack, @Status, @MPVersion, @key
                end            
        end                                                                 
    end
    else
    begin
        insert into @Result Select @BatchId, @DataSource, @ManagementPack, @Status, @MPVersion, @key
    end 

end; close c; deallocate c;

--That's the Job Progress area in Console DW/Jobs/MpSyncJob
select cast(sum(case when Status in ('Associated','Disassociated') then 1 else 0 end) as nvarchar(max)) +'/'+ cast(count(*) as nvarchar(max)) as [Job Progress]
from @Result

--That's the list in Console DW/Jobs/MpSyncJob/Synchronization Job Details
--sorted by Status descending order, so that incomplete syncs will appear at the top.
--ignore the last column, it's only for debugging purposes.
select * from @Result
order by 4 desc,3,2,5 
'@

    # We assume that DwRep and DWDatamart databasases are on the same SQL instance as DWStagingAndConfig
    $SQL_SCSM_DW['SQL_NewestWorkItemsInDW'] = @'
--IR
select * from (select top 1 'IR in DWRepository' as 'WI type',Id as 'Newest ID',CreatedDate as 'Created at', datediff(MINUTE,CreatedDate,GETUTCDATE()) as 'Minutes Behind' from DWRepository.dbo.IncidentDim where IncidentDimKey!=0 order by 3 desc) as sub1 
union all
select * from (select top 1 'IR in DWDataMart' as 'WI type'  ,Id as 'Newest ID',CreatedDate as 'Created at', datediff(MINUTE,CreatedDate,GETUTCDATE()) as 'Minutes Behind' from DWDataMart.dbo.IncidentDim where IncidentDimKey!=0 order by 3 desc) as sub1 
--SR
select * from (select top 1 'SR in DWRepository' as 'WI type',Id as 'Newest ID',CreatedDate as 'Created at', datediff(MINUTE,CreatedDate,GETUTCDATE()) as 'Minutes Behind' from DWRepository.dbo.ServiceRequestDim where ServiceRequestDimKey!=0 order by 3 desc) as sub1 
union all
select * from (select top 1 'SR in DWDataMart' as 'WI type'  ,Id as 'Newest ID',CreatedDate as 'Created at', datediff(MINUTE,CreatedDate,GETUTCDATE()) as 'Minutes Behind' from DWDataMart.dbo.ServiceRequestDim where ServiceRequestDimKey!=0 order by 3 desc) as sub1 
--CR
select * from (select top 1 'CR in DWRepository' as 'WI type',Id as 'Newest ID',CreatedDate as 'Created at', datediff(MINUTE,CreatedDate,GETUTCDATE()) as 'Minutes Behind' from DWRepository.dbo.ChangeRequestDim where ChangeRequestDimKey!=0 order by 3 desc) as sub1 
union all
select * from (select top 1 'CR in DWDataMart' as 'WI type'  ,Id as 'Newest ID',CreatedDate as 'Created at', datediff(MINUTE,CreatedDate,GETUTCDATE()) as 'Minutes Behind' from DWDataMart.dbo.ChangeRequestDim where ChangeRequestDimKey!=0 order by 3 desc) as sub1 

'@
    $SQL_SCSM_DW['SQL_OldestWorkItemsInDW'] = @'
select * from (select top 1 'IR in DWRepository' as 'WI type',Id as 'Oldest ID',CreatedDate as 'Created at' from DWRepository.dbo.IncidentDim where IncidentDimKey!=0 order by 3 ) as sub1 
union all
select * from (select top 1 'IR in DWDataMart' as 'WI type'  ,Id as 'Oldest ID',CreatedDate as 'Created at' from DWDataMart.dbo.IncidentDim where IncidentDimKey!=0 order by 3 ) as sub1 

select * from (select top 1 'SR in DWRepository' as 'WI type',Id as 'Oldest ID',CreatedDate as 'Created at' from DWRepository.dbo.ServiceRequestDim where ServiceRequestDimKey!=0 order by 3 ) as sub1 
union all
select * from (select top 1 'SR in DWDataMart' as 'WI type'  ,Id as 'Oldest ID',CreatedDate as 'Created at' from DWDataMart.dbo.ServiceRequestDim where ServiceRequestDimKey!=0 order by 3 ) as sub1 

select * from (select top 1 'CR in DWRepository' as 'WI type',Id as 'Oldest ID',CreatedDate as 'Created at' from DWRepository.dbo.ChangeRequestDim where ChangeRequestDimKey!=0 order by 3 ) as sub1 
union all
select * from (select top 1 'CR in DWDataMart' as 'WI type'  ,Id as 'Oldest ID',CreatedDate as 'Created at' from DWDataMart.dbo.ChangeRequestDim where ChangeRequestDimKey!=0 order by 3 ) as sub1 

'@ 
    $SQL_SCSM_DW['SQL_WorkItemsInDW_ByMonth'] = @'
--IR
select coalesce(sub1DwRep.year,sub1DwDm.year) as Year, coalesce(sub1DwRep.month,sub1DwDm.month) as Month,'IR' as 'WI Type', coalesce(sub1DwRep.count,0) as "Count in DWRep", coalesce(sub1DwDM.count,0) as "Count in DWDataMart", coalesce(sub1DwDM.count,0) - coalesce(sub1DwRep.count,0) as "Diff (DM-Rep)" from (
	select datepart(year,CreatedDate) year,datepart(month,CreatedDate) month,count(*) count
	from DWRepository.dbo.IncidentDim
	where IncidentDimKey!=0
	group by datepart(year,CreatedDate),datepart(month,CreatedDate)
) as sub1DwRep
full outer join (
	select datepart(year,CreatedDate) year,datepart(month,CreatedDate) month,count(*) count
	from DWDataMart.dbo.IncidentDim
	where IncidentDimKey!=0
	group by datepart(year,CreatedDate),datepart(month,CreatedDate)
) as sub1DwDM
on sub1DwRep.year = sub1DwDM.year and sub1DwRep.month = sub1DwDM.month
order by coalesce(sub1DwRep.year,sub1DwDm.year), coalesce(sub1DwRep.month,sub1DwDm.month) 
--SR
select coalesce(sub1DwRep.year,sub1DwDm.year) as Year, coalesce(sub1DwRep.month,sub1DwDm.month) as Month,'SR' as 'WI Type', coalesce(sub1DwRep.count,0) as "Count in DWRep", coalesce(sub1DwDM.count,0) as "Count in DWDataMart", coalesce(sub1DwDM.count,0) - coalesce(sub1DwRep.count,0) as "Diff (DM-Rep)" from (
	select datepart(year,CreatedDate) year,datepart(month,CreatedDate) month,count(*) count
	from DWRepository.dbo.ServiceRequestDim
	where ServiceRequestDimKey!=0
	group by datepart(year,CreatedDate),datepart(month,CreatedDate)
) as sub1DwRep
full outer join (
	select datepart(year,CreatedDate) year,datepart(month,CreatedDate) month,count(*) count
	from DWDataMart.dbo.ServiceRequestDim
	where ServiceRequestDimKey!=0
	group by datepart(year,CreatedDate),datepart(month,CreatedDate)
) as sub1DwDM
on sub1DwRep.year = sub1DwDM.year and sub1DwRep.month = sub1DwDM.month
order by coalesce(sub1DwRep.year,sub1DwDm.year), coalesce(sub1DwRep.month,sub1DwDm.month) 
--CR
select coalesce(sub1DwRep.year,sub1DwDm.year) as Year, coalesce(sub1DwRep.month,sub1DwDm.month) as Month,'CR' as 'WI Type', coalesce(sub1DwRep.count,0) as "Count in DWRep", coalesce(sub1DwDM.count,0) as "Count in DWDataMart", coalesce(sub1DwDM.count,0) - coalesce(sub1DwRep.count,0) as "Diff (DM-Rep)" from (
	select datepart(year,CreatedDate) year,datepart(month,CreatedDate) month,count(*) count
	from DWRepository.dbo.ChangeRequestDim
	where ChangeRequestDimKey!=0
	group by datepart(year,CreatedDate),datepart(month,CreatedDate)
) as sub1DwRep
full outer join (
	select datepart(year,CreatedDate) year,datepart(month,CreatedDate) month,count(*) count
	from DWDataMart.dbo.ChangeRequestDim
	where ChangeRequestDimKey!=0
	group by datepart(year,CreatedDate),datepart(month,CreatedDate)
) as sub1DwDM
on sub1DwRep.year = sub1DwDM.year and sub1DwRep.month = sub1DwDM.month
order by coalesce(sub1DwRep.year,sub1DwDm.year), coalesce(sub1DwRep.month,sub1DwDm.month) 
'@ 

    if ($SQLDatabase_SCSMDW_Rep -ne "DwRepository"){
        $SQL_SCSM_DW['SQL_NewestWorkItemsInDW'] = $SQL_SCSM_DW['SQL_NewestWorkItemsInDW'] -replace 'DwRepository.', ($SQLDatabase_SCSMDW_Rep +'.' )
        $SQL_SCSM_DW['SQL_OldestWorkItemsInDW'] = $SQL_SCSM_DW['SQL_OldestWorkItemsInDW'] -replace 'DwRepository.', ($SQLDatabase_SCSMDW_Rep +'.' )
        $SQL_SCSM_DW['SQL_WorkItemsInDW_ByMonth'] = $SQL_SCSM_DW['SQL_WorkItemsInDW_ByMonth'] -replace 'DwRepository.', ($SQLDatabase_SCSMDW_Rep +'.' )
        $SQL_SCSM_DW['SQL_FKIssuesInDW'] = $SQL_SCSM_DW['SQL_FKIssuesInDW'] -replace 'DwRepository.', ($SQLDatabase_SCSMDW_Rep +'.' )
    }
    if ($SQLDatabase_SCSMDW_DM -ne "DwDataMart"){
        $SQL_SCSM_DW['SQL_NewestWorkItemsInDW'] = $SQL_SCSM_DW['SQL_NewestWorkItemsInDW'] -replace 'DwDataMart.', ($SQLDatabase_SCSMDW_DM +'.' )
        $SQL_SCSM_DW['SQL_OldestWorkItemsInDW'] = $SQL_SCSM_DW['SQL_OldestWorkItemsInDW'] -replace 'DwDataMart.', ($SQLDatabase_SCSMDW_DM +'.' )
        $SQL_SCSM_DW['SQL_WorkItemsInDW_ByMonth'] = $SQL_SCSM_DW['SQL_WorkItemsInDW_ByMonth'] -replace 'DwDataMart.', ($SQLDatabase_SCSMDW_DM +'.' )        
    }

    foreach($SQL_SCSM_DW_Text in $SQL_SCSM_DW.Keys) {        
        RamSB -outputString $SQL_SCSM_DW_Text -pscriptBlock `
        {  
            SaveSQLResultSetsToFiles $SQLInstance_SCSMDW $SQLDatabase_SCSMDW ($SQL_SCSM_DW[$SQL_SCSM_DW_Text]) "$SQL_SCSM_DW_Text.csv"
        }
    }

}