function Collect_SQL_MS_Specific() {

    $SQL_SCSM_MS =@{}
    $SQL_SCSM_MS['SQL_DCM']=@'

SELECT COUNT(*) AS 'Number of Updates to DCM Instances'
FROM EntityChangeLog AS ECL WITH(NOLOCK)
JOIN ManagedType AS MT
ON ECL.EntityTypeId = MT.ManagedTypeId
WHERE MT.TypeName = 'Microsoft.SystemCenter.ConfigurationManager.DCM_NonCompliance_CI' 
GO

DECLARE @MinState INT
SET @MinState = (
SELECT MIN(State)
FROM CmdbInstanceSubscriptionState AS W WITH(NOLOCK)
JOIN Rules AS R
ON W.RuleId = R.RuleId
WHERE
R.RuleEnabled <> 0 AND
W.IsPeriodicQueryEvent = 0
)
SELECT COUNT(*) AS 'UNPROCESSED Number of Updates to DCM Instances'
FROM EntityChangeLog AS ECL WITH(NOLOCK)
JOIN ManagedType AS MT
ON ECL.EntityTypeId = MT.ManagedTypeId
WHERE
ECL.EntityTransactionLogId >= @MinState AND
MT.TypeName = 'Microsoft.SystemCenter.ConfigurationManager.DCM_NonCompliance_CI' 
GO
'@
    $SQL_SCSM_MS['SQL_PatchInfo']=@'
     select '__PatchInfo__' tableName,* from [__PatchInfo__]  order by AppliedOn  desc
'@
    $SQL_SCSM_MS['SQL_NotificationTemplate']=@'
SELECT LTValue as "Notification Template Display Name",ot.*
FROM ObjectTemplate ot
inner join localizedtext lt on ot.ObjectTemplateId=lt.LTStringId and LTStringType=1 and LanguageCode='ENU'
'@
    $SQL_SCSM_MS['SQL_WorkflowMinutesBehind_Original'] = @'
DECLARE @MaxState INT, @MaxStateDate Datetime, @Delta INT, @Language nvarchar(3)
 SET @Delta = 0
 SET @Language = 'ENU'
 SET @MaxState = (
    SELECT MAX(EntityTransactionLogId)
    FROM EntityChangeLog WITH(NOLOCK)
 )
 SET @MaxStateDate = (
	SELECT TimeAdded 
	FROM EntityTransactionLog
	WHERE EntityTransactionLogId = @MaxState
)
SELECT
    LT.LTValue AS 'Display Name',
	S.State AS 'Current Workflow Watermark',
	@MaxState AS 'Current Transaction Log Watermark',
	@MaxState-S.State as Delta,
	DATEDIFF(mi,(SELECT TimeAdded 
	FROM EntityTransactionLog WITH(NOLOCK)
	WHERE EntityTransactionLogId = S.State), @MaxStateDate) AS 'Minutes Behind',
	S.EventCount,
	S.LastNonZeroEventCount,
	R.RuleName AS 'MP Rule Name',
    MT.TypeName AS 'Source Class Name',
    S.LastModified AS 'Rule Last Modified',
	S.IsPeriodicQueryEvent AS 'Is Periodic Query Subscription', 
    R.RuleEnabled AS 'Rule Enabled',    R.RuleID
 FROM CmdbInstanceSubscriptionState AS S WITH(NOLOCK)
 LEFT OUTER JOIN Rules AS R
    ON S.RuleId = R.RuleId
 LEFT OUTER JOIN ManagedType AS MT
    ON S.TypeId = MT.ManagedTypeId
 LEFT OUTER JOIN LocalizedText AS LT
	ON R.RuleId = LT.MPElementId
 WHERE
    S.State <= @MaxState - @Delta 
	AND R.RuleEnabled <> 0 
	AND LT.LTStringType = 1
	AND LT.LanguageCode = @Language
	AND S.IsPeriodicQueryEvent = 0
order by 4 desc 
'@
    $SQL_SCSM_MS['SQL_WorkflowMinutesBehind'] = @'
DECLARE @MaxState INT, @MaxStateDate Datetime, @Delta INT, @Language nvarchar(3)
 SET @Delta = 0
 SET @Language = 'ENU'
 SET @MaxState = (
    SELECT MAX(EntityTransactionLogId)
    FROM EntityChangeLog WITH(NOLOCK)
 )
 SET @MaxStateDate = (
	SELECT TimeAdded 
	FROM EntityTransactionLog
	WHERE EntityTransactionLogId = @MaxState
)
SELECT
    LT.LTValue AS 'Display Name',
	S.State AS 'Current Workflow Watermark',
	@MaxState AS 'Current Transaction Log Watermark',
	@MaxState-S.State as Delta,
	DATEDIFF(mi,(SELECT TimeAdded 
	FROM EntityTransactionLog WITH(NOLOCK)
	WHERE EntityTransactionLogId = S.State), @MaxStateDate) AS 'Minutes Behind',
	S.EventCount,
	S.LastNonZeroEventCount,
	R.RuleName AS 'MP Rule Name',
    MT.TypeName AS 'Source Class Name',
    S.LastModified AS 'Rule Last Modified',
	S.IsPeriodicQueryEvent AS 'Is Periodic Query Subscription', 
    R.RuleEnabled AS 'Rule Enabled',    R.RuleID
into #tmp
 FROM CmdbInstanceSubscriptionState AS S WITH(NOLOCK)
 LEFT OUTER JOIN Rules AS R
    ON S.RuleId = R.RuleId
 LEFT OUTER JOIN ManagedType AS MT
    ON S.TypeId = MT.ManagedTypeId
 LEFT OUTER JOIN LocalizedText AS LT
	ON R.RuleId = LT.MPElementId
 WHERE
    S.State <= @MaxState - @Delta 
	AND R.RuleEnabled <> 0 
	AND LT.LTStringType = 1
	AND LT.LanguageCode = @Language
	AND S.IsPeriodicQueryEvent = 0

select [Display Name],max([Current Workflow Watermark]) as [Current Workflow Watermark], max([Current Transaction Log Watermark]) as [Current Transaction Log Watermark], 
max(Delta) as Delta,min([Minutes Behind]) as [Minutes Behind],
[MP Rule Name], [Source Class Name], RuleId 
from #tmp
group by [Display Name], [MP Rule Name], [Source Class Name], RuleId
order by 4
'@
    $SQL_SCSM_MS['SQL_Queues'] = @'     
select dsv.DisplayName
,(select mtTarget.TypeName from  RelationshipType rst inner join ManagedType as mtTarget on rst.TargetManagedTypeId=mtTarget.ManagedTypeId where rst.SourceManagedTypeId=mt.ManagedTypeId) as WorkItemType
, mt.IsDeleted as "Q is deleted"
,(select count(*) from Relationship rs where rs.SourceEntityId=mt.ManagedTypeId and rs.IsDeleted=0) as Existing_membercount
,(select count(*) from Relationship rs where rs.SourceEntityId=mt.ManagedTypeId and rs.IsDeleted=1) as Deleted_membercount
,mt.ManagedTypeId,dsv.ManagementPackId,dsv.MPElementId,dsv.ElementName,mp.MPName,mp.MPFriendlyName--,* 
from ManagedType mt
inner join DisplayStringView dsv on mt.ManagedTypeId = dsv.LTStringId and LanguageCode='ENU'
inner join ManagementPack mp on dsv.ManagementPackId = mp.ManagementPackId
where mt.BaseManagedTypeId='31D729D9-83C5-5B36-703B-C51D54395687'
'@
    $SQL_SCSM_MS['SQL_InternalJobHistory'] = @'
Select top 4 * from InternalJobHistory where command like '%Exec dbo.p_GroomSubscriptionSpecificRECLRows 55270A70-AC47-C853-C617-236B0CFF9B4C%' order by TimeStarted desc
Select top 4 * from InternalJobHistory where command like '%Exec dbo.p_GroomSubscriptionSpecificECLRows 55270A70-AC47-C853-C617-236B0CFF9B4C%' order by TimeStarted desc
Select top 4 * from InternalJobHistory where command like '%Exec dbo.p_GroomStagedChangeLogs 55270A70-AC47-C853-C617-236B0CFF9B4C%' order by TimeStarted desc
Select top 4 * from InternalJobHistory where command like '%Exec dbo.p_GroomManagedEntity A604B942-4C7B-2FB2-28DC-61DC6F465C68%' order by TimeStarted desc
Select top 4 * from InternalJobHistory where command like '%Exec dbo.p_GroomManagedEntity E6C9CF6E-D7FE-1B5D-216C-C3F5D2C7670C%' order by TimeStarted desc
Select top 4 * from InternalJobHistory where command like '%Exec dbo.p_GroomManagedEntity D02DC3B6-D709-46F8-CB72-452FA5E082B8%' order by TimeStarted desc
Select top 4 * from InternalJobHistory where command like '%Exec dbo.p_GroomManagedEntity 422AFC88-5EFF-F4C5-F8F6-E01038CDE67F%' order by TimeStarted desc
Select top 4 * from InternalJobHistory where command like '%Exec dbo.p_GroomManagedEntity 04B69835-6343-4DE2-4B19-6BE08C612989%' order by TimeStarted desc
Select top 4 * from InternalJobHistory where command like '%Exec dbo.p_GroomChangeLogs 55270A70-AC47-C853-C617-236B0CFF9B4C%' order by TimeStarted desc
Select top 4 * from InternalJobHistory where command like '%Exec dbo.p_GroomPartitionedObjects and dbo.p_Grooming%' order by TimeStarted desc
Select top 4 * from InternalJobHistory where command like '%Exec dbo.p_GroomTypeSpecificLogTables%' order by TimeStarted desc
Select top 4 * from InternalJobHistory where command like '%Exec dbo.p_DataPurging%' order by TimeStarted desc
'@
    $SQL_SCSM_MS['SQL_WF_and_2ndaryMS'] = @'
select sitc.*,mt.TypeName, bme.DisplayName as "Primary/WF Mgmt Server"  -- ,*
FROM dbo.[ScopedInstanceTargetClass] sitc
inner join ManagedType mt on mt.ManagedTypeId = sitc.ManagedTypeId
inner join BaseManagedEntity bme on bme.BaseManagedEntityId = sitc.ScopedInstanceId and bme.IsDeleted=0
where mt.ManagedTypeId = dbo.fn_ManagedTypeId_MicrosoftSystemCenterWorkflowTarget()
select 'All registered mgmt servers below (including WF, except DW)'
exec    p_RootManagementServerSelectConnectionPropertyValues
'@
    $SQL_SCSM_MS['SQL_AdvancedTypeProjections'] = @'
select distinct lttp.ltvalue as TypeProjectionName,ltf.LTValue as FolderName,lt.ltvalue as ViewName
from TypeProjection tp
left join LocalizedText lttp on tp.TypeProjectionId=lttp.LTStringId 
inner join  views v  on v.ConfigurationXML like '%Parameter="TypeProjectionId"%Value="$MPElement\[Name=''%!'+ tp.TypeProjectionName +'''\]$"%' escape '\'
inner join FolderItem fi on v.ViewId=fi.MPElementId
inner join Folder f on fi.FolderId=f.FolderId
left join LocalizedText lt on v.ViewId=lt.LTStringId 
left join LocalizedText ltf on f.FolderId=ltf.LTStringId 
inner join ManagementPack mp on v.ManagementPackId=mp.ManagementPackId
where 
lttp.ltvalue like '%(advanced)%'
and lttp.LTStringType=1 and lttp.LanguageCode like 'EN_' 
and lt.LTStringType=1 and lt.LanguageCode like 'EN_' 
and ltf.LTStringType=1 and ltf.LanguageCode like 'EN_' 
and (MP.MPKeyToken!='31bf3856ad364e35' or mp.MPKeyToken is null)
order by 1,2,3  
'@
    $SQL_SCSM_MS['SQL_ScsmMonitoringMP_Grooming'] = @'
    SELECT COUNT(*) "Grooming - SCSM Monitoring MP" FROM dbo.InternalJobHistory Job, (SELECT max(timestarted) as LastTime, command FROM dbo.InternalJobHistory GROUP BY command) GroupJob WHERE job.Command = GroupJob.Command AND job.TimeStarted= GroupJob.LastTime AND ( (job.StatusCode = '0' AND (DATEDIFF(MINUTE, job.TimeStarted , GETUTCDATE()) >= 25)) OR (job.StatusCode = '0' AND (DATEDIFF(MINUTE, job.TimeStarted , GETUTCDATE()) >= 15) AND job.Command like '%Subscription%') OR job.StatusCode ='2' )
'@
    $SQL_SCSM_MS['SQL_ScsmMonitoringMP_Lfx'] = @'
declare @TableName sysname; declare @StatusColumn sysname; declare @StartTimeColumn sysname; declare @Query varchar(max); 
select @TableName = MT.ManagedTypeTableName, @StatusColumn = MTP1.ColumnName,@StartTimeColumn = MTP2.ColumnName from ManagedType MT inner join ManagedTypeProperty MTP1 on MT.ManagedTypeId = MTP1.ManagedTypeId inner join ManagedTypeProperty MTP2 on MT.ManagedTypeId = MTP2.ManagedTypeId where MT.TypeName = N'Microsoft.SystemCenter.LinkingFramework.SyncStatus' and MTP1.ManagedTypePropertyName = N'Status' and MTP2.ManagedTypePropertyName = N'LastRunStartTime'
SET @Query = N'select CONVERT(varchar,COUNT(*)) "Linking FX - SCSM Monitoring MP" ' + ' from dbo.EnumType Etype join ' + @TableName + ' SyncStatus on Etype.EnumTypeId = SyncStatus.' + @StatusColumn + ' join dbo.Relationship Rel on Rel.TargetEntityId = SyncStatus.BaseManagedEntityId join dbo.BaseManagedEntity BME '+ 'on BME.BaseManagedEntityId = Rel.SourceEntityId ' + ' WHERE (' + @StatusColumn + ' like ''%FinishedwithError%'') OR ' + '(' + @StatusColumn + ' like ''%Unknown%'') OR ' + '(' + @StatusColumn + ' like ''%NeverRun%'' AND ' + '('+ ' DATEDIFF(MINUTE,' + @StartTimeColumn + ', GETUTCDATE()) >= 5))' 
EXEC(@Query)
'@
    $SQL_SCSM_MS['SQL_ScsmMonitoringMP_Workflows'] = @'
SELECT CONVERT(nvarchar,COUNT(*)) "Workflows - SCSM Monitoring MP"
FROM dbo.WindowsWorkflowTaskJobStatus 
LEFT OUTER JOIN dbo.JobStatusView ON dbo.[JobStatusView].[BatchId] = dbo.[WindowsWorkflowTaskJobStatus].[BatchId] 
LEFT OUTER JOIN dbo.MySubscriptions ON dbo.[WindowsWorkflowTaskJobStatus].[RuleId] = dbo.[MySubscriptions].[RuleEntityId] WHERE (( dbo.[WindowsWorkflowTaskJobStatus].[Processed] IS NULL 
AND ( (dbo.[WindowsWorkflowTaskJobStatus].[ErrorMessage] IS NOT NULL) 
OR (dbo.[JobStatusView].Status = 3) 
OR ((dbo.[JobStatusView].Status = 0 
OR dbo.[JobStatusView].Status = 1) AND (DATEDIFF(MINUTE, dbo.[JobStatusView].TimeScheduled, GETUTCDATE()) >= 25) ) OR( dbo.[JobStatusView].Status = 2) 
OR( dbo.[JobStatusView].Status is NULL) ) ))
and RuleId!='78B51DD8-0183-A48B-3993-E793F3BB9F85'
GO
SELECT R.RuleName, [JobStatusView].[Id],[JobStatusView].[BatchId],[JobStatusView].[Status],[JobStatusView].[TimeStarted],[JobStatusView].[TimeFinished],[JobStatusView].[Output],[WindowsWorkflowTaskJobStatus].[BaseManagedEntityId],[WindowsWorkflowTaskJobStatus].[RuleId],[MySubscriptions].[UserSID],[JobStatusView].[ErrorCode],[JobStatusView].[ErrorMessage],[WindowsWorkflowTaskJobStatus].[ErrorMessage] AS [TaskSubmissionErrorMessage],[WindowsWorkflowTaskJobStatus].[RowId]--, r.*
FROM dbo.WindowsWorkflowTaskJobStatus 
 LEFT OUTER JOIN dbo.JobStatusView 
     ON dbo.[JobStatusView].[BatchId] = dbo.[WindowsWorkflowTaskJobStatus].[BatchId]
 LEFT OUTER JOIN dbo.MySubscriptions 
     ON dbo.[WindowsWorkflowTaskJobStatus].[RuleId] = dbo.[MySubscriptions].[RuleEntityId] 
 LEFT JOIN Rules r on [WindowsWorkflowTaskJobStatus].[RuleId] = r.RuleId
WHERE 
dbo.[WindowsWorkflowTaskJobStatus].[Processed] IS NULL            
AND
(    
	dbo.[WindowsWorkflowTaskJobStatus].[ErrorMessage] IS NOT NULL
	OR ((dbo.[JobStatusView].Status = 0 OR dbo.[JobStatusView].Status = 1) AND (DATEDIFF(MINUTE, dbo.[JobStatusView].TimeScheduled, GETUTCDATE()) >= 25))                
	OR dbo.[JobStatusView].Status = 2
	OR dbo.[JobStatusView].Status = 3                
)
and R.RuleId!='78B51DD8-0183-A48B-3993-E793F3BB9F85'
'@
    $SQL_SCSM_MS['SQL_Connectors'] = @'
SELECT [PC].[S] as Connector_BME
into #BME_Connector
FROM (SELECT [S].[BaseManagedEntityId] AS [S],0 AS CS
	FROM dbo.TypedManagedEntity AS S 
	WHERE (S.[ManagedTypeId] = '71f6cfcd-99b3-3a07-471d-bb9c4bf5ba76'
		AND S.[IsDeleted] = 0)) AS PC
LEFT OUTER JOIN
	(
		SELECT DISTINCT [SourceView].[LastModified], [MTV_Connector].[BaseManagedEntityId]
		FROM dbo.MTV_Connector AS MTV_Connector 
		INNER JOIN dbo.EnterpriseManagementObjectView AS SourceView 
			ON [MTV_Connector].[BaseManagedEntityId] = [SourceView].[Id] 
		WHERE ((SourceView.[MonitoringClassId] = '71F6CFCD-99B3-3A07-471D-BB9C4BF5BA76')) 
	) AS EpilogOrderByJoin0_0 ON EpilogOrderByJoin0_0.[BaseManagedEntityId] = [PC].[S]
SELECT [PC].[S] as BME_Connector,[PC].[T0] as BME_SyncStatus
into #Bme_Map
FROM (SELECT [S].[BaseManagedEntityId] AS [S],0 AS CS,[R0].[TargetEntityId] AS [T0],1 AS CRT0
FROM dbo.TypedManagedEntity AS S 
 LEFT OUTER JOIN dbo.Relationship AS R0 /*SOURCE_HINT_PATTERN*/-- Microsoft.SystemCenter.LinkingFramework.DataSourceHostSyncStatus
     ON (R0.[SourceEntityId] = S.[BaseManagedEntityId]
     AND R0.[RelationshipTypeId] = '1548950d-6cea-d9c1-11ec-53701fbcbbec'
     AND R0.[IsDeleted] = 0)
WHERE (S.[ManagedTypeId] = '71f6cfcd-99b3-3a07-471d-bb9c4bf5ba76'
     AND S.[IsDeleted] = 0)) AS PC 
WHERE [PC].[S] IN (select Connector_BME from #BME_Connector)
 OPTION (KEEP PLAN)
SELECT 
bmecon.DisplayName as "Name",
[MTV_Connector].[Enabled_2B488464_2BCA_D1E4_B438_D6DE9759E808] as "Enabled",
[MTV_Connector].[DataProviderDisplayName_6244FC3E_8D65_C1D5_29E7_1071B0890237] as "Data Provider Name",
CONVERT(datetime, SWITCHOFFSET(CONVERT(datetimeoffset, [MTV_Microsoft$SystemCenter$LinkingFramework$SyncStatus].[LastRunStartTime_2B415DAF_7E5C_1241_ADD4_955E08C15B89]), DATENAME(TzOffset, SYSDATETIMEOFFSET())))  as "Start Time",
CONVERT(datetime, SWITCHOFFSET(CONVERT(datetimeoffset, [MTV_Microsoft$SystemCenter$LinkingFramework$SyncStatus].[LastRunFinishTime_B2581D10_0D95_2D11_A250_5BFC7E325EDC]), DATENAME(TzOffset, SYSDATETIMEOFFSET())))  as "Finish Time",
lt.LTValue as Status,
[MTV_Microsoft$SystemCenter$LinkingFramework$SyncStatus].[SyncPercent_A712979C_DCB0_6936_9F52_802603596BBC] as "Percentage",
datediff(MINUTE,[MTV_Microsoft$SystemCenter$LinkingFramework$SyncStatus].[LastRunStartTime_2B415DAF_7E5C_1241_ADD4_955E08C15B89],[MTV_Microsoft$SystemCenter$LinkingFramework$SyncStatus].[LastRunFinishTime_B2581D10_0D95_2D11_A250_5BFC7E325EDC]) as Duration_Minutes,
[MTV_Microsoft$SystemCenter$LinkingFramework$SyncStatus].[LastRunStartTime_2B415DAF_7E5C_1241_ADD4_955E08C15B89] as "Start Time (UTC)",
[MTV_Microsoft$SystemCenter$LinkingFramework$SyncStatus].[LastRunFinishTime_B2581D10_0D95_2D11_A250_5BFC7E325EDC] as "Finish Time (UTC)"
FROM dbo.MTV_Microsoft$SystemCenter$LinkingFramework$SyncStatus AS MTV_Microsoft$SystemCenter$LinkingFramework$SyncStatus  
	inner join #Bme_Map sync on [MTV_Microsoft$SystemCenter$LinkingFramework$SyncStatus].[BaseManagedEntityId]=sync.BME_SyncStatus
	inner join BaseManagedEntity bmeCon on sync.BME_Connector=bmeCon.BaseManagedEntityId
	inner join MTV_Connector on MTV_Connector.BaseManagedEntityId = sync.BME_Connector
	left join LocalizedText lt on Status_6505CB6B_B5DE_D3D0_6DB4_2C746EB1AAC5=lt.LTStringId and lt.LanguageCode='ENU' and lt.LTStringType=1
WHERE [MTV_Microsoft$SystemCenter$LinkingFramework$SyncStatus].[BaseManagedEntityId] IN (select BME_SyncStatus from #Bme_Map)
'@
    $SQL_SCSM_MS['SQL_TroubleshootingWorkflowPerformanceandDelays'] =@'
--Appendix of  https://techcommunity.microsoft.com/t5/system-center-blog/troubleshooting-workflow-performance-and-delays/ba-p/347510
declare @minState bigint, @maxETL bigint
declare @cntCard1 int, @largestRECLetlID bigint

--STEP 1
--Select the minimum watermark
SELECT @minState=MIN(State)
FROM dbo.CmdbInstanceSubscriptionState W WITH (nolock)
JOIN dbo.Rules R
ON W.RuleId = R.RuleId
WHERE R.RuleEnabled <> 0
AND W.IsPeriodicQueryEvent = 0;
-- Example: 1204988

--STEP 2
--Select the max watermark
SELECT @maxETL=MAX(EntityTransactionLogId)  FROM EntityChangeLog WITH (nolock)
-- Example: 1232787

--STEP 3
-- See if the large volume transaction entries in RECL have a target max cardinality=1 relationship.
SELECT 
top 1 @cntCard1=COUNT(*), @largestRECLetlID=RECL.EntityTransactionLogId
--COUNT(*) AS TargetMaxCard1CountInTransaction,RECL.EntityTransactionLogId
FROM dbo.RelatedEntityChangeLog RECL WITH(nolock)
INNER JOIN dbo.RelationshipType RT WITH(nolock)
ON RECL.EntityTypeId = RT.RelationshipTypeId 
WHERE RT.TargetMaxCardinality=1
AND RECL.EntityTransactionLogId <= @maxETL --1232787
AND RECL.EntityTransactionLogId >= @minState --1204988
GROUP BY RECL.EntityTransactionLogId
ORDER BY COUNT(*) DESC
-- TargetMaxCard1CountInTransaction EntityTransactionLogId
-- 1656     1232364

--STEP 4
-- In a large transaction in RECL see if there are target max cardinality = 1 relationships that also have 
-- the source endpoint of the target max cardinality=1 relationship in RECL.
-- This means they are here because their targets changed.
-- Group by target, to see how many sources are associated with the same target.
-- If you see a large count, this is a good candidate to add to exclusion.
SELECT COUNT(*) AS CountOfSourcesForSameTarget,RT.RelationshipTypeId, RECL.RelatedEntityId
FROM dbo.RelatedEntityChangeLog RECL WITH(nolock)
INNER JOIN dbo.RelationshipType RT WITH(nolock)
ON RECL.EntityTypeId = RT.RelationshipTypeId 
INNER JOIN dbo.RelatedEntityChangeLog RECLSOURCE with(nolock)
ON RECL.EntityId = RECLSOURCE.EntityId
WHERE RT.TargetMaxCardinality=1
AND RECLSOURCE.RelatedEntityId IS NULL
AND RECL.EntityTransactionLogId = @largestRECLetlID--'1232364'
AND RECLSOURCE.EntityTransactionLogId = @largestRECLetlID--'1232364'
GROUP BY RT.RelationshipTypeId, RECL.RelatedEntityId
ORDER BY COUNT(*) DESC
---
SELECT '!' as "Custom RelationshipTypes not in ExcludedRelatedEntityChangeLog !",
 R.RelationshipTypeId,
 R.TargetManagedTypeId,
 R.RelationshipTypeName,
 R.TargetMaxCardinality,
 R.ManagementPackId,
 MP.MPName
FROM RelationshipType AS R WITH(NOLOCK)
INNER JOIN ManagementPack AS MP WITH(NOLOCK)
 ON R.ManagementPackId = MP.ManagementPackId
WHERE
 R.TargetMaxCardinality = 1 AND
 R.RelationshipTypeId NOT IN (
 SELECT EX.RelationshipTypeId FROM ExcludedRelatedEntityChangeLog AS EX WITH(NOLOCK)
)
and MP.MPName not in 
('Microsoft.SystemCenter.ConfigurationManager',
'Microsoft.SystemCenter.ServiceManager.Portal',
'Microsoft.SystemCenter.ServiceManager.Portal',
'Microsoft.Windows.Library',
'ServiceManager.IncidentManagement.Library',
'ServiceManager.IncidentManagement.Library',
'ServiceManager.IncidentManagement.Library',
'ServiceManager.LinkingFramework.Library',
'ServiceManager.SLAManagement.Library',
'ServiceManager.SLAManagement.Library',
'System.Knowledge.Library',
'System.Library',
'System.Library',
'System.ServiceCatalog.Library',
'System.SLA.Library',
'System.SLA.Library',
'System.SLA.Library',
'System.SLA.Library',
'System.SLA.Library',
'System.WorkItem.Activity.Library',
'System.WorkItem.Library')
ORDER BY MP.MPName, R.RelationshipTypeName
'@
    $SQL_SCSM_MS['SQL_ForRFH_829977'] = @'
--Regarding UnauthorizedAccessException mentioned in below articles
--https://support.microsoft.com/en-us/topic/update-rollup-2-for-system-center-service-manager-2019-9211f013-33a5-fee4-ea18-d4c35befa831
--https://support.microsoft.com/en-us/topic/update-rollup-10-for-system-center-2016-service-manager-9ffb4362-551d-8a8d-3746-a25d3f379f74

select 'look for for Return based on ImplicitPermission check',substring(text,1,2000) from sys.syscomments where text like '%Procedure%\[AzMan_SPD_AzRoleAssignment_Single_SidMember%' escape '\'
'@  
    $SQL_SCSM_MS['SQL_RegisteredDwInfo'] = @'
select dw.Server_48B308F9_CF0E_0F74_83E1_0AEB1B58E2FA as "DW mgmt server name", dw.DisplayName as DW_MgmtGroupName 
from MT_Microsoft$SystemCenter$ResourceAccessLayer$DwSdkResourceStore dw
inner join BaseManagedEntity bme on dw.BaseManagedEntityId=bme.BaseManagedEntityId
'@
    $SQL_SCSM_MS['SQL_WorkItemsCount']=@'
select count(*) 'IR count in SMDB', min(CreatedDate_6258638D_B885_AB3C_E316_D00782B8F688) as "Oldest",max(CreatedDate_6258638D_B885_AB3C_E316_D00782B8F688) as "Newest" from [dbo].[MT_System$WorkItem$Incident]
select count(*) 'SR count in SMDB', min(CreatedDate_6258638D_B885_AB3C_E316_D00782B8F688) as "Oldest",max(CreatedDate_6258638D_B885_AB3C_E316_D00782B8F688) as "Newest" from [dbo].[MT_System$WorkItem$ServiceRequest] 
select count(*) 'CR count in SMDB', min(CreatedDate_6258638D_B885_AB3C_E316_D00782B8F688) as "Oldest",max(CreatedDate_6258638D_B885_AB3C_E316_D00782B8F688) as "Newest" from [dbo].[MT_System$WorkItem$ChangeRequest]
'@
    $SQL_SCSM_MS['SQL_WorkItemsCount_ByMonth']=@'
select 'IR in SMDB',datepart(year,CreatedDate_6258638D_B885_AB3C_E316_D00782B8F688) year,datepart(month,CreatedDate_6258638D_B885_AB3C_E316_D00782B8F688) month,count(*) count
from [dbo].[MT_System$WorkItem$Incident]
group by datepart(year,CreatedDate_6258638D_B885_AB3C_E316_D00782B8F688),datepart(month,CreatedDate_6258638D_B885_AB3C_E316_D00782B8F688)
order by 2,3
select 'SR in SMDB',datepart(year,CreatedDate_6258638D_B885_AB3C_E316_D00782B8F688) year,datepart(month,CreatedDate_6258638D_B885_AB3C_E316_D00782B8F688) month,count(*) count
from [dbo].[MT_System$WorkItem$ServiceRequest]
group by datepart(year,CreatedDate_6258638D_B885_AB3C_E316_D00782B8F688),datepart(month,CreatedDate_6258638D_B885_AB3C_E316_D00782B8F688)
order by 2,3
select 'CR in SMDB',datepart(year,CreatedDate_6258638D_B885_AB3C_E316_D00782B8F688) year,datepart(month,CreatedDate_6258638D_B885_AB3C_E316_D00782B8F688) month,count(*) count
from [dbo].[MT_System$WorkItem$ChangeRequest]
group by datepart(year,CreatedDate_6258638D_B885_AB3C_E316_D00782B8F688),datepart(month,CreatedDate_6258638D_B885_AB3C_E316_D00782B8F688)
order by 2,3
'@

    $SQL_SCSM_MS['SQL_DelayedImplicitPermissions']=@'
--To see how many implicit permissions are waiting to be processed
select (select max(entitytransactionlogID) from EntityChangeLog)-EntityTransactionLogID as WatermarksBehind
,EntityTransactionLogID as LastProcessedImplicitPermission,(select max(entitytransactionlogID) from EntityChangeLog) as LatestChangeInSM
from [dbo].[ImplicitUserRoleAdministratorState]
'@

    $SQL_SCSM_MS['SQL_UsersWithMissingImpliedPermissionsOnWorkItems']=@'
--Important: Even if the query shows proper Implicit Role, the work item won't be visible in the Portal if the user has no access permission to the relevant Queues (like IR, SR, RA, MA)
--As mentioned in the WHERE clause below, you may add your SM admins who are not directly added into the SM Administrators role.
--shows all users who are missing ImpliedIncidentAffectedUser Permissions on non-CLOSED Work Items
declare @UserRoleName nvarchar(510)='UserRoleImpliedIncidentAffectedUser'
declare @RelationshipTypeName nvarchar(512)='System.WorkItemAffectedUser' 
declare @UsersWithMissingImpliedPermissions table (Domain_UserName nvarchar(1026) null,BmeID uniqueidentifier not null, SID varbinary(85))
declare @UserRoleId uniqueidentifier=(select UserRoleId from UserRole where UserRoleName = @UserRoleName)
declare @AzRoleID int=(select ID from [dbo].[AzMan_AzScope] where name like convert(nvarchar(50),@UserRoleId))
insert into @UsersWithMissingImpliedPermissions
select distinct Domain_E36D56F2_AD60_E76E_CD5D_9F7AB51AD395+'\'+UserName_6AF77E23_669B_123F_B392_323C17097BBD as 'Permission is missing for User', rs.TargetEntityId as BmeIdUser, 
SUSER_SID(Domain_E36D56F2_AD60_E76E_CD5D_9F7AB51AD395+'\'+UserName_6AF77E23_669B_123F_B392_323C17097BBD) as SID
from Relationship rs 
inner join RelationshipType rst on rs.RelationshipTypeId=rst.RelationshipTypeId and RelationshipTypeName = @RelationshipTypeName and rs.IsDeleted=0
inner join MTV_System$Domain$User MTV_User on MTV_User.BaseManagedEntityId=rs.TargetEntityId
where not exists(select * from [dbo].[AzMan_Role_SIDMember] where RoleID=@AzRoleID and SUSER_Sname(MemberSID)=Domain_E36D56F2_AD60_E76E_CD5D_9F7AB51AD395+'\'+UserName_6AF77E23_669B_123F_B392_323C17097BBD)
select usr.Domain_UserName as 'User is missing Implied Permission' , bme.Name as 'on Work Item'
from @UsersWithMissingImpliedPermissions usr
inner join Relationship rs on usr.BmeID=rs.TargetEntityId and rs.IsDeleted=0 and rs.RelationshipTypeId = 'DFF9BE66-38B0-B6D6-6144-A412A3EBD4CE'
inner join BaseManagedEntity bme on bme.BaseManagedEntityId=rs.SourceEntityId
--below to exclude work items affected by users who are directly set in Administrators role
and not exists(select *
       from [dbo].[AzMan_AzRoleAssignment] ara
       inner join LocalizedText on Name=LTStringId and LTStringType=1 and LanguageCode='ENU'
       inner join userrole on Name=UserRoleId
       inner join AzMan_Role_SIDMember rsidm on ara.ID = rsidm.RoleID
       where  LTValue='Administrators'
       and SUSER_Sname(MemberSID) = usr.Domain_UserName
)
where SID is not null 

--below to exclude Closed IRs, other EnumTypeId can be added into the IN clause eg.  2B8830B6-59F0-F574-9C2A-F4B4682F1681 for IncidentStatusEnum.Resolved
and 1 != (select count(*) from [dbo].[MTV_System$WorkItem$Incident] IR where IR.BaseManagedEntityId = bme.BaseManagedEntityId and IR.Status_785407A9_729D_3A74_A383_575DB0CD50ED='BD0AE7C4-3315-2EB3-7933-82DFC482DBAF')
 
--below to exclude Closed SRs, other EnumTypeId can be added into the IN clause eg.  B026FDFD-89BD-490B-E1FD-A599C78D440F for ServiceRequestStatusEnum.Completed
and 1 != (select count(*) from [dbo].[MTV_System$WorkItem$ServiceRequest] SR where SR.BaseManagedEntityId = bme.BaseManagedEntityId and SR.Status_6DBB4A46_48F2_4D89_CBF6_215182E99E0F IN ('C7B65747-F99E-C108-1E17-3C1062138FC4'))
 
--below to exclude work items affected by users who are NOT directly set in Administrators role directly but indirectly through AD group membership. Add into the IN clause in DOMAIN\USERNAME format
and usr.Domain_UserName NOT IN ('')
 
order by 1,2
'@

    $SQL_SCSM_MS['SQL_UsersWithMissingImpliedPermissionsOnReviewActivities']=@'
--Important: Even if the query shows proper Implicit Role, the work item won't be visible in the Portal if the user has no access permission to the relevant Queues (like IR, SR, RA, MA)
--As mentioned in the WHERE clause below, you may add your SM admins who are not directly added into the SM Administrators role.
--shows all users who are missing ImpliedReviewer Permissions on non-COMPLETED Review Activities
declare @UserRoleName nvarchar(510)='UserRoleImpliedReviewer'
declare @RelationshipTypeName nvarchar(512)='System.ReviewerIsUser' 
declare @UsersWithMissingImpliedPermissions table (Domain_UserName nvarchar(1026) null,BmeID uniqueidentifier not null, SID varbinary(85))
declare @UserRoleId uniqueidentifier=(select UserRoleId from UserRole where UserRoleName = @UserRoleName)
declare @AzRoleID int=(select ID from [dbo].[AzMan_AzScope] where name like convert(nvarchar(50),@UserRoleId))
insert into @UsersWithMissingImpliedPermissions
select distinct Domain_E36D56F2_AD60_E76E_CD5D_9F7AB51AD395+'\'+UserName_6AF77E23_669B_123F_B392_323C17097BBD as 'Permission is missing for User', rs.TargetEntityId as BmeIdUser,
SUSER_SID(Domain_E36D56F2_AD60_E76E_CD5D_9F7AB51AD395+'\'+UserName_6AF77E23_669B_123F_B392_323C17097BBD) as SID
from Relationship rs 
inner join RelationshipType rst on rs.RelationshipTypeId=rst.RelationshipTypeId and RelationshipTypeName = @RelationshipTypeName and rs.IsDeleted=0
inner join MTV_System$Domain$User MTV_User on MTV_User.BaseManagedEntityId=rs.TargetEntityId
where not exists(select * from [dbo].[AzMan_Role_SIDMember] where RoleID=@AzRoleID and SUSER_Sname(MemberSID)=Domain_E36D56F2_AD60_E76E_CD5D_9F7AB51AD395+'\'+UserName_6AF77E23_669B_123F_B392_323C17097BBD)
select usr.Domain_UserName as 'User is missing Implied Permission', bme2.Name as 'on Review Activity'
from @UsersWithMissingImpliedPermissions usr
inner join Relationship rs on usr.BmeID=rs.TargetEntityId and rs.IsDeleted=0 and rs.RelationshipTypeId = '90DA7D7C-948B-E16E-F39A-F6E3D1FFC921'
inner join BaseManagedEntity bme on bme.BaseManagedEntityId=rs.SourceEntityId
inner join Relationship rs2 on rs.SourceEntityId=rs2.TargetEntityId and rs2.IsDeleted=0 and rs2.RelationshipTypeId = '6E05D202-38A4-812E-34B8-B11642001A80'
inner join BaseManagedEntity bme2 on bme2.BaseManagedEntityId=rs2.SourceEntityId
and not exists(select *
       from [dbo].[AzMan_AzRoleAssignment] ara
       inner join LocalizedText on Name=LTStringId and LTStringType=1 and LanguageCode='ENU'
       inner join userrole on Name=UserRoleId
       inner join AzMan_Role_SIDMember rsidm on ara.ID = rsidm.RoleID
       where  LTValue='Administrators'
       and SUSER_Sname(MemberSID) = usr.Domain_UserName
)
where SID is not null 

--below to exclude Completed RAs, other EnumTypeId can be added into the IN clause eg.  144BCD52-A710-2778-2A6E-C62E0C8AAE74 for ActivityStatusEnum.Failed
and 1 != (select count(*) from [dbo].[MTV_System$WorkItem$Activity$ReviewActivity] RA where RA.BaseManagedEntityId = bme2.BaseManagedEntityId and RA.Status_8895EC8D_2CBF_0D9D_E8EC_524DEFA00014 in ('9DE908A1-D8F1-477E-C6A2-62697042B8D9'))
 
--below to exclude users who are NOT directly set in Administrators role directly but indirectly through AD group membership. Add into the IN clause in DOMAIN\USERNAME format
and usr.Domain_UserName NOT IN ('')
 
order by 1,2
'@

   $SQL_SCSM_MS['SQL_CmdbInstanceSubscriptionState']=@'
select 
 '->CmdbInstanceSubscriptionState cmdb',cmdb.*
,'->rules r',r.*
,'->ManagedType mt',mt.*
,'->LocalizedText lt',lt.*
,'->RelationshipType rst',rst.*
,'->ManagedType mt_rel',mt_rel.*
from CmdbInstanceSubscriptionState cmdb
left join rules r on cmdb.RuleId = r.RuleId
left join ManagedType mt on cmdb.TypeId = mt.ManagedTypeId
left join LocalizedText lt on cmdb.RuleId = lt.LTStringId and lt.LanguageCode='ENU' and lt.LTStringType=1
left join RelationshipType rst on cmdb.RelationshipTypeId = rst.RelationshipTypeId
left join ManagedType mt_rel on cmdb.RelatedTypeId = mt_rel.ManagedTypeId
'@

   $SQL_SCSM_MS['SQL_EntityTransactionLog_stats']=@'
Select count(*) as cnt,
MIN(EntityTransactionLogId) as min_EntityTransactionLogId, MAX(EntityTransactionLogId) as max_EntityTransactionLogId,
MIN(LastModified) as min_LastModified, MAX(LastModified) as max_LastModified,
MIN(TimeAdded) as min_TimeAdded, MAX(TimeAdded) as max_TimeAdded
FROM dbo.EntityTransactionLog
'@

   $SQL_SCSM_MS['SQL_EntityTransactionLog_stats_by_DiscoverySource']=@'
select 
case ds.DiscoverySourceType
when 0 then 'Workflow'
when 1 then 'Connector'
when 2 then 'User'
when 3 then 'System'
when 4 then 'ConfigService '
end "Discover ySource Type"
,case 
when ds.DiscoveryRuleId is not null then d.DiscoveryName
when ds.DiscoverySourceType = 1 then cBME.DisplayName
when ds.DiscoverySourceType = 2 then '[User]'
when ds.DiscoverySourceType = 3 then '[System]'
when ds.DiscoverySourceType = 4 then '[ConfigService]'
end as "Discovery Source"
,'->Stats',etlStats.*
,'->DiscoverySource ds', ds.*
,'->Discovery d', d.*
--,'->ManagedType mt', mt.*
,'->BaseManagedEntity boundBME', boundBME.*
,'->Connector c', c.*
,'->BaseManagedEntity cBME', cBME.*
--,'->*',* 
from (
	Select etl.DiscoverySourceId, count(*) as cnt,
	MIN(etl.EntityTransactionLogId) as min_EntityTransactionLogId, MAX(etl.EntityTransactionLogId) as max_EntityTransactionLogId,
	MIN(etl.LastModified) as min_LastModified, MAX(etl.LastModified) as max_LastModified,
	MIN(etl.TimeAdded) as min_TimeAdded, MAX(etl.TimeAdded) as max_TimeAdded
	FROM EntityTransactionLog etl
	group by etl.DiscoverySourceId
) as etlStats
left join DiscoverySource ds on etlStats.DiscoverySourceId = ds.DiscoverySourceId
left join Discovery d on ds.DiscoveryRuleId = d.DiscoveryId
--left join ManagedType mt on ds.DiscoverySourceId = mt.ManagedTypeId
left join BaseManagedEntity boundBME on ds.BoundManagedEntityId = boundBME.BaseManagedEntityId
left join Connector c on ds.ConnectorId = c.ConnectorId
left join BaseManagedEntity cBME on c.BaseManagedEntityId = cBME.BaseManagedEntityId
'@

    foreach($SQL_SCSM_MS_Text in $SQL_SCSM_MS.Keys) {
        SaveSQLResultSetsToFiles $SQLInstance_SCSM $SQLDatabase_SCSM ($SQL_SCSM_MS[$SQL_SCSM_MS_Text]) "$SQL_SCSM_MS_Text.csv"    
    }

}