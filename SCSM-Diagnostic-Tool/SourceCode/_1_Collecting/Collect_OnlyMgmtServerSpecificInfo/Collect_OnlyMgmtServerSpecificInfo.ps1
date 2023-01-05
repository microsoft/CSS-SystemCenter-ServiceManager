function Collect_OnlyMgmtServerSpecificInfo() {
#region DO NOT REMOVE THIS! Exit immediately if script is NOT running on a WF or Secondary or DW mgmt server
if (-not (IsThisAnyScsmMgmtServer)) {
    return
}
#endregion

#region DO NOT MOVE THIS! To be used in subsequent functions
#region Import SM Module and fetch SM DB Location
if (!(Get-Module System.Center.Service.Manager)) {    
        Import-Module ((Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\System Center\2010\Service Manager\Setup').InstallDirectory +'PowerShell\' +'System.Center.Service.Manager.psd1') -force 
}

$SQLInstance_SCSM = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\System Center\2010\Common\Database').DatabaseServerName
$SQLDatabase_SCSM = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\System Center\2010\Common\Database').DatabaseName
#endregion
#region Import DW Module and fetch DW DB Locations
if (!(Get-Module Microsoft.EnterpriseManagement.Warehouse.Cmdlets)) {    
    Import-Module ((Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\System Center\2010\Service Manager\Setup').InstallDirectory +'Microsoft.EnterpriseManagement.Warehouse.Cmdlets.psd1') -force
}

$SQLInstance_SCSMDW = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\System Center\2010\Common\Database').StagingSQLInstance
$SQLDatabase_SCSMDW = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\System Center\2010\Common\Database').StagingDatabaseName

$SQLInstance_SCSMDW_Rep = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\System Center\2010\Common\Database').RepositorySQLInstance
$SQLDatabase_SCSMDW_Rep = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\System Center\2010\Common\Database').RepositoryDatabaseName

$SQLInstance_SCSMDW_DM = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\System Center\2010\Common\Database').DataMartSQLInstance
$SQLDatabase_SCSMDW_DM = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\System Center\2010\Common\Database').DataMartDatabaseName

$SQLInstance_SCSMDW_CMDM = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\System Center\2010\Common\Database').CMDataMartSQLInstance
$SQLDatabase_SCSMDW_CMDM = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\System Center\2010\Common\Database').CMDataMartDatabaseName

$SQLInstance_SCSMDW_OMDM = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\System Center\2010\Common\Database').OMDataMartSQLInstance
$SQLDatabase_SCSMDW_OMDM = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\System Center\2010\Common\Database').OMDataMartDatabaseName
    #endregion
#region Setting SQL SHARED query definitions that will be LATER executed by all mgmt servers including DW
$SQL_SCSM_Shared =@{}
$SQL_SCSM_Shared['SQL_Date']=@'
select SYSDATETIMEOFFSET() as LocalTime, FORMAT(GETUTCDATE(),N'yyyy-MM-dd__HH:mm.ss.fff') as UtcTime
'@
$SQL_SCSM_Shared['SQL_MOMManagementGroupInfo']=@'
select '__MOMManagementGroupInfo__' tableName,* from [__MOMManagementGroupInfo__]
'@
$SQL_SCSM_Shared['SQL_Databases']=@'
SELECT name,is_broker_enabled,compatibility_level,recovery_model_desc,* FROM sys.databases order by 1
'@
$SQL_SCSM_Shared['SQL_dm_os_schedulers']=@'
SELECT * FROM sys.dm_os_schedulers WHERE scheduler_id < 255;
'@
$SQL_SCSM_Shared['SQL_CurrentlyRunningQueries']=@'
SELECT SUBSTRING(sqltext.text, ( req.statement_start_offset / 2 ) + 1, 
              ( ( CASE WHEN req.statement_end_offset <= 0
                       THEN DATALENGTH(sqltext.text) 
              ELSE req.statement_end_offset END - 
       req.statement_start_offset ) / 2 ) + 1) AS statement_text,
sqltext.TEXT, req.last_wait_type,req.session_id,req.status,req.command,req.cpu_time,req.total_elapsed_time,blocking_session_id
,database_id,DB_NAME(database_id), p.hostname,p.hostprocess
FROM sys.dm_exec_requests req
CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS sqltext 
left join sys.sysprocesses p on req.session_id=p.spid
where req.session_id !=@@spid
and  req.last_wait_type not like '%broker%'
'@
$SQL_SCSM_Shared['SQL_database_scoped_configurations_IfGe2016']=@'
if (select convert(smallint,SERVERPROPERTY('ProductMajorVersion'))) >= 13 --greater than or equal sql 2016
SELECT
(select value from sys.database_scoped_configurations as dsc where dsc.name = 'MAXDOP') AS [MaxDop],
(select value_for_secondary from sys.database_scoped_configurations as dsc where dsc.name = 'MAXDOP') AS [MaxDopForSecondary],
(select value from sys.database_scoped_configurations as dsc where dsc.name = 'LEGACY_CARDINALITY_ESTIMATION') AS [LegacyCardinalityEstimation],
(select ISNULL(value_for_secondary, 2) from sys.database_scoped_configurations as dsc where dsc.name = 'LEGACY_CARDINALITY_ESTIMATION') AS [LegacyCardinalityEstimationForSecondary],
(select value from sys.database_scoped_configurations as dsc where dsc.name = 'PARAMETER_SNIFFING') AS [ParameterSniffing],
(select ISNULL(value_for_secondary, 2) from sys.database_scoped_configurations as dsc where dsc.name = 'PARAMETER_SNIFFING') AS [ParameterSniffingForSecondary],
(select value from sys.database_scoped_configurations as dsc where dsc.name = 'QUERY_OPTIMIZER_HOTFIXES') AS [QueryOptimizerHotfixes],
(select ISNULL(value_for_secondary, 2) from sys.database_scoped_configurations as dsc where dsc.name = 'QUERY_OPTIMIZER_HOTFIXES') AS [QueryOptimizerHotfixesForSecondary]
else
select 'no sys.database_scoped_configurations available for this sql version'
'@
$SQL_SCSM_Shared['SQL_DatabaseFiles']=@'
select sys.databases.name, sys.databases.database_id,sys.master_files.physical_name,size*8/1024 SizeInMB  from sys.databases join sys.master_files on sys.databases.database_id = sys.master_files.database_id where sys.databases.source_database_id is null order by 1,3
'@
$SQL_SCSM_Shared['SQL_sp_configure']=@'
exec sp_configure 'show advanced options',1 
RECONFIGURE
exec sp_configure
'@
$SQL_SCSM_Shared['SQL_dm_os_sys_info']=@'
select * from sys.dm_os_sys_info 
'@
$SQL_SCSM_Shared['SQL_dm_os_wait_stats']=@'
SELECT TOP 15 * FROM sys.dm_os_wait_stats ORDER BY wait_time_ms DESC
'@
$SQL_SCSM_Shared['SQL_sp_helplogins']=@'
exec master..sp_helplogins
'@
$SQL_SCSM_Shared['SQL_LoginsInfo']=@'
select name,language,sysadmin from sys.syslogins order by 1
'@
$SQL_SCSM_Shared['SQL_DbUsersInfo']=@'
DECLARE @DB_USers TABLE
(DBName sysname, UserName sysname, LoginType sysname, AssociatedRole varchar(max),create_date datetime,modify_date datetime)
INSERT @DB_USers
EXEC sp_MSforeachdb
'use [?]
SELECT ''?'' AS DB_Name,
case prin.name when ''dbo'' then prin.name + '' (''+ (select SUSER_SNAME(owner_sid) from master.sys.databases where name =''?'') + '')'' else prin.name end AS UserName,
prin.type_desc AS LoginType,
isnull(USER_NAME(mem.role_principal_id),'''') AS AssociatedRole ,create_date,modify_date
FROM sys.database_principals prin
LEFT OUTER JOIN sys.database_role_members mem ON prin.principal_id=mem.member_principal_id
WHERE prin.sid IS NOT NULL and prin.sid NOT IN (0x00) and
prin.is_fixed_role <> 1 AND prin.name NOT LIKE ''##%'''
SELECT
dbname,username ,logintype ,create_date ,modify_date ,
STUFF(
	(SELECT ',' + CONVERT(VARCHAR(500),associatedrole)
	FROM @DB_USers user2
	WHERE
	user1.DBName=user2.DBName AND user1.UserName=user2.UserName
	FOR XML PATH('')
	)
	,1,1,''
	) AS Permissions_user
FROM @DB_USers user1
WHERE dbname=DB_NAME()
GROUP BY dbname,username ,logintype ,create_date ,modify_date
ORDER BY DBName,username
'@
$SQL_SCSM_Shared['SQL_FragmentationInfo']=@'
SELECT OBJECT_NAME(ind.OBJECT_ID) AS TableName,
ind.name AS IndexName, indexstats.index_type_desc AS IndexType,
indexstats.avg_fragmentation_in_percent--,*
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, NULL) indexstats
INNER JOIN sys.indexes ind
ON ind.object_id = indexstats.object_id
AND ind.index_id = indexstats.index_id
ORDER BY indexstats.avg_fragmentation_in_percent DESC
'@
$SQL_SCSM_Shared['SQL_TableSizeInfo']=@'
declare c cursor local FORWARD_ONLY READ_ONLY for
select '['+ s.name +'].['+ o.name +']'
from sys.objects o
inner join sys.schemas s on o.schema_id=s.schema_id 
where o.type='U' 
order by o.name
declare @fqName nvarchar(max)
declare  @tbl table(
name nvarchar(max),
rows bigint,
reserved varchar(18),
data varchar(18),
index_size varchar(18),
unused varchar(18)
)
open c
while 1=1
begin
fetch c into @fqName
if @@FETCH_STATUS<>0 break
	insert into @tbl
	exec sp_spaceused @fqName
end
close c
deallocate c
select name,rows,data,index_size,unused from @tbl order by rows desc
'@
$SQL_SCSM_Shared['SQL_GroomingConfiguration']=@'
SELECT mt.TypeName,gc.RetentionPeriodInMinutes/60/24 as Days,gc.*
FROM [dbo].[MT_GroomingConfiguration] gc
inner join ManagedType mt on gc.TargetId=mt.ManagedTypeId
'@
$SQL_SCSM_Shared['SQL_GroomingConfiguration_Log']=@'
select * from [dbo].[MT_GroomingConfiguration_Log]
'@
$SQL_SCSM_Shared['SQL_PartitionAndGroomingSettings']=@'
select * from [dbo].[PartitionAndGroomingSettings]
'@
$SQL_SCSM_Shared['SQL_ManagementPack']=@'
select mp.ManagementPackId,MPIsSealed,MPName,MPFriendlyName,lt.LTValue as MPDisplayName, MPVersionDependentId,MPVersion,MPKeyToken,MPReadOnly,MPXMLInvalid, MPLastModified,MPCreated,MPSchemaTypes,MPCacheRefreshTimestamp,ContentReadable
from ManagementPack mp left join LocalizedText lt on mp.ManagementPackId=lt.LTStringId and lt.LTStringType=1 and lt.LanguageCode='ENU'
'@
$SQL_SCSM_Shared['SQL_ManagementPackHistory']=@'
select * from ManagementPackHistory
'@
$SQL_SCSM_Shared['SQL_ManagedType']=@'
select * from ManagedType
'@
$SQL_SCSM_Shared['SQL_ManagedTypeProperty']=@'
select mt.TypeName,* 
from ManagedTypeProperty mtp
inner join ManagedType mt on mtp.ManagedTypeId=mt.ManagedTypeId
order by 1,4
'@
$SQL_SCSM_Shared['SQL_Event1209']=@'
select ' !!! ' "Event ID: 1209 and Service Manager Workflows are stuck" , MP.ManagementPackId, MP.MPVersionDependentId, MP.MPName, MPVersion, MP.MPKeyToken,cast(MPRunTimeXML as xml).value('(/ManagementPack/@RevisionId)[1]','uniqueidentifier') as CorrectRevisionId , Convert(xml,MP.MPRunTimeXML) as MPRunTimeXML 
from ManagementPack as MP
where MP.MPIsSealed = 1 and MP.MPVersionDependentId != dbo.fn_MPVersionDependentId(MP.MPName, MP.MPKeyToken, MPVersion)
'@
$SQL_SCSM_Shared['SQL_Info'] = @'
select @@VERSION as "@@VERSION"
create table #SVer(ID int,  Name  sysname, Internal_Value int, Value nvarchar(512))
insert #SVer exec master.dbo.xp_msver
if exists (select 1 from sys.all_objects where name = 'dm_os_host_info' and type = 'V' and is_ms_shipped = 1)
begin
insert #SVer select t.*
from sys.dm_os_host_info
CROSS APPLY (
VALUES
(1001, 'host_platform', 0, host_platform),
(1002, 'host_distribution', 0, host_distribution),
(1003, 'host_release', 0, host_release),
(1004, 'host_service_pack_level', 0, host_service_pack_level),
(1005, 'host_sku', host_sku, '')
) t(id, [name], internal_value, [value])
end
declare @SmoRoot nvarchar(512)
exec master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\MSSQLServer\Setup', N'SQLPath', @SmoRoot OUTPUT
SELECT
(select Value from #SVer where Name = N'ProductName') AS [Product],
SERVERPROPERTY(N'ProductVersion') AS [VersionString],
(select Value from #SVer where Name = N'Language') AS [Language],
(select Value from #SVer where Name = N'Platform') AS [Platform],
CAST(SERVERPROPERTY(N'Edition') AS sysname) AS [Edition],
(select Internal_Value from #SVer where Name = N'ProcessorCount') AS [Processors],
(select Value from #SVer where Name = N'WindowsVersion') AS [OSVersion],
(select Internal_Value from #SVer where Name = N'PhysicalMemory') AS [PhysicalMemory],
CAST(ISNULL(SERVERPROPERTY('IsClustered'),N'') AS bit) AS [IsClustered],
@SmoRoot AS [RootDirectory],
convert(sysname, serverproperty(N'collation')) AS [Collation],
( select Value from #SVer where Name =N'host_platform') AS [HostPlatform],
( select Value from #SVer where Name =N'host_release') AS [HostRelease],
( select Value from #SVer where Name =N'host_service_pack_level') AS [HostServicePackLevel],
( select Value from #SVer where Name =N'host_distribution') AS [HostDistribution]
drop table #SVer
GO
'@
$SQL_SCSM_Shared['SQL_Rules'] = @'
select * from Rules
'@
$SQL_SCSM_Shared['SQL_Dbcc_Useroptions'] = @'
dbcc useroptions
'@
$SQL_SCSM_Shared['SQL_ForRFH_430445'] = @'
select 'check for Nvarchar and WITH RECOMPILE',substring(text,1,500) from sys.syscomments where text like '%CREATE PROCEDURE%SelectForNewTypeCache%'
'@
$SQL_SCSM_Shared['SQL_information_schema_columns'] = @'
select * from information_schema.columns order by Table_name,COLUMN_NAME
'@
$SQL_SCSM_Shared['SQL_Indexes'] = @'
--Taken from https://stackoverflow.com/questions/765867/list-of-all-index-index-columns-in-sql-server-db
SELECT '[' + s.NAME + '].[' + o.NAME + ']' AS 'table_name'
    ,+ i.NAME AS 'index_name'
    ,LOWER(i.type_desc) + CASE 
        WHEN i.is_unique = 1
            THEN ', unique'
        ELSE ''
        END + CASE 
        WHEN i.is_primary_key = 1
            THEN ', primary key'
        ELSE ''
        END AS 'index_description'
    ,STUFF((
            SELECT ', [' + sc.NAME + ']' AS "text()"
            FROM syscolumns AS sc
            INNER JOIN sys.index_columns AS ic ON ic.object_id = sc.id
                AND ic.column_id = sc.colid
            WHERE sc.id = so.object_id
                AND ic.index_id = i1.indid
                AND ic.is_included_column = 0
            ORDER BY key_ordinal
            FOR XML PATH('')
            ), 1, 2, '') AS 'indexed_columns'
    ,STUFF((
            SELECT ', [' + sc.NAME + ']' AS "text()"
            FROM syscolumns AS sc
            INNER JOIN sys.index_columns AS ic ON ic.object_id = sc.id
                AND ic.column_id = sc.colid
            WHERE sc.id = so.object_id
                AND ic.index_id = i1.indid
                AND ic.is_included_column = 1
            FOR XML PATH('')
            ), 1, 2, '') AS 'included_columns'
FROM sysindexes AS i1
INNER JOIN sys.indexes AS i ON i.object_id = i1.id
    AND i.index_id = i1.indid
INNER JOIN sysobjects AS o ON o.id = i1.id
INNER JOIN sys.objects AS so ON so.object_id = o.id
    AND is_ms_shipped = 0
INNER JOIN sys.schemas AS s ON s.schema_id = so.schema_id
WHERE so.type = 'U'
    AND i1.indid < 255
    AND i1.STATUS & 64 = 0 --index with duplicates
    AND i1.STATUS & 8388608 = 0 --auto created index
    AND i1.STATUS & 16777216 = 0 --stats no recompute
    AND i.type_desc <> 'heap'
    AND so.NAME <> 'sysdiagrams'
ORDER BY table_name
    ,index_name;
'@
$SQL_SCSM_Shared['SQL_BackupInfo'] = @'
SELECT 
    database_name
    , case type
	when 'D' then 'Database'
	when 'I' then 'Differential database'
	when 'L' then 'Log'
	when 'F' then 'File or filegroup'
	when 'G' then 'Differential file'
	when 'P' then 'Partial'
	when 'Q' then 'Differential partial'
	else '(unknown)'
	 end AS BackupType
    , MAX(backup_start_date) AS LastBackupDate
    , GETDATE() AS CurrentDate
    , DATEDIFF(DD,MAX(backup_start_date),GETDATE()) AS DaysSinceBackup
FROM msdb.dbo.backupset BS JOIN master.dbo.sysdatabases SD ON BS.database_name = SD.[name]
GROUP BY database_name, type 
ORDER BY database_name, type
'@
$SQL_SCSM_Shared['SQL_Get-SCSMUserRole'] = @'
select LocalizedText.LTValue as UserRoleName,  SUSER_Sname(MemberSID) as MembersInRole
	from [dbo].[AzMan_AzRoleAssignment] ara
	inner join LocalizedText on Name=LTStringId and LTStringType=1 and LanguageCode='ENU'
	inner join userrole on Name=UserRoleId
	inner join AzMan_Role_SIDMember rsidm on ara.ID = rsidm.RoleID
	inner join Profile p on userrole.ProfileId = p.ProfileId
where p.IsImplicitProfile = 0
order by 1,2
'@
$SQL_SCSM_Shared['SQL_RelationshipType'] = @'
select * from RelationshipType order by RelationshipTypeName
'@
$SQL_SCSM_Shared['SQL_EnumType'] = @'
select * from EnumType order by EnumTypeName
'@
$SQL_SCSM_Shared['SQL_OnlyNonEnuLocalizedStrings'] = @'
--find localized strings that have no ENU strings, but have for other languages
select * from LocalizedText where LTStringId in (
    select LTStringId
    from LocalizedText 
    where LTStringType=1
    group by LTStringId
    having sum(case LanguageCode when 'ENU' then 1 else 0 end) = 0
)
order by LTValue
'@
#endregion 
#endregion

Collect_FromDWAndWFAndSecondary

Collect_FromWFAndSecondary
Collect_FromWFAndDW
#Collect_FromDWAndSecondary  #ignored because I don't know anything common between DW AND Secondary

Collect_FromDW
Collect_FromWF
Collect_FromSecondary

}