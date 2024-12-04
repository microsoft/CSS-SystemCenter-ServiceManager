if  not exists (select * from sys.schemas where quotename(name) = N'[etl]')
begin
	execute ('create schema [etl] authorization [dbo]')
end
go


if  not exists (select * from sys.schemas where quotename(name) = N'[DWTemp]')
begin
	execute ('create schema [DWTemp] authorization [dbo]')
end
go


if  not exists (select * from sys.schemas where quotename(name) = N'[Staging]')
begin
	execute ('create schema [Staging] authorization [dbo]')
end
go

if  not exists (select * from sys.schemas where quotename(name) = N'[inbound]')
begin
	execute ('create schema [inbound] authorization [dbo]')
end
go


If not exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME ='DateDim')
begin
	
	print 'Creating table: DateDim'
	create table [dbo].[DateDim]
	(
	  DateKey				int not null primary key,
	  CalendarDate			smalldatetime not null unique,
	  DayOfWeek				nvarchar(64) not null,
	  DayNumberInMonth		smallint not null, 	  
	  WeekNumberInYear		smallint not null,
	  CalendarMonth		    nvarchar(64) not null,
	  MonthNumber		    smallint not null,
	  YearNumber			smallint not null, 	
	  CalendarQuarter		char(2) not null, 	
	  FiscalQuarter			char(2) not null, 	
	  FiscalMonth			nvarchar(64) not null,
	  FiscalYear			smallint not null,	
	  IsHoliday				tinyInt not null  constraint CK_Holiday check (IsHoliday in (1,0)),
	  IsWeekDay				tinyInt not null  constraint CK_WeekDay check (IsWeekDay in (1,0)),
	  IsLastDayOfMonth		tinyint not null  constraint CK_LastDayOfMonth check (IsLastDayOfMonth in (1,0))	  
	)
end
GO


IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'DomainTable' AND TABLE_SCHEMA = 'dbo')
BEGIN
  CREATE TABLE dbo.DomainTable
  (                               
       DomainTableRowId          int              NOT NULL    IDENTITY(1,1)
      ,TableObjectId             int              NOT NULL
      ,TableName                 nvarchar(256)     NOT NULL
      ,DatasetId                 uniqueidentifier NULL
      ,CreatedDateTime           datetime         NOT NULL    DEFAULT (GETUTCDATE())
     
      ,CONSTRAINT PK_DomainTable PRIMARY KEY CLUSTERED (DomainTableRowId)
      ,CONSTRAINT UN_DomainTable UNIQUE (TableObjectId)
  )
END

GO

IF EXISTS(SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Domaintable') AND name = 'TableName' AND max_length <> 512)
BEGIN
    ALTER TABLE dbo.DomainTable
    ALTER COLUMN TableName NVARCHAR(256) NOT NULL
END
GO
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'DomainTableIndex' AND TABLE_SCHEMA = 'dbo')
BEGIN
  CREATE TABLE dbo.DomainTableIndex
  (                               
       DomainTableIndexRowId     int              NOT NULL    IDENTITY(1,1)
      ,DomainTableRowId          int              NOT NULL
      ,IndexId                   int              NOT NULL
      ,IndexName                 sysname          NOT NULL
      ,OptimizationFrequencyMinutes int           NOT NULL
      ,LastConsideredForOptimizationDateTime datetime  NOT NULL    DEFAULT (0)
      ,CreatedDateTime           datetime         NOT NULL    DEFAULT (GETUTCDATE())
      ,RebuildFillFactor         int              NULL 
    
      ,CONSTRAINT PK_DomainTableIndex PRIMARY KEY CLUSTERED (DomainTableIndexRowId)
      ,CONSTRAINT UN_DomainTableIndex UNIQUE (DomainTableRowId, IndexId)
  )
END
GO

IF NOT EXISTS(SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('DomainTableIndex') AND name = 'RebuildFillFactor')
BEGIN
    ALTER TABLE dbo.DomainTableIndex
    ADD RebuildFillFactor int NULL  
END
GO
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'DomainTableIndexOptimizationHistory' AND TABLE_SCHEMA = 'dbo')
BEGIN
  CREATE TABLE dbo.DomainTableIndexOptimizationHistory
  (                               
       DomainTableIndexOptimizationHistoryRowId     int         NOT NULL    IDENTITY(1,1)
      ,DomainTableIndexRowId                        int         NOT NULL
      ,OptimizationStartDateTime                    datetime    NOT NULL    DEFAULT (GETUTCDATE())
      ,OptimizationDurationSeconds                  int         NOT NULL
      ,BeforeAvgFragmentationInPercent              float       NOT NULL
      ,AfterAvgFragmentationInPercent               float       NOT NULL
      ,OptimizationMethod                           varchar(50) NULL

      ,CONSTRAINT PK_DomainTableIndexOptimizationHistory PRIMARY KEY CLUSTERED (DomainTableIndexOptimizationHistoryRowId)
    )
END

GO
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'DomainTableStatisticsUpdateHistory' AND TABLE_SCHEMA = 'dbo')
BEGIN
  CREATE TABLE dbo.DomainTableStatisticsUpdateHistory
  (                               
       DomainTableStatisticsUpdateHistoryRowId  int         NOT NULL    IDENTITY(1,1)
      ,DomainTableRowId                         int         NOT NULL
      ,StatisticName                            sysname     NOT NULL
      ,UpdateStartDateTime                      datetime    NOT NULL    DEFAULT (GETUTCDATE())
      ,UpdateDurationSeconds                    int         NOT NULL
      ,RowsSampledPercentage                    int         NULL

      ,CONSTRAINT PK_DomainTableStatisticsUpdateHistory PRIMARY KEY CLUSTERED (DomainTableStatisticsUpdateHistoryRowId)
  )
END

GO
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'DebugMessage' AND TABLE_SCHEMA = 'dbo')
BEGIN
  DROP TABLE DebugMessage
END
GO

CREATE TABLE DebugMessage
(                               
      DebugMessageRowId       bigint      NOT NULL    IDENTITY (1, 1)
     ,ProcessId               int         NOT NULL    DEFAULT (@@SPID)
     ,DatasetId               uniqueidentifier NOT NULL
     ,MessageLevel            tinyint     NOT NULL
     ,MessageDateTime         datetime    NOT NULL    DEFAULT (GETUTCDATE())
     ,MessageText             nvarchar(max) NOT NULL
     ,OperationDurationMs     bigint      NULL
 
     ,CONSTRAINT PK_DebugMessageRowId PRIMARY KEY CLUSTERED (DebugMessageRowId)
)
GO

CREATE INDEX IX_DebugMessage_DatasetIdMessageDataTime ON DebugMessage(DatasetId, MessageDateTime)
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'StandardDataset' AND TABLE_SCHEMA = 'dbo')
BEGIN
  DROP TABLE StandardDataset
END
GO

CREATE TABLE StandardDataset
(                               
       DatasetId                            uniqueidentifier  NOT NULL
      ,SchemaName                           sysname           NOT NULL  DEFAULT('dbo')
      ,DebugLevel                           tinyint           NOT NULL  DEFAULT(0)
      ,DefaultAggregationIntervalCount      tinyint           NOT NULL
      ,RawInsertTableCount                  tinyint           NOT NULL  DEFAULT(1)
      ,StagingProcessorStoredProcedureName  sysname           NULL
      ,BlockingMaintenanceDailyStartTime    char(5)           NOT NULL
      ,BlockingMaintenanceDurationMinutes   int               NOT NULL  DEFAULT (60)
      ,LastOptimizationActionDateTime       datetime          NOT NULL  DEFAULT (GETUTCDATE())
      ,LastOptimizationActionSuccessfulCompletionDateTime datetime NOT NULL  DEFAULT (GETUTCDATE())

      ,CONSTRAINT PK_StandardDataset PRIMARY KEY CLUSTERED (DatasetId)
)
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'StandardDatasetTableMap' AND TABLE_SCHEMA = 'dbo')
BEGIN
  IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_StandardDatasetOptimizationHistory_StandardDatasetTableMap')
    ALTER TABLE StandardDatasetOptimizationHistory DROP CONSTRAINT FK_StandardDatasetOptimizationHistory_StandardDatasetTableMap

  DROP TABLE StandardDatasetTableMap
END
GO

CREATE TABLE StandardDatasetTableMap
(                               
      StandardDatasetTableMapRowId bigint         NOT NULL    IDENTITY (1, 1)
     ,DatasetId                 uniqueidentifier  NOT NULL
     ,AggregationTypeId         tinyint           NOT NULL
     ,TableGuid                 uniqueidentifier  NOT NULL
     ,TableNameSuffix           AS (REPLACE(CAST(TableGuid AS varchar(50)), '-', ''))
     ,InsertInd                 bit               NOT NULL    DEFAULT (1)
     ,OptimizedInd              bit               NOT NULL    DEFAULT (0)
     ,StartDateTime             datetime          NULL
     ,EndDateTime               datetime          NULL
 
     ,CONSTRAINT PK_StandardDatasetTableMap PRIMARY KEY CLUSTERED (StandardDatasetTableMapRowId)
     ,CONSTRAINT UN_StandardDatasetTableMap_DatasetAggergationTypeTable UNIQUE (DatasetId, AggregationTypeId, TableGuid)
)
GO 


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'StandardDatasetAggregation' AND TABLE_SCHEMA = 'dbo')
BEGIN
  DROP TABLE StandardDatasetAggregation
END
GO

CREATE TABLE StandardDatasetAggregation
(                               
       DatasetId                            uniqueidentifier    NOT NULL
      ,AggregationTypeId                    tinyint             NOT NULL
      ,AggregationIntervalDurationMinutes   int                 NULL 
      ,AggregationStartDelayMinutes         int                 NULL 
      ,BuildAggregationStoredProcedureName  sysname             NULL
      ,DeleteAggregationStoredProcedureName sysname             NULL
      ,GroomStoredProcedureName             sysname             NOT NULL
      ,IndexOptimizationIntervalMinutes     int                 NOT NULL
      ,MaxDataAgeDays                       int                 NOT NULL
      ,GroomingIntervalMinutes              int                 NOT NULL
      ,MaxRowsToGroom                       int                 NOT NULL
      ,LastGroomingDateTime                 smalldatetime       NULL
      ,DataFileGroupName                    sysname             NULL
      ,IndexFileGroupName                   sysname             NULL
      ,StatisticsMaxAgeHours                int                 NOT NULL  DEFAULT(18)
      ,StatisticsUpdateSamplePercentage     int                 NULL

      ,CONSTRAINT PK_StandardDatasetAggregation PRIMARY KEY CLUSTERED (DatasetId, AggregationTypeId)
)
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'StandardDatasetAggregationStorage' AND TABLE_SCHEMA = 'dbo')
BEGIN
  IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_StandardDatasetAggregationStorageIndex_StandardDatasetAggregationStorage')
    ALTER TABLE StandardDatasetAggregationStorageIndex DROP CONSTRAINT FK_StandardDatasetAggregationStorageIndex_StandardDatasetAggregationStorage
 
   DROP TABLE StandardDatasetAggregationStorage
END
GO

CREATE TABLE StandardDatasetAggregationStorage
(                               
       StandardDatasetAggregationStorageRowId int       NOT NULL  IDENTITY(1, 1)
      ,DatasetId                 uniqueidentifier  NOT NULL
      ,AggregationTypeId         tinyint           NOT NULL
      ,BaseTableName             nvarchar(90)      NOT NULL
      ,TableTag                  nvarchar(50)      NULL
      ,DependentTableInd         tinyint           NOT NULL  DEFAULT(0)
      ,TableTemplate             nvarchar(max)     NOT NULL
      ,CoverViewSelectClause     nvarchar(max)     NOT NULL
      ,MaxTableRowCount          int               NULL
      ,MaxTableSizeKb            int               NULL

      ,CONSTRAINT PK_StandardDatasetAggregationStorage PRIMARY KEY CLUSTERED (StandardDatasetAggregationStorageRowId)
      ,CONSTRAINT UN_StandardDatasetAggregationStorage_BaseTableName UNIQUE (BaseTableName)
      ,CONSTRAINT UN_StandardDatasetAggregationStorage_DatasetTableTag UNIQUE (DatasetId, AggregationTypeId, DependentTableInd, TableTag)
)
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'StandardDatasetAggregationStorageIndex' AND TABLE_SCHEMA = 'dbo')
BEGIN
  IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_StandardDatasetOptimizationHistory_StandardDatasetAggregationStorageIndex')
    ALTER TABLE StandardDatasetOptimizationHistory DROP CONSTRAINT FK_StandardDatasetOptimizationHistory_StandardDatasetAggregationStorageIndex

  DROP TABLE StandardDatasetAggregationStorageIndex
END
GO

CREATE TABLE StandardDatasetAggregationStorageIndex
(                               
       StandardDatasetAggregationStorageIndexRowId  int       NOT NULL  IDENTITY(1, 1)
      ,StandardDatasetAggregationStorageRowId       int       NOT NULL
      ,PrimaryKeyInd                                bit       NOT NULL  DEFAULT (0)
      ,UniqueInd                                    bit       NOT NULL
      ,IndexGuid                                    uniqueidentifier NULL
      ,IndexDefinition                              nvarchar(1000) NULL
      ,OnlineRebuildPossibleInd                     bit       NULL
      ,OnlineRebuildLastPerformedDateTime           datetime  NULL

      ,CONSTRAINT PK_StandardDatasetAggregationStorageIndex PRIMARY KEY CLUSTERED (StandardDatasetAggregationStorageIndexRowId)
      ,CONSTRAINT UN_StandardDatasetAggregationStorageIndex_IndexGuid UNIQUE (StandardDatasetAggregationStorageRowId, IndexGuid)
      ,CONSTRAINT CHK_StandardDatasetAggregationStorageIndex_Index CHECK ((PrimaryKeyInd = 1 AND UniqueInd = 1 AND IndexGuid IS NULL AND IndexDefinition IS NULL) OR (PrimaryKeyInd = 0 AND IndexGuid IS NOT NULL AND IndexDefinition IS NOT NULL))
)
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'StandardDatasetOptimizationHistory' AND TABLE_SCHEMA = 'dbo')
BEGIN
  DROP TABLE StandardDatasetOptimizationHistory
END
GO

CREATE TABLE StandardDatasetOptimizationHistory
(                               
     StandardDatasetOptimizationHistoryRowId  bigint    NOT NULL  IDENTITY(1, 1)
    ,StandardDatasetTableMapRowId             bigint    NOT NULL
    ,StandardDatasetAggregationStorageIndexRowId int    NOT NULL
    ,OptimizationStartDateTime                datetime  NULL
    ,OptimizationDurationSeconds              int       NULL
    ,BeforeAvgFragmentationInPercent          float     NULL
    ,AfterAvgFragmentationInPercent           float     NULL
    ,OptimizationMethod                       varchar(30) NULL
    ,CreatedDateTime                          datetime  NOT NULL  DEFAULT(GETUTCDATE())
     
    ,CONSTRAINT PK_StandardDatasetOptimizationHistory PRIMARY KEY CLUSTERED (StandardDatasetOptimizationHistoryRowId)
)
GO

CREATE INDEX IX_StandardDatasetOptimizationHistory_TableMapRowIdIndexRowIdDateTime ON StandardDatasetOptimizationHistory(StandardDatasetTableMapRowId, StandardDatasetAggregationStorageIndexRowId, CreatedDateTime)
GO
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME like 'SourceType' and TABLE_SCHEMA = 'etl')
begin
	
	print 'Creating table: SourceType'
	create table etl.SourceType 
	(
		SourceTypeId		int not null constraint PK_SourceType primary key,
		SourceTypeName		nvarchar(128) not null constraint SourceTypeName unique	
	)

end
go

if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME like 'Source' and TABLE_SCHEMA = 'etl')
begin	
	print 'Creating table: Source'
	create table etl.Source
	(
		SourceId				int not null constraint PK_Source primary key identity(1,1),
		SourceGuid				uniqueidentifier not null,
		SourceName				nvarchar(512) not null,
		SourceTypeId			int not null references etl.SourceType(SourceTypeId)
		Constraint UK_Source unique (SourceName, SourceTypeId),
	)

end
go
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME like 'WarehouseEntityType' and TABLE_SCHEMA = 'etl')
begin
	
	print 'Creating table: WarehouseEntityType'
	create table etl.WarehouseEntityType 
	(
		WarehouseEntityTypeId		int not null constraint PK_WarehouseEntityType primary key identity(1,1),
		WarehouseEntityTypeName		nvarchar(128) not null constraint WarehouseEntityTypeName unique	
	)

end
go

if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME like 'WarehouseEntity' and TABLE_SCHEMA = 'etl')
begin
	
	print 'Creating table: WarehouseEntity'
	create table etl.WarehouseEntity 
	(
		WarehouseEntityId		int not null constraint PK_WarehouseEntity primary key identity(1,1),
		EntityGuid				uniqueidentifier not null default NEWSEQUENTIALID(),
		SourceId				int null references etl.Source(SourceId),
		WarehouseEntityName		nvarchar(512) not null,
		ViewName				as WarehouseEntityName + 'vw' persisted,
		WarehouseEntityTypeId	int not null references etl.WarehouseEntityType(WarehouseEntityTypeId)
		Constraint UK_WarehouseEntity unique (WarehouseEntityName, WarehouseEntityTypeId,SourceId),
		Constraint UK_WarehouseEntityGuid unique(EntityGuid,SourceId)
	)

end
go




if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME like 'WarehouseColumn' and TABLE_SCHEMA = 'etl')
begin	
	print 'Creating table: WarehouseColumn'
	create table etl.WarehouseColumn
	(
		ColumnId				int not null constraint PK_Column primary key identity(1,1),
		EntityId				int not null references etl.WarehouseEntity(WarehouseEntityId),
		ColumnName				nvarchar(512) not null,
		DataType				nvarchar(128) not null,
		ColumnLength			smallint null,
		Nullable				bit not null default 0,
		IsIdentity				bit not null default 0,
		ReferenceEntityId		int null,
		ReferenceColumnId		int null
		Constraint UK_Column unique (ColumnName, EntityId),
	)

end
go



if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME like 'TablePartition')
begin
	create table etl.TablePartition
	(
		PartitionId			int not null constraint PK_Partition primary key identity (1,1),
		PartitionName		nvarchar(128) not null constraint UK_Partition unique,
		EntityId			int not null,		
		RangeStartDate		int null,
		RangeEndDate		int null,
		CreatedDate			smalldatetime not null default getutcdate(),
		-- the following field has been added to be able to
		-- track Entities across install, uninstall and re-install scenario
		-- this is necessary because Partitionname is no longer usable for this
		-- since it is normalized for length
		WarehouseEntityName nvarchar(512) null,		
		InsertedBatchId		int null,
		UpdatedBatchId		int null
    )
end
go

-- FOR: UPGRADE
if not exists(select 'x' from sys.columns where name = 'WarehouseEntityName' and object_id = OBJECT_ID('etl.TablePartition'))
begin
    alter table etl.TablePartition
    add WarehouseEntityName nvarchar(512) null
end
go

if not exists(select 'x' from sys.columns where name = 'InsertedBatchId' and object_id = OBJECT_ID('etl.TablePartition'))
begin
    alter table etl.TablePartition
    add InsertedBatchId int null
end
go

if not exists(select 'x' from sys.columns where name = 'UpdatedBatchId' and object_id = OBJECT_ID('etl.TablePartition'))
begin
    alter table etl.TablePartition
    add UpdatedBatchId int null
end
go


if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME like 'WarehouseEntityGroomingInfo' and TABLE_SCHEMA = 'etl')
begin
    
    print 'Creating table: WarehouseEntityGroomingInfo'
    create table etl.WarehouseEntityGroomingInfo
    (
        WarehouseEntityGroomingInfoId   int not null constraint PK_WarehouseEntityGroomingInfo primary key identity(1,1),
        WarehouseEntityId               int not null,
        GroomingStoredProcedure         nvarchar(max) not null default('EXEC etl.DropPartition @WarehouseEntityId=@WarehouseEntityId, @WarehouseEntityType=@WarehouseEntityType, @EntityGuid=@EntityGuid, @PartitionId=@PartitionId'),
        RetentionPeriodInMinutes        int not null default(525600), -- 1year: 1mi * 60mis * 24hrs * 365days * 1yr = 525600
        CreatedDate                     smalldatetime not null default getutcdate(),
        UpdatedDate                     smalldatetime null
    )

end
go

if not exists(select 'x' from sys.columns where object_id = OBJECT_ID('etl.WarehouseEntityGroomingInfo') and name = 'UpdatedDate')
begin
    alter table etl.WarehouseEntityGroomingInfo
    add UpdatedDate smalldatetime null
end
go

if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME like 'WarehouseEntityGroomingHistory' and TABLE_SCHEMA = 'etl')
begin
    
    print 'Creating table: WarehouseEntityGroomingHistory'
    create table etl.WarehouseEntityGroomingHistory
    (
        WarehouseEntityGroomingHistoryId    bigint not null constraint PK_WarehouseEntityGroomingHistory primary key identity(1,1),
        WarehouseEntityId                   int not null,
        PartitionIdTobeGroomed              int not null,
		PartitionName						nvarchar(128) not null,
		RangeStartDate						int null,
		RangeEndDate						int not null,
		PartitionRowCount                   bigint null,
        PreparationDate                     smalldatetime not null default getutcdate(),
        GroomedDate                         smalldatetime null
    )

end
go

/*
****************************************************************************************************************************************
*   This table is designed to hold configuration settings for etl.
*
    DROP TABLE etl.Configuration
****************************************************************************************************************************************
*/

IF OBJECT_ID(N'etl.Configuration') IS NULL
BEGIN
    CREATE TABLE etl.Configuration
    (
        ConfigurationFilter     NVARCHAR(512)   NOT NULL,
        ConfigurationPath       NVARCHAR(1024)  NOT NULL,
        ConfiguredValueType     VARCHAR(64)     NOT NULL,
        ConfiguredValue         NVARCHAR(MAX)   NOT NULL,
        CreatedDateTime         DATETIME        NOT NULL    CONSTRAINT ConfigurationDEF1 DEFAULT(GETUTCDATE()),
        ModifiedDateTime        DATETIME        NOT NULL    CONSTRAINT ConfigurationDEF2 DEFAULT(GETUTCDATE())
    )
END
GO
-------------------------------------------------------------------------------
--    (c) Copyright 2005-2006, Microsoft Corporation, All Rights Reserved    --
--    Proprietary and confidential to Microsoft Corporation                  --
--                                                                           --
--    File: SCCMConnectorTablesAlteration.sql                                --
--                                                                           --
--    Contents: This file contains the alteration of tables for SCCM         --
--              Connector.                                                   --
-------------------------------------------------------------------------------

SET NOCOUNT ON;
    DECLARE @Statement nvarchar(4000) ;
    DECLARE table_cursor CURSOR FOR
        SELECT 'ALTER TABLE [' + TABLE_SCHEMA+'].['+TABLE_NAME +']
        ALTER COLUMN '+ COLUMN_NAME +' decimal(19,0);'
        FROM  INFORMATION_SCHEMA.COLUMNS
        WHERE ( TABLE_NAME LIKE '%CMv5_DISK' OR TABLE_NAME LIKE '%vex_GS_DISK') AND 
		COLUMN_NAME = 'Size0' AND DATA_TYPE != 'decimal' ;
      
    OPEN table_cursor     
    FETCH NEXT FROM table_cursor  
    INTO @Statement    
    WHILE @@FETCH_STATUS = 0
    BEGIN        
        EXEC sp_sqlexec @Statement
        FETCH NEXT FROM table_cursor  
        INTO @Statement
    END
    CLOSE table_cursor;
    DEALLOCATE table_cursor;


	DECLARE table_cursor CURSOR FOR
        SELECT 'ALTER TABLE [' + TABLE_SCHEMA+'].['+TABLE_NAME +']
        ALTER COLUMN '+ COLUMN_NAME +' decimal(19,0);'
        FROM  INFORMATION_SCHEMA.COLUMNS
        WHERE (TABLE_NAME LIKE '%CMv5_LOGICAL_DISK' OR TABLE_NAME LIKE '%vex_GS_LOGICAL_DISK') AND
	    (COLUMN_NAME = 'Size0' OR COLUMN_NAME = 'FreeSpace0') AND 
	    DATA_TYPE != 'decimal' ;
      
    OPEN table_cursor     
    FETCH NEXT FROM table_cursor  
    INTO @Statement    
    WHILE @@FETCH_STATUS = 0
    BEGIN        
        EXEC sp_sqlexec @Statement
        FETCH NEXT FROM table_cursor  
        INTO @Statement
    END
    CLOSE table_cursor;
    DEALLOCATE table_cursor;


	DECLARE table_cursor CURSOR FOR
        SELECT 'ALTER TABLE [' + TABLE_SCHEMA+'].['+TABLE_NAME +']
        ALTER COLUMN '+ COLUMN_NAME +' decimal(19,0);'
        FROM  INFORMATION_SCHEMA.COLUMNS
        WHERE (TABLE_NAME LIKE '%CMv5_OPERATING_SYSTEM' OR TABLE_NAME LIKE '%vex_GS_OPERATING_SYSTEM') AND
	    COLUMN_NAME = 'TotalVisibleMemorySize0' AND 
	    DATA_TYPE != 'decimal' ;
      
    OPEN table_cursor     
    FETCH NEXT FROM table_cursor  
    INTO @Statement    
    WHILE @@FETCH_STATUS = 0
    BEGIN        
        EXEC sp_sqlexec @Statement
        FETCH NEXT FROM table_cursor  
        INTO @Statement
    END
    CLOSE table_cursor;
    DEALLOCATE table_cursor;


/*Bug-420319 - Dimension Table fix for OperatingSystem table */
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'OperatingSystemDim' and COLUMN_NAME = 'PhysicalMemory' and DATA_TYPE != 'decimal')
BEGIN
	/* Dropping Indexes */
	DROP INDEX IF EXISTS NCI0_OperatingSystemDim on dbo.OperatingSystemDim;
	DROP INDEX IF EXISTS NCI1_OperatingSystemDim on dbo.OperatingSystemDim;

	/* Altering  Data Type */
	ALTER TABLE dbo.OperatingSystemDim ALTER COLUMN PhysicalMemory decimal(19,0);

	/*Recreating Indexes */
	CREATE INDEX NCI0_OperatingSystemDim on	dbo.OperatingSystemDim(InsertedBatchId) 
	INCLUDE(OperatingSystemDimKey,BaseManagedEntityId,EntityDimKey,SourceId,OSVersion,OSVersionDisplayName,ProductType,
	BuildNumber,CSDVersion,ServicePackVersion,SerialNumber,InstallDate,SystemDrive,WindowsDirectory,PhysicalMemory,
	LogicalProcessors,CountryCode,Locale,Description,Manufacturer,OSLanguage,MinorVersion,MajorVersion,ObjectStatus_ConfigItemObjectStatusId,
	ObjectStatus,AssetStatus_ConfigItemAssetStatusId,AssetStatus,Notes,DisplayName,IsDeleted ,UpdatedBatchId);

	CREATE INDEX NCI1_OperatingSystemDim on	dbo.OperatingSystemDim(UpdatedBatchId)
	INCLUDE(OperatingSystemDimKey,BaseManagedEntityId,EntityDimKey,SourceId,OSVersion,OSVersionDisplayName,ProductType,
	BuildNumber,CSDVersion,ServicePackVersion,SerialNumber,InstallDate,SystemDrive,WindowsDirectory,PhysicalMemory,
	LogicalProcessors,CountryCode,Locale,Description,Manufacturer,OSLanguage,MinorVersion,MajorVersion,ObjectStatus_ConfigItemObjectStatusId,
	ObjectStatus,AssetStatus_ConfigItemAssetStatusId,AssetStatus,Notes,DisplayName,IsDeleted ,InsertedBatchId);

	/*Refreshing View After datatype change */
	IF  EXISTS (SELECT 1 from INFORMATION_SCHEMA.VIEWS where TABLE_NAME = 'OperatingSystemDimvw')
	BEGIN 
		EXEC sp_refreshview 'dbo.OperatingSystemDimvw';
	END
END

/*Bug-420319 - Dimension Table fix for LogicalDisk table */
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'LogicalDiskDim' and COLUMN_NAME = 'Size' and DATA_TYPE != 'decimal')
BEGIN

	/*Altering DataType*/
	ALTER TABLE dbo.LogicalDiskDim ALTER COLUMN Size decimal(19,0);

	/*Refreshing View after datatype change */
	IF  EXISTS (SELECT 1 from INFORMATION_SCHEMA.VIEWS where TABLE_NAME = 'LogicalDiskDimvw')
	BEGIN 
		EXEC sp_refreshview 'dbo.LogicalDiskDimvw';
	END
END


if object_id (N'etl.ShredWaterMark', N'IF') is not null
    drop function etl.ShredWaterMark;
GO
create function etl.ShredWaterMark (@WaterMarkXml xml)
returns table
as
Return
(    
	select Module.value('@ModuleName', 'nvarchar(256)') as ModuleName
		   , Module.value('@ProcessName', 'nvarchar(128)') as ProcessName
		   , Module.value('@BatchId', 'int') as BatchId
		   , Entities.value('@WarehouseEntityName', 'nvarchar(128)') as WarehouseEntityName
		   , Entities.value('@WarehouseEntityTypeName', 'nvarchar(128)') as WarehouseEntityTypeName
		   , Entities.value('@EntityGuid', 'nvarchar(128)') as EntityGuid
		   , Entities.value('@WaterMarkType', 'nvarchar(128)') as WaterMarkType
		   , case Entities.value('@WaterMarkType', 'nvarchar(128)')	
				when 'DateTime' then convert(nvarchar(64), Entities.value('@WaterMark', 'datetime'),109)
				else cast(Entities.value('@WaterMark', 'int') as varchar(64)) end as WaterMark
		  , case Entities.value('@WaterMarkType', 'nvarchar(128)')	
				when 'DateTime' then convert(nvarchar(64), Entities.value('@MaxWaterMark', 'datetime'),109)
				else cast(Entities.value('@MaxWaterMark', 'int') as varchar(64)) end as MaxWaterMark
	from @WaterMarkXml.nodes('/Module')as W(Module)
			CROSS APPLY W.Module.nodes('./Entity') as WE(Entities)       
);
go


if object_id (N'etl.MonthId', N'FN') is not null
    drop function etl.MonthId;
GO
create function [etl].[MonthId] (@DateKey int)
returns int
as
begin
	declare @MonthId int
	     
    select @MonthId = substring(cast(@DateKey as NCHAR(8)),1,6)	
    
	return(@MonthId)
end
go


IF (OBJECT_ID(N'etl.NormalizeNameForLength') IS NOT NULL)
    DROP FUNCTION etl.NormalizeNameForLength;
GO

CREATE FUNCTION etl.NormalizeNameForLength (@objectName NVARCHAR(1024), @maxLen INT)
RETURNS SYSNAME
AS BEGIN
    DECLARE @hashName       VARCHAR(40)     = ''
    
    SELECT  @maxLen = @maxLen - 41 -- '_' + (40)

    SET @objectName = LTRIM(RTRIM(@objectName))

    IF(LEN(@objectName) > @maxLen)
    BEGIN
        -- select a, convert(varbinary(8000), '0x' + convert(varchar(1024), a, 2), 1)
        SET @hashName = CONVERT(VARCHAR(40), HASHBYTES('SHA1', @objectName), 2)

        --Format: '%PRETEXT%_%POSTTEXT%'
        SET @objectName = LEFT(@objectName, @maxLen) + '_' + @hashName
    END

    RETURN @objectName
END
GO
if object_id (N'etl.PartitionName', N'FN') is not null
    drop function etl.PartitionName;
GO
create function [etl].[PartitionName] (@FactName nvarchar(512), @partitionPeriod datetime, @literalPeriod bit)
returns sysname as 
begin
    declare @Suffix nvarchar(64), @Month nchar(3), @partitionName nvarchar(522) = '', @minDateKey int, @maxDateKey int

    select @partitionPeriod = isnull(@partitionPeriod, getutcdate()),@literalPeriod = isnull(@literalPeriod, 0)

    declare @MonthId tinyint = datepart(month, @partitionPeriod)

    if (isnull(@FactName, '') = '')
    begin
	    return null
    end	

    select @minDateKey = min(d.DateKey), @maxDateKey = max(d.DateKey)
    from dbo.DateDim d
    where d.MonthNumber = datepart(month, @partitionPeriod)
    and d.YearNumber = datename(yy, @partitionPeriod)

    select @Month = case @MonthId 
    when 1 then 'Jan'
    when 2 then 'Feb'
    when 3 then 'Mar'
    when 4 then 'Apr'
    when 5 then 'May'
    when 6 then 'Jun'
    when 7 then 'Jul'
    when 8 then 'Aug'
    when 9 then 'Sep'
    when 10 then 'Oct'
    when 11 then 'Nov'
    when 12 then 'Dec' end

    set @Suffix = '_' + cast(DATEPART(year, @partitionPeriod) as nchar(4)) + '_' + @Month

    select @partitionName = PartitionName
    from etl.TablePartition
    where isnull(RangeStartDate, '19000101') <= @minDateKey
    and isnull(RangeEndDate, '99990101') >= @maxDateKey
    and @FactName = substring(PartitionName, 1, len(@FactName))

    if(@partitionName = '' or @literalPeriod = 1) set @partitionName = @FactName + @Suffix

    select @partitionName = case when len(@partitionName) < 128 then @partitionName else etl.NormalizeNameForLength(@partitionName, 118) + @Suffix end

    return(@partitionName)
end
go


IF (OBJECT_ID(N'etl.ConcatForeignKeyColumns') IS NOT NULL)
    DROP FUNCTION etl.ConcatForeignKeyColumns;
GO

CREATE FUNCTION etl.ConcatForeignKeyColumns (@FKName VARCHAR(512))
RETURNS @FKCols TABLE(SourceFKColumnsList VARCHAR(MAX), TargetFKColumnsList VARCHAR(MAX))
AS BEGIN
    DECLARE @SrcColumns VARCHAR(MAX),
            @TargetColumns VARCHAR(MAX)

    SELECT  @SrcColumns = '',
            @TargetColumns = ''

    SELECT  @SrcColumns = @SrcColumns + ', ' + COL_NAME(FKCols.parent_object_id, FKCols.parent_column_id),
            @TargetColumns = @TargetColumns + ', ' + COL_NAME(FKCols.referenced_object_id, FKCols.referenced_column_id)
    FROM sys.foreign_key_columns FKCols
    WHERE FKCols.constraint_object_id = OBJECT_ID(@FKName)

    INSERT INTO @FKCols(SourceFKColumnsList, TargetFKColumnsList)
    SELECT RIGHT(@SrcColumns, LEN(@SrcColumns) - 2), RIGHT(@TargetColumns, LEN(@TargetColumns) - 2)
    WHERE @SrcColumns <> ''

    RETURN
END
GO
/*
select etl.ConcatIndexColumns('NCI3_BillableTimeDim', 0)
select etl.ConcatIndexColumns('NCI3_BillableTimeDim', 1)
select etl.ConcatIndexColumns('NCI0_BillableTimeDim', 0)
select etl.ConcatIndexColumns('NCI0_BillableTimeDim', 1)
select etl.ConcatIndexColumns('NCI1_BillableTimeDim', 0)
select etl.ConcatIndexColumns('NCI1_BillableTimeDim', 1)
BillableTimeDim
select * from sys.indexes
SELECT DISTINCT IX.object_id, IXCols.column_id, IXCols.is_descending_key isDesc
FROM    sys.indexes IX
JOIN    sys.index_columns IXCols ON (IX.object_id = IXCols.object_id and IX.index_id = IXCols.index_id)
WHERE   IX.Name = 'NCI0_BillableTimeDim'
    AND IXCols.is_included_column = 1
ORDER BY IX.object_id, IXCols.column_id, IXCols.is_descending_key
*/

IF (OBJECT_ID(N'etl.ConcatIndexColumns') IS NOT NULL)
    DROP FUNCTION etl.ConcatIndexColumns;
GO

CREATE FUNCTION etl.ConcatIndexColumns (@IXName VARCHAR(512), @forIncludedColumns BIT)
RETURNS VARCHAR(MAX)
AS BEGIN
    DECLARE @IXColumn VARCHAR(512) = '',
            @IXCols VARCHAR(MAX) = '',
            @tableId INT = 0,
            @idxColumnId INT = 0,
            @columnId INT = 0,
            @isDesc BIT = 0

    SELECT  @IXCols = ''

    -- i'd to use a cursor because the distinct and order by clause
    -- was preventing concatination from happening correctly
	DECLARE ixCursor CURSOR FAST_FORWARD
	FOR SELECT DISTINCT IX.object_id, IXCols.index_column_id, IXCols.column_id, IXCols.is_descending_key isDesc
    FROM    sys.indexes IX
    JOIN    sys.index_columns IXCols ON (IX.object_id = IXCols.object_id AND IX.index_id = IXCols.index_id)
    WHERE   IX.Name = @IXName
        AND IXCols.is_included_column = @forIncludedColumns
    ORDER BY IX.object_id, IXCols.index_column_id, IXCols.column_id, IXCols.is_descending_key

	OPEN ixCursor
	FETCH NEXT FROM ixCursor INTO @tableId, @idxColumnId, @columnId, @isDesc

	WHILE @@FETCH_STATUS = 0
	BEGIN
	    SELECT @IXCols = @IXCols + ', ' + COL_NAME(@tableId, @columnId) + CASE WHEN @isDesc = 1 THEN ' DESC' ELSE '' END
	    FETCH NEXT FROM ixCursor INTO @tableId, @idxColumnId, @columnId, @isDesc
	END
	CLOSE ixCursor
	DEALLOCATE ixCursor

    SELECT @IXCols = SUBSTRING(@IXCols, 3, LEN(@IXCols))

    RETURN @IXCols
END
GO

if object_id (N'etl.[GetDateKey]', N'FN') is not null
    drop function etl.GetDateKey;
GO 
CREATE FUNCTION [etl].[GetDateKey]
( @pInputDate    DATETIME )
RETURNS int
AS
BEGIN

	RETURN CONVERT(nvarchar(8), @pInputDate, 112)

END
GO 

if object_id (N'etl.[GetFirstDayOfWeek]', N'FN') is not null
    drop function etl.GetFirstDayOfWeek;
GO 
CREATE FUNCTION [etl].[GetFirstDayOfWeek]
( @pInputDate    DATETIME )
RETURNS int
AS
BEGIN

	SET @pInputDate = CONVERT(VARCHAR(10), @pInputDate, 111)
	SET @pInputDate =  DATEADD(DD, 1 - DATEPART(DW, @pInputDate),
               @pInputDate)
    RETURN CONVERT(nvarchar(8), @pInputDate, 112)  

END
GO 

/*
This method will return the date key that corresponds to the first day of the week
for the date key that is passed into the function.

For example, a call to this function passing in the date key "20091117" will return
the value "20091115"
*/ 
if object_id (N'etl.GetFirstDayOfWeekForDateKey', N'FN') is not null
    drop function etl.[GetFirstDayOfWeekForDateKey];
GO 
CREATE FUNCTION [etl].[GetFirstDayOfWeekForDateKey]
( @pInputDateKey    INT  )
RETURNS int
AS
BEGIN

	declare @WeekKey INT
	
	select @WeekKey = 
	(
		Select MAX(DateKey) 
		from dbo.DateDim 
		where DayOfWeek = 'Sunday' and DateKey <= @pInputDateKey and DateKey > @pInputDateKey - 7
	)
    return @WeekKey

END
GO 

if object_id (N'etl.[GetFirstDayOfMonth]', N'FN') is not null
    drop function etl.GetFirstDayOfMonth;
GO 
CREATE FUNCTION [etl].[GetFirstDayOfMonth] ( @pInputDate    DATETIME )
RETURNS int
AS
BEGIN

    SET @pInputDate = CAST(CAST(YEAR(@pInputDate) AS VARCHAR(4)) + '/' + 
                CAST(MONTH(@pInputDate) AS VARCHAR(2)) + '/01' AS DATETIME)
    RETURN CONVERT(nvarchar(8), @pInputDate, 112)            

END
GO 

/*
This method will return the date key that corresponds to the first day of the month
for the date key that is passed into the function.

For example, a call to this function passing in the date key "20091117" will return
the value "20091101"
*/ 
if object_id (N'etl.[GetFirstDayOfMonthForDateKey]', N'FN') is not null
    drop function etl.GetFirstDayOfMonthForDateKey;
GO 
CREATE FUNCTION [etl].[GetFirstDayOfMonthForDateKey] ( @pInputDateKey    INT )
RETURNS int
AS
BEGIN
	declare @MonthKey INT	
	select @MonthKey = substring(cast(@pInputDateKey as NCHAR(8)),1,6) + '01'		
    return @MonthKey
END
GO 

IF (OBJECT_ID(N'etl.GetColumnTypeDefinition') IS NOT NULL)
    DROP FUNCTION etl.GetColumnTypeDefinition;
GO

CREATE FUNCTION etl.GetColumnTypeDefinition (@tableName SYSNAME, @columnName SYSNAME)
RETURNS VARCHAR(MAX)
AS BEGIN
    DECLARE @retVal VARCHAR(MAX)
    
    SELECT @retVal = '', @columnName = CASE WHEN @columnName IS NOT NULL THEN REPLACE(REPLACE(@columnName, '[', ''), ']', '') END

    SELECT  @retVal = @retVal +
            CASE WHEN @columnName IS NULL THEN col.name ELSE '' END + ' ' +
            TYPE_NAME(system_type_id) + 
            CASE
                WHEN Precision <> 0 and TYPE_NAME(system_type_id) in ('REAL','MONEY','DECIMAL','NUMERIC')
                    THEN '(' + CAST(precision AS VARCHAR) + ', ' + CAST(scale AS VARCHAR) + ')'
                WHEN TYPE_NAME(system_type_id) IN ('CHAR', 'VARCHAR')
                    THEN '(' + (CASE WHEN max_length = -1 THEN 'MAX' ELSE CAST(max_length AS VARCHAR) END) + ')'
                WHEN TYPE_NAME(system_type_id) IN ('NCHAR', 'NVARCHAR')
                    THEN '(' + (CASE WHEN max_length = -1 THEN 'MAX' ELSE CAST(max_length/2 AS VARCHAR) END) + ')'
                ELSE ''
            END +
            ',' + CHAR(13) -- --> this is to add a comma delimiter between multiple columns
    FROM    sys.columns col
    WHERE   col.object_id = ISNULL(OBJECT_ID(@tableName), col.object_id)
        AND col.name = ISNULL(@columnName, col.name)

    SELECT @retVal = LEFT(@retVal, LEN(@retVal) - 2) -- strip the last ',' + CHAR(13)
    RETURN @retVal
END
GO
if object_id (N'Staging.fn_GetConcreteRelationshipTypeId') is not null
    drop function Staging.fn_GetConcreteRelationshipTypeId
GO 
Create Function Staging.fn_GetConcreteRelationshipTypeId(@RelationshipTypeId uniqueidentifier)
returns @concreteRelationshipType TABLE (RelationshipTypeId uniqueidentifier,
                                         RelationshipTypeName nvarchar(128),
                                         BaseRelationshipTypeId uniqueidentifier,
                                         SourceManagedTypeId uniqueidentifier,
                                         TargetManagedTypeId uniqueidentifier)
BEGIN
 
with DerivedRelationshipTypes(RelationshipTypeId, RelationshipTypeName, BaseRelationshipTypeId,
SourceManagedTypeId, TargetManagedTypeId)
as
(
      SELECT RelationshipTypeId, RelationshipTypeName, BaseRelationshipTypeId,
      SourceManagedTypeId, TargetManagedTypeId FROM inbound.RelationshipType WHERE 
	  RelationshipTypeId = @RelationshipTypeId
      UNION ALL      
      SELECT a.RelationshipTypeId, a.RelationshipTypeName, a.BaseRelationshipTypeId,
      a.SourceManagedTypeId, a.TargetManagedTypeId 
       FROM inbound.RelationshipType a JOIN DerivedRelationshipTypes b
      ON a.BaseRelationshipTypeId = b.RelationshipTypeId
) 
insert @concreteRelationshipType
select RelationshipTypeId, RelationshipTypeName, BaseRelationshipTypeId,
SourceManagedTypeId, TargetManagedTypeId from  DerivedRelationshipTypes
 
IF Exists (select 1 from INFORMATION_SCHEMA.VIEWS WHERE TABLE_NAME = 'RelationshipTypeDimvw') 
 
with DerivedRelationshipTypes2(RelationshipTypeId, RelationshipTypeName, BaseRelationshipTypeId,
SourceManagedTypeId, TargetManagedTypeId)
as
(
      SELECT RelationshipTypeId, RelationshipTypeName, BaseRelationshipTypeId,
      SourceManagedTypeId, TargetManagedTypeId FROM dbo.RelationshipTypeDimvw WHERE RelationshipTypeId = @RelationshipTypeId 
      
      UNION ALL
      
      SELECT a.RelationshipTypeId, a.RelationshipTypeName, a.BaseRelationshipTypeId,
      a.SourceManagedTypeId, a.TargetManagedTypeId 
       FROM dbo.RelationshipTypeDimvw a JOIN DerivedRelationshipTypes2 b
      ON a.BaseRelationshipTypeId = b.RelationshipTypeId
)
Merge @concreteRelationshipType  as target
Using DerivedRelationshipTypes2 as source
on (target.relationshipTypeId = source.RelationshipTypeId)
WHEN NOT MATCHED BY TARGET THEN
      INSERT (RelationshipTypeId, RelationshipTypeName, BaseRelationshipTypeId,
SourceManagedTypeId, TargetManagedTypeId) VALUES (source.RelationshipTypeId, 
source.RelationshipTypeName, source.BaseRelationshipTypeId,
source.SourceManagedTypeId, source.TargetManagedTypeId);
Return
END
GO



IF OBJECT_ID (N'etl.[GetNextFileGroupName]', N'FN') IS NOT NULL
    DROP FUNCTION etl.GetNextFileGroupName;
GO 

CREATE FUNCTION [etl].[GetNextFileGroupName] (@warehouseEntityId INT)
RETURNS SYSNAME
AS BEGIN
    DECLARE @fileGroupName      SYSNAME,
            @fileGroupCount     INT,
            @partitionCount     INT,
            @fileGroupIndex     INT

    SELECT  @fileGroupCount = (SELECT COUNT(*) FROM sys.filegroups WHERE name LIKE '%Facts%'),
            @partitionCount = (SELECT COUNT(*) FROM etl.TablePartition WHERE EntityId = @warehouseEntityId) + 1 -- + 1 to account for the new partition

    IF(@fileGroupCount = 0) RETURN NULL;

    SELECT @fileGroupIndex = @partitionCount % @fileGroupCount
    SELECT @fileGroupIndex = ISNULL(NULLIF(@fileGroupIndex, 0), @fileGroupCount)

    ;WITH FGs(RowId, name)
    AS (
        SELECT  ROW_NUMBER() OVER (ORDER BY data_space_id) AS RowId,
                name
        FROM    sys.filegroups
        WHERE   name LIKE '%Facts%'
    )
    SELECT @fileGroupName = name
    FROM FGs
    WHERE RowId = @fileGroupIndex

    RETURN @fileGroupName
END
GO 


IF OBJECT_ID (N'etl.[GetConfigurationInfo]', N'FN') IS NOT NULL
    DROP FUNCTION etl.GetConfigurationInfo;
GO 

CREATE FUNCTION [etl].[GetConfigurationInfo] (@configurationFilter NVARCHAR(512), @configurationPath NVARCHAR(1024))
RETURNS NVARCHAR(MAX)
AS BEGIN
    DECLARE @configurationValue NVARCHAR(MAX) = NULL
    
    SELECT @configurationValue = ConfiguredValue
    FROM etl.Configuration
    WHERE ConfigurationFilter = @configurationFilter
        AND ConfigurationPath = @configurationPath

    RETURN @configurationValue
END
GO

if object_id (N'dbo.fn_GetFlattenedManagedTypeHierarchy') is not null
    drop function dbo.fn_GetFlattenedManagedTypeHierarchy
GO 


CREATE FUNCTION dbo.fn_GetFlattenedManagedTypeHierarchy (
    @rootTypeName nvarchar(256)
)
RETURNS @flattenedManagedTypes TABLE(
    DatasourceId uniqueidentifier,
    BaseManagedTypeId uniqueidentifier,
    ManagedTypeId uniqueidentifier,
    BaseManagedTypeDimKey int,
    ManagedTypeDimKey int, 
    BaseManagedTypeName nvarchar(255),
    ManagedTypeName nvarchar(255),   
    Level int
)
AS BEGIN

DECLARE @rootManagedTypeId uniqueidentifier = NULL

IF @rootTypeName IS NOT NULL
BEGIN
  SELECT @rootManagedTypeId = ManagedTypeId from dbo.ManagedTypeDimvw where TypeName = @rootTypeName
END

IF @rootManagedTypeId IS NULL 
BEGIN
	RETURN;
END

;with
 DerivedManagedTypes(DatasourceId, BaseManagedTypeId,  ManagedTypeId, BaseManagedTypeDimKey, ManagedTypeDimKey, BaseManagedTypeName, ManagedTypeName, Level) as
 (
  select SourceId  as DatasourceId,
      BaseManagedTypeId as BaseManagedTypeId,
   ManagedTypeId as ManagedTypeId,   
   0 as BaseManagedTypeDimKey,
   ManagedTypeDimKey as ManagedTypeDimKey, 
   CAST('' as nvarchar(255))    as BaseManagedTypeName,
   TypeName        as ManagedTypeName,  
   1               as Level
  from dbo.ManagedTypeDimvw md 
  where md.BaseManagedTypeId = ISNULL(@rootManagedTypeId, md.BaseManagedTypeId)
  
  union all

  select derivedTypes.SourceId as DatasourceId ,
   baseTypes.BaseManagedTypeId as BaseManagedTypeId,
   derivedTypes.ManagedTypeId      as ManagedTypeId,
   baseTypes.ManagedTypeDimKey as BaseManagedTypeDimKey,
   derivedTypes.ManagedTypeDimKey as ManagedTypeDimKey,   
   baseTypes.ManagedTypeName as BaseManagedTypeName,
   derivedTypes.TypeName as ManagedTypeName,
   baseTypes.Level + 1             as Level
  from DerivedManagedTypes as baseTypes
  inner join dbo.ManagedTypeDimvw as derivedTypes on 
   baseTypes.DatasourceId = derivedTypes.SourceId and derivedTypes.BaseManagedTypeId = baseTypes.ManagedTypeId
 ) 
 insert into @flattenedManagedTypes
 select *
 from DerivedManagedTypes d

    RETURN;
END
GO
if object_id (N'dbo.fn_GetFlattenedRelationshipTypeHierarchy') is not null
    drop function dbo.fn_GetFlattenedRelationshipTypeHierarchy
GO


CREATE FUNCTION dbo.fn_GetFlattenedRelationshipTypeHierarchy (
    @rootTypeName nvarchar(256)
)
RETURNS @flattenedRelationshipTypes TABLE(
    DatasourceId uniqueidentifier,
    BaseRelationshipTypeId uniqueidentifier,
    RelationshipTypeId uniqueidentifier,
    BaseRelationshipTypeDimKey int,
    RelationshipTypeDimKey int,
    BaseRelationshipTypeName nvarchar(255),
    RelationshipTypeName nvarchar(255),
    SourceManagedTypeId uniqueidentifier,
    TargetManagedTypeId uniqueidentifier,
    Level int
)
AS BEGIN

    ;with
    DerivedRelationshipTypes(DatasourceId, BaseRelationshipTypeId,  RelationshipTypeId, BaseRelationshipTypeDimKey, RelationshipTypeDimKey, BaseRelationshipTypeName, RelationshipTypeName, SourceManagedTypeId, TargetManagedTypeId, Level) as
    (
        select SourceId        as DatasourceId,
            BaseRelationshipTypeId as BaseRelationshipTypeId,
            RelationshipTypeId    as RelationshipTypeId,
            0 as BaseRelationshipTypeDimKey,
            RelationshipTypeDimKey    as RelationshipTypeDimKey,
            CAST('' as nvarchar(255))    as BaseRelationshipTypeName,
            RelationshipTypeName        as RelationshipTypeName,
            SourceManagedTypeId         as SourceManagedTypeId,
            TargetManagedTypeId         as TargetManagedTypeId,
            1               as Level
        from dbo.RelationshipTypeDim rtd
        where rtd.RelationshipTypeName = ISNULL(@rootTypeName, rtd.RelationshipTypeName)

        union all

        select baseTypes.DatasourceId as DatasourceId,
            baseTypes.BaseRelationshipTypeId as BaseRelationshipTypeId,
            derivedTypes.RelationshipTypeId  as RelationshipTypeId,
            baseTypes.RelationshipTypeDimKey as BaseRelationshipTypeDimKey,
            derivedTypes.RelationshipTypeDimKey as RelationshipTypeDimKey,
            baseTypes.RelationshipTypeName    as BaseRelationshipTypeName,
            derivedTypes.RelationshipTypeName        as RelationshipTypeName,
            derivedTypes.SourceManagedTypeId         as SourceManagedTypeId,
            derivedTypes.TargetManagedTypeId         as TargetManagedTypeId,
            baseTypes.Level + 1             as Level
        from DerivedRelationshipTypes as baseTypes
        inner join dbo.RelationshipTypeDim as derivedTypes on
            baseTypes.DatasourceId = derivedTypes.SourceId and derivedTypes.BaseRelationshipTypeId = baseTypes.RelationshipTypeId
    )
    insert into @flattenedRelationshipTypes
    select *
    from DerivedRelationshipTypes d

    RETURN;
END

GO
IF OBJECT_ID(N'dbo.p_MakeSynonym') IS NOT NULL 
  DROP PROCEDURE dbo.p_MakeSynonym
go

CREATE PROCEDURE dbo.p_MakeSynonym
(
  @dbname sysname,
  @schemaname sysname,
  @objectname sysname
)
AS
BEGIN 
SET NOCOUNT ON

-- If Synonym already exists, just return
IF OBJECT_ID(@schemaname + N'.' + @objectname) IS NOT NULL
    RETURN 0

DECLARE @Command nvarchar(max)
SET @Command = N'CREATE SYNONYM ' + @schemaname + N'.' + @objectname + N' FOR ' + @dbname + N'.' + @schemaname + N'.' + @objectname

EXEC (@Command)

RETURN 0
END

GO
 IF NOT EXISTS (SELECT * FROM sysobjects WHERE type = 'P' AND name = 'DomainTableIndexOptimize')
	BEGIN
		EXECUTE ('CREATE PROCEDURE dbo.DomainTableIndexOptimize AS RETURN 1')
	END
GO

ALTER PROCEDURE dbo.DomainTableIndexOptimize
   @DatasetId                               uniqueidentifier = NULL
  ,@MinAvgFragmentationInPercentToOptimize  int = 10
  ,@TargetFillfactor                        int = 100
  ,@BlockingMaintenanceStartTime            char(5) = '01:00'
  ,@BlockingMaintenanceDurationMinutes      int = 240
  ,@StatisticsUpdateMaxDurationSeconds      int = 15
  ,@StatisticsUpdateMaxStatAgeHours         int = 12
  ,@StatisticsSamplePercentage              int = NULL
  ,@MinAvgFragmentationInPercentToReorg     int = NULL
  ,@NumberOfIndexesToOptimize               int = 1
AS
BEGIN
  SET NOCOUNT ON
  
  DECLARE 
     @ErrorInd        bit
    ,@ErrorMessage    nvarchar(max)
    ,@ErrorNumber     int
    ,@ErrorSeverity   int
    ,@ErrorState      int
    ,@ErrorLine       int
    ,@ErrorProcedure  nvarchar(256)
    ,@ErrorMessageText nvarchar(max)
    
  SET @ErrorInd = 0
  
  BEGIN TRY
    DECLARE
       @DomainTableIndexRowId int
      ,@IndexOptimizedInd bit
      ,@TableObjectId int
      ,@IndexId int
      ,@BeforeAvgFragmentationInPercent float
      ,@AfterAvgFragmentationInPercent float
      ,@LockResourceName sysname
      ,@ExecResult int
      ,@LockSetInd bit
      ,@TableName nvarchar(256)
      ,@IndexName sysname
      ,@OnlineStatement nvarchar(1000)
      ,@OfflineStatement nvarchar(1000)
      ,@ReorganizeStatement nvarchar(1000)
      ,@OnlineRebuildInd bit
      ,@IndexReorganized bit
      ,@OptimizationStartDateTime datetime
      ,@CanPerformBlockingOptimizationInd bit
      ,@NumberOfIndexesOptimized int
      
      ,@StatsUpdateProcessStartDateTime datetime
      ,@StatisticName sysname
      ,@StatsUpdateStartDateTime datetime
      ,@DomainTableRowId int
      ,@RebuildFillFactor int
    
    -- set dataset domain table optimization lock

    SELECT @LockResourceName =
      CASE
        WHEN @DatasetId IS NOT NULL THEN CAST(@DatasetId AS varchar(50)) + '_OptimizeDomain'
        ELSE 'MainDS_OptimizeDomain'
      END
  
    EXEC @ExecResult = sp_getapplock
           @Resource = @LockResourceName
          ,@LockMode = 'Exclusive'
          ,@LockOwner = 'Session'
          ,@LockTimeout = 0

    IF (@ExecResult < -1)
    BEGIN
      RAISERROR(777971001, 16, 1, 'DomainTableOptimize', @ExecResult)
    END
    
    IF (@ExecResult = -1)
    BEGIN
      RETURN
    END
    
    SET @LockSetInd = 1
    
    -- delete old optimization history records
    DELETE DomainTableIndexOptimizationHistory
    WHERE (OptimizationStartDateTime < DATEADD(day, -7, GETUTCDATE()))

    -- fugure out if we can perform blocking maintenance
    SET @CanPerformBlockingOptimizationInd =
      CASE
        WHEN (DATEDIFF(minute, CONVERT(char(8), GETDATE(), 112) + ' ' + @BlockingMaintenanceStartTime, GETDATE()) < @BlockingMaintenanceDurationMinutes)
          THEN 1
        ELSE 0
      END

    SET @IndexOptimizedInd = 0
    SET @DomainTableIndexRowId = 0
    SET @NumberOfIndexesOptimized = 0
    
    WHILE ((@NumberOfIndexesToOptimize = 0) OR (@NumberOfIndexesToOptimize > @NumberOfIndexesOptimized))
      AND (EXISTS (SELECT *
                   FROM DomainTableIndex i
                          JOIN DomainTable t ON (i.DomainTableRowId = t.DomainTableRowId)
                   WHERE (i.DomainTableIndexRowId > @DomainTableIndexRowId)
                     AND (i.LastConsideredForOptimizationDateTime < DATEADD(minute, -i.OptimizationFrequencyMinutes, GETUTCDATE()))
                     AND ((@DatasetId = t.DatasetId) OR ((@DatasetId IS NULL) AND (t.DatasetId IS NULL)))
                  )
          )
    BEGIN
      SET @IndexOptimizedInd = 0
      SET @IndexReorganized = 0
      SET @OnlineRebuildInd = 0

      SELECT TOP 1
         @DomainTableIndexRowId = i.DomainTableIndexRowId
        ,@TableObjectId = t.TableObjectId
        ,@IndexId = i.IndexId
        ,@TableName = t.TableName
        ,@IndexName = i.IndexName
        ,@RebuildFillFactor = i.RebuildFillFactor
      FROM DomainTableIndex i
            JOIN DomainTable t ON (i.DomainTableRowId = t.DomainTableRowId)
      WHERE (i.DomainTableIndexRowId > @DomainTableIndexRowId)
        AND (i.LastConsideredForOptimizationDateTime < DATEADD(minute, -i.OptimizationFrequencyMinutes, GETUTCDATE()))
        AND ((@DatasetId = t.DatasetId) OR ((@DatasetId IS NULL) AND (t.DatasetId IS NULL)))
      ORDER BY i.DomainTableIndexRowId
      
      -- check table / index exist and ids match
      IF NOT EXISTS (SELECT *
                     FROM sys.tables t
                            JOIN sys.indexes i ON (t.object_id = i.object_id)
                            JOIN sys.schemas s ON (t.schema_id = s.schema_id)
                     WHERE (QUOTENAME(s.name) + '.' + QUOTENAME(t.name) = @TableName)
                       AND (t.object_id = @TableObjectId)
                       AND (i.name = @IndexName)
                       AND (i.index_id = @IndexId)
                    )
      BEGIN
        INSERT DomainTableIndexOptimizationHistory (
           DomainTableIndexRowId
          ,OptimizationStartDateTime
          ,OptimizationDurationSeconds
          ,BeforeAvgFragmentationInPercent
          ,AfterAvgFragmentationInPercent
          ,OptimizationMethod
        )
        VALUES (
           @DomainTableIndexRowId
          ,GETUTCDATE()
          ,0
          ,0
          ,0
          ,'none - tbl/ind not found or obj ids don''t match'
        )

        DELETE DomainTableIndex
        WHERE (DomainTableIndexRowId = @DomainTableIndexRowId)
        
        CONTINUE
      END
      
      IF NOT EXISTS (SELECT *
                     FROM sys.tables t
                            JOIN sys.schemas s ON (t.schema_id = s.schema_id)
                     WHERE (QUOTENAME(s.name) + '.' + QUOTENAME(t.name) = @TableName)
                       AND (t.object_id = @TableObjectId)
                    )
      BEGIN
        DELETE DomainTable
        WHERE TableObjectId = @TableObjectId
      END

      SELECT @BeforeAvgFragmentationInPercent = avg_fragmentation_in_percent
      FROM sys.dm_db_index_physical_stats(DB_ID(), @TableObjectId, @IndexId, NULL, NULL)
      WHERE alloc_unit_type_desc = 'IN_ROW_DATA'
      -- If rebuild fillfactor is not defined in dbo.DomainTableIndex.[RebuildFillFactor], than take it from input parameter (by default 100%)
      IF (@RebuildFillFactor IS NULL)
      BEGIN
		SET @RebuildFillFactor = @TargetFillFactor
      END
      
      IF (@BeforeAvgFragmentationInPercent >= @MinAvgFragmentationInPercentToOptimize) OR ((@MinAvgFragmentationInPercentToReorg IS NOT NULL) AND (@BeforeAvgFragmentationInPercent> = @MinAvgFragmentationInPercentToReorg))
      BEGIN
        SET @OnlineStatement = 'ALTER INDEX ' + QUOTENAME(@IndexName) + ' ON ' + @TableName + ' REBUILD WITH (ONLINE=ON, FILLFACTOR=' + CAST(@RebuildFillFactor AS varchar) + ')'
        SET @OfflineStatement = 'ALTER INDEX ' + QUOTENAME(@IndexName) + ' ON ' + @TableName + ' REBUILD WITH (FILLFACTOR=' + CAST(@RebuildFillFactor AS varchar) + ')'
        SET @ReorganizeStatement = 'ALTER INDEX ' + QUOTENAME(@IndexName) + ' ON ' + @TableName + ' REORGANIZE'

        SET @OptimizationStartDateTime = GETUTCDATE()

        -- Check if a rebuild is necessary.        
        IF (@BeforeAvgFragmentationInPercent >= @MinAvgFragmentationInPercentToOptimize)
        BEGIN
          -- try online rebuild first
          BEGIN TRY
            EXECUTE (@OnlineStatement)
            
            SET @IndexOptimizedInd = 1
            SET @OnlineRebuildInd = 1
            SET @NumberOfIndexesOptimized = @NumberOfIndexesOptimized + 1
          END TRY
          BEGIN CATCH
            SET @OnlineRebuildInd = 0
          END CATCH
        
          -- do offline optimization only if online failed
          -- and we are in allowed window
          IF (@IndexOptimizedInd = 0) AND (@CanPerformBlockingOptimizationInd = 1)
          BEGIN
            EXECUTE (@OfflineStatement)
            
            SET @IndexOptimizedInd = 1
            SET @NumberOfIndexesOptimized = @NumberOfIndexesOptimized + 1
          END
        END

        -- if we didn't rebuild the index, and reorganizing the index is an option, give it a try.
        IF (@IndexOptimizedInd = 0) AND (@MinAvgFragmentationInPercentToReorg IS NOT NULL) AND (@BeforeAvgFragmentationInPercent> = @MinAvgFragmentationInPercentToReorg)
        BEGIN
          EXECUTE (@ReorganizeStatement)
          
          SET @IndexOptimizedInd = 1
          SET @IndexReorganized = 1
          SET @NumberOfIndexesOptimized = @NumberOfIndexesOptimized + 1
        END
        
        SELECT @AfterAvgFragmentationInPercent = avg_fragmentation_in_percent
        FROM sys.dm_db_index_physical_stats(DB_ID(), @TableObjectId, @IndexId, NULL, NULL)
        WHERE alloc_unit_type_desc = 'IN_ROW_DATA'
     
        INSERT DomainTableIndexOptimizationHistory (
           DomainTableIndexRowId
          ,OptimizationStartDateTime
          ,OptimizationDurationSeconds
          ,BeforeAvgFragmentationInPercent
          ,AfterAvgFragmentationInPercent
          ,OptimizationMethod
        )
        SELECT
           @DomainTableIndexRowId
          ,@OptimizationStartDateTime
          ,ABS(DATEDIFF(second, @OptimizationStartDateTime, GETUTCDATE()))
          ,@BeforeAvgFragmentationInPercent
          ,@AfterAvgFragmentationInPercent
          ,CASE @IndexOptimizedInd
             WHEN 0 THEN 'none - blocking optimization not allowed'
             ELSE CASE 
                    WHEN @OnlineRebuildInd = 1 THEN 'online rebuild'
                    WHEN @IndexReorganized = 1 THEN 'online reorganize'
                    ELSE 'offline rebuild'
                  END
           END
      END

      -- mark table as "considered" and move on
      UPDATE DomainTableIndex
      SET LastConsideredForOptimizationDateTime = GETUTCDATE()
      WHERE (DomainTableIndexRowId = @DomainTableIndexRowId)
    END
    
    -- delete old stats update history records
    DELETE DomainTableStatisticsUpdateHistory
    WHERE (UpdateStartDateTime < DATEADD(day, -7, GETUTCDATE()))

      -- Update statistics.
      SET @DomainTableRowId = 0;
      SET @StatisticName = '';
      SET @StatsUpdateProcessStartDateTime = GETUTCDATE()
      
      WHILE (DATEADD(second, -@StatisticsUpdateMaxDurationSeconds, GETUTCDATE()) < @StatsUpdateProcessStartDateTime)
      BEGIN
        SET @TableName = NULL
        
        SELECT TOP 1 
           @DomainTableRowId = d.DomainTableRowId
          ,@TableName = d.TableName
          ,@StatisticName = s.name
        FROM sys.stats s
              JOIN sys.objects o ON (s.object_id = o.object_id)
              JOIN DomainTable d on (d.TableObjectId = o.object_id)
        WHERE (s.auto_created = 0)
          AND (s.no_recompute = 0)
          AND ((d.DomainTableRowId > @DomainTableRowId) OR (((d.DomainTableRowId = @DomainTableRowId)) AND (s.name > @StatisticName)))
          AND (STATS_DATE(s.object_id, s.stats_id) < DATEADD(hour, -@StatisticsUpdateMaxStatAgeHours, GETDATE()))
        ORDER BY d.DomainTableRowId ASC, s.name ASC

        IF (@TableName IS NULL)
        BEGIN
          BREAK
        END
        ELSE
        BEGIN
          SET @OnlineStatement = 'UPDATE STATISTICS ' + @TableName + ' ' + QUOTENAME(@StatisticName)
          
          IF (@StatisticsSamplePercentage >= 100)
            SET @OnlineStatement = @OnlineStatement + ' WITH FULLSCAN'
          ELSE IF (@StatisticsSamplePercentage > 0)
            SET @OnlineStatement = @OnlineStatement + ' WITH SAMPLE ' + CAST(@StatisticsSamplePercentage AS varchar(10)) + ' PERCENT'
            
          SET @StatsUpdateStartDateTime = GETUTCDATE()
          
          EXECUTE (@OnlineStatement)
          
          INSERT DomainTableStatisticsUpdateHistory (
             DomainTableRowId
            ,StatisticName
            ,UpdateStartDateTime
            ,UpdateDurationSeconds
            ,RowsSampledPercentage
          )
          VALUES
          (
             @DomainTableRowId
            ,@StatisticName
            ,@StatsUpdateStartDateTime
            ,ABS(DATEDIFF(second, @StatsUpdateStartDateTime, GETUTCDATE()))
            ,@StatisticsSamplePercentage
          )
        END
      END
  END TRY
  BEGIN CATCH
    IF (@@TRANCOUNT > 0)
      ROLLBACK TRAN
  
    SELECT 
       @ErrorNumber = ERROR_NUMBER()
      ,@ErrorSeverity = ERROR_SEVERITY()
      ,@ErrorState = ERROR_STATE()
      ,@ErrorLine = ERROR_LINE()
      ,@ErrorProcedure = ISNULL(ERROR_PROCEDURE(), '-')
      ,@ErrorMessageText = ERROR_MESSAGE()

    SET @ErrorInd = 1
  END CATCH

  IF (@LockSetInd = 1)
  BEGIN
    EXEC @ExecResult = sp_releaseapplock
               @Resource = @LockResourceName
              ,@LockOwner = 'Session'
  END

  -- report error if any
  IF (@ErrorInd = 1)
  BEGIN
    DECLARE @AdjustedErrorSeverity int

    SET @AdjustedErrorSeverity = CASE
                                   WHEN @ErrorSeverity > 18 THEN 18
                                   ELSE @ErrorSeverity
                                 END
    
    RAISERROR (777971002, @AdjustedErrorSeverity, 1
      ,@ErrorNumber
      ,@ErrorSeverity
      ,@ErrorState
      ,@ErrorProcedure
      ,@ErrorLine
      ,@ErrorMessageText
    )
  END
  
  RETURN @IndexOptimizedInd
END
GO
 IF NOT EXISTS (SELECT * FROM sysobjects WHERE type = 'P' AND name = 'DomainTableRegisterIndexOptimization')
	BEGIN
		EXECUTE ('CREATE PROCEDURE dbo.DomainTableRegisterIndexOptimization AS RETURN 1')
	END
GO

ALTER PROCEDURE dbo.DomainTableRegisterIndexOptimization
   @TableName                         nvarchar(256)
  ,@IndexOptimizationFrequencyMinutes int = 240
  ,@DatasetId                         uniqueidentifier = NULL
  ,@IncludeClusteredIndex             bit = 0
  ,@RebuildFillFactor                 int = NULL 
AS
BEGIN
  SET NOCOUNT ON
  
  DECLARE @Error int
  DECLARE @DomainTableRowId int
  DECLARE @Trancount int
  
  SET @Trancount = @@TRANCOUNT

  BEGIN TRAN
  
  SELECT @Error = @@ERROR
  IF @Error <> 0 GOTO Quit

  DELETE i
  FROM DomainTableIndex i
        JOIN DomainTable t WITH (UPDLOCK) ON (i.DomainTableRowId = t.DomainTableRowId)
  WHERE (t.TableObjectId = OBJECT_ID(@TableName))
  
  SELECT @Error = @@ERROR
  IF @Error <> 0 GOTO Quit

  DELETE DomainTable
  WHERE (TableObjectId = OBJECT_ID(@TableName))
  
  SELECT @Error = @@ERROR
  IF @Error <> 0 GOTO Quit

  INSERT DomainTable (
     TableObjectId
    ,TableName
    ,DatasetId
  )
  VALUES
  (
     OBJECT_ID(@TableName)
    ,@TableName
    ,@DatasetId
  )

  SELECT @DomainTableRowId = @@IDENTITY

  SELECT @Error = @@ERROR
  IF @Error <> 0 GOTO Quit

  INSERT DomainTableIndex (
     DomainTableRowId
    ,IndexId
    ,IndexName
    ,OptimizationFrequencyMinutes
    ,RebuildFillFactor
  )
  SELECT
     @DomainTableRowId
    ,sys.indexes.index_id
    ,sys.indexes.[name]
    ,@IndexOptimizationFrequencyMinutes
    ,@RebuildFillFactor   
  FROM sys.indexes
  WHERE (object_id = OBJECT_ID(@TableName))
    AND (index_id > (SELECT CASE @IncludeClusteredIndex WHEN 0 THEN 1 ELSE 0 END))

  SELECT @Error = @@ERROR
  IF @Error <> 0 GOTO Quit

  COMMIT
      
Quit:
  IF (@@TRANCOUNT > @Trancount)
    ROLLBACK
END
GO

 IF NOT EXISTS (SELECT * FROM sysobjects WHERE type = 'P' AND name = 'DomainTableUnregisterIndexOptimization')
	BEGIN
		EXECUTE ('CREATE PROCEDURE dbo.DomainTableUnregisterIndexOptimization AS RETURN 1')
	END
GO

ALTER PROCEDURE dbo.DomainTableUnregisterIndexOptimization
   @TableName                         nvarchar(256)
AS
BEGIN
  SET NOCOUNT ON
  
  DECLARE @Error int
  DECLARE @Trancount int
  
  SET @Trancount = @@TRANCOUNT

  BEGIN TRAN
  
  SELECT @Error = @@ERROR
  IF @Error <> 0 GOTO Quit

  DELETE i
  FROM DomainTableIndex i
        JOIN DomainTable t WITH (UPDLOCK) ON (i.DomainTableRowId = t.DomainTableRowId)
  WHERE (t.TableObjectId = OBJECT_ID(@TableName))
  
  SELECT @Error = @@ERROR
  IF @Error <> 0 GOTO Quit

  DELETE DomainTable
  WHERE (TableObjectId = OBJECT_ID(@TableName))
 
  SELECT @Error = @@ERROR
  IF @Error <> 0 GOTO Quit

  COMMIT
      
Quit:
  IF (@@TRANCOUNT > @Trancount)
    ROLLBACK
END
GO
 IF NOT EXISTS (SELECT * FROM sysobjects WHERE type = 'P' AND name = 'DebugMessageInsert')
	BEGIN
		EXECUTE ('CREATE PROCEDURE DebugMessageInsert AS RETURN 1')
	END
GO

ALTER PROCEDURE DebugMessageInsert
   @DatasetId   uniqueidentifier
  ,@MessageLevel int
  ,@MessageText nvarchar(max)
  ,@OperationDurationMs bigint = NULL
AS
BEGIN
  SET NOCOUNT ON
  
  DELETE DebugMessage
  WHERE MessageDateTime < DATEADD(day, -7, GETUTCDATE())
  
  INSERT DebugMessage (
     DatasetId
    ,MessageLevel
    ,MessageText
    ,OperationDurationMs
  )
  VALUES (
     @DatasetId
    ,@MessageLevel
    ,@MessageText
    ,@OperationDurationMs
  )
END
GO


 IF NOT EXISTS (SELECT * FROM sysobjects WHERE type = 'P' AND name = 'StandardDatasetOptimize')
	BEGIN
		EXECUTE ('CREATE PROCEDURE StandardDatasetOptimize AS RETURN 1')
	END
GO

ALTER PROCEDURE StandardDatasetOptimize
   @DatasetId uniqueidentifier
  ,@MinAvgFragmentationInPercentToOptimize  int = 10
  ,@MinAvgFragmentationInPercentToRebuild   int = 30
AS
BEGIN
  SET NOCOUNT ON

  DECLARE 
     @ErrorInd        bit
    ,@ErrorMessage    nvarchar(max)
    ,@ErrorNumber     int
    ,@ErrorSeverity   int
    ,@ErrorState      int
    ,@ErrorLine       int
    ,@ErrorProcedure  nvarchar(256)
    ,@ErrorMessageText nvarchar(max)

  SET @ErrorInd = 0

  DECLARE
  
     @DebugLevel tinyint
    ,@DebugMessage nvarchar(max)
    ,@StandardDatasetTableMapRowId int
    ,@TableNameSuffix varchar(50)
    ,@StandardDatasetAggregationStorageRowId int
    ,@AggregationTypeId int
    ,@FoundNonoptimalIndexInd bit
    ,@TableName sysname
    ,@TableNameWithSchema nvarchar(1000)
    ,@IndexName sysname
    ,@PrimaryKeyInd bit
    ,@AvgFragmentationInPercent float
    ,@StandardDatasetOptimizationHistoryRowId bigint
    ,@OnlineRebuildPossibleInd bit
    ,@CanPerformBlockingOptimizationInd bit
    ,@OptimizationStartDateTime datetime
    ,@IndexOptimized bit
    ,@IndexRebuild bit
    ,@InsertInd bit
    ,@OperationDurationMs bigint
    ,@MainTableName sysname
    ,@Statement nvarchar(max)
    ,@EffectiveStatement nvarchar(max)
    ,@StandardDatasetAggregationStorageIndexRowId int
    ,@IndexId int
    ,@AfterAvgFragmentationInPercent float
    ,@OnlineRebuildInd bit
    ,@SchemaName nvarchar(256)
    ,@BlockingMaintenanceStartTime char(5)
    ,@BlockingMaintenanceDurationMinutes int
    
    ,@StatisticsMaxAgeHours int
    ,@StatisticsUpdateSamplePercentage int
    ,@StatisticsUpdateStartDateTime datetime
    ,@StatisticsUpdateDurationSeconds int
    ,@StatisticUpdatedInd bit
    ,@StatisticsUpdateMethod varchar(50)

    ,@LockResourceName sysname
    ,@ExecResult int
    ,@LockSetInd bit

  BEGIN TRY
    SELECT
       @DebugLevel = DebugLevel
      ,@SchemaName = SchemaName
      ,@BlockingMaintenanceStartTime = BlockingMaintenanceDailyStartTime
      ,@BlockingMaintenanceDurationMinutes = BlockingMaintenanceDurationMinutes
    FROM StandardDataset
    WHERE DatasetId = @DatasetId
    
    -- set lock to make sure only one process
    -- performs optimization on this data set
   SELECT @LockResourceName =
      CASE
        WHEN @DatasetId IS NOT NULL THEN CAST(@DatasetId AS varchar(50)) + '_Optimize'
        ELSE 'OptimizeDomainTables'
      END
  
    EXEC @ExecResult = sp_getapplock
           @Resource = @LockResourceName
          ,@LockMode = 'Exclusive'
          ,@LockOwner = 'Session'
          ,@LockTimeout = 0

    IF (@ExecResult < -1)
    BEGIN
      RAISERROR(777971001, 16, 1, 'StandardDatasetOptimize', @ExecResult)
    END
    
    IF (@ExecResult = -1)
    BEGIN
      RETURN
    END
    
    SET @LockSetInd = 1

    --********************************************************
    -- Optimize domain tables
    
    EXEC DomainTableIndexOptimize
          @DatasetId = @DatasetId
         ,@BlockingMaintenanceStartTime = @BlockingMaintenanceStartTime
         ,@BlockingMaintenanceDurationMinutes = @BlockingMaintenanceDurationMinutes

    --********************************************************
    -- Insert new optimization work items
   
    -- groom optimization history
    DELETE StandardDatasetOptimizationHistory
    WHERE (OptimizationDurationSeconds IS NOT NULL)
      AND (OptimizationStartDateTime < DATEADD(day, -7, GETUTCDATE()))
    
    -- add indexes for optimization
    INSERT StandardDatasetOptimizationHistory (StandardDatasetTableMapRowId, StandardDatasetAggregationStorageIndexRowId)
    SELECT m.StandardDatasetTableMapRowId, i.StandardDatasetAggregationStorageIndexRowId
    FROM StandardDatasetTableMap m
          JOIN StandardDatasetAggregationStorage s ON (m.DatasetId = s.DatasetId) AND (m.AggregationTypeId = s.AggregationTypeId)
          JOIN StandardDatasetAggregationStorageIndex i ON (s.StandardDatasetAggregationStorageRowId = i.StandardDatasetAggregationStorageRowId)
          JOIN StandardDatasetAggregation a ON (m.DatasetId = a.DatasetId) AND (m.AggregationTypeId = a.AggregationTypeId)
    WHERE (m.DatasetId = @DatasetId)
      AND ((m.OptimizedInd = 0) OR (m.InsertInd = 1))
      AND (NOT EXISTS (SELECT *
                       FROM StandardDatasetOptimizationHistory
                       WHERE (StandardDatasetTableMapRowId = m.StandardDatasetTableMapRowId)
                         AND (StandardDatasetAggregationStorageIndexRowId = i.StandardDatasetAggregationStorageIndexRowId)
                         AND ((OptimizationDurationSeconds IS NULL)
                              OR
                              (OptimizationStartDateTime > DATEADD(minute, -a.IndexOptimizationIntervalMinutes, GETUTCDATE()))
                             )
                      )
          )
     
    --********************************************************
    -- set "optimized" property on optimized tables

    SET @StandardDatasetTableMapRowId = 0
    
    WHILE EXISTS (SELECT *
                  FROM StandardDatasetTableMap m
                        JOIN StandardDatasetAggregationStorage s ON (m.DatasetId = s.DatasetId) AND (m.AggregationTypeId = s.AggregationTypeId)
                        LEFT JOIN StandardDatasetAggregationStorageIndex i ON (s.StandardDatasetAggregationStorageRowId = i.StandardDatasetAggregationStorageRowId)
                  WHERE (m.DatasetId = @DatasetId)
                    AND (m.OptimizedInd = 0)
                    AND (m.InsertInd = 0)
                    AND (m.StandardDatasetTableMapRowId > @StandardDatasetTableMapRowId)
                    AND (NOT EXISTS (SELECT *
                                     FROM StandardDatasetOptimizationHistory
                                     WHERE (StandardDatasetTableMapRowId = m.StandardDatasetTableMapRowId)
                                       AND (StandardDatasetAggregationStorageIndexRowId = i.StandardDatasetAggregationStorageIndexRowId)
                                       AND (OptimizationStartDateTime IS NULL)
                                    )
                        )
                 )
    BEGIN
      SELECT TOP 1
         @StandardDatasetTableMapRowId = m.StandardDatasetTableMapRowId
        ,@TableNameSuffix = m.TableNameSuffix
        ,@AggregationTypeId = m.AggregationTypeId
        ,@InsertInd = m.InsertInd
        ,@StatisticsMaxAgeHours = a.StatisticsMaxAgeHours
      FROM StandardDatasetTableMap m
            JOIN StandardDatasetAggregationStorage s ON (m.DatasetId = s.DatasetId) AND (m.AggregationTypeId = s.AggregationTypeId)
            JOIN StandardDatasetAggregation a ON (m.DatasetId = a.DatasetId) AND (m.AggregationTypeId = a.AggregationTypeId)
            LEFT JOIN StandardDatasetAggregationStorageIndex i ON (s.StandardDatasetAggregationStorageRowId = i.StandardDatasetAggregationStorageRowId)
      WHERE (m.DatasetId = @DatasetId)
        AND (m.OptimizedInd = 0)
        AND (m.InsertInd = 0)
        AND (m.StandardDatasetTableMapRowId > @StandardDatasetTableMapRowId)
        AND (NOT EXISTS (SELECT *
                         FROM StandardDatasetOptimizationHistory
                         WHERE (StandardDatasetTableMapRowId = m.StandardDatasetTableMapRowId)
                           AND (StandardDatasetAggregationStorageIndexRowId = i.StandardDatasetAggregationStorageIndexRowId)
                           AND (OptimizationStartDateTime IS NULL)
                        )
            )
      ORDER BY m.AggregationTypeId, m.StandardDatasetTableMapRowId
      
      -- scroll through storage tables
      SET @StandardDatasetAggregationStorageRowId = 0
      SET @FoundNonoptimalIndexInd = 0
      SET @MainTableName = NULL
      
      WHILE EXISTS (SELECT *
                    FROM StandardDatasetAggregationStorage
                    WHERE (DatasetId = @DatasetId)
                      AND (AggregationTypeId = @AggregationTypeId)
                      AND (StandardDatasetAggregationStorageRowId > @StandardDatasetAggregationStorageRowId)
                  )
      BEGIN
        SELECT TOP 1
           @StandardDatasetAggregationStorageRowId = StandardDatasetAggregationStorageRowId
          ,@TableName = BaseTableName + '_' + @TableNameSuffix
        FROM StandardDatasetAggregationStorage
        WHERE (DatasetId = @DatasetId)
          AND (AggregationTypeId = @AggregationTypeId)
          AND (StandardDatasetAggregationStorageRowId > @StandardDatasetAggregationStorageRowId)
        ORDER BY DependentTableInd, StandardDatasetAggregationStorageRowId
        
        IF (@MainTableName IS NULL)
          SET @MainTableName = @TableName
          
        -- run through all registered indexes to see if they need reorg or rebuild
        SET @StandardDatasetAggregationStorageIndexRowId = -1
        
        WHILE EXISTS (SELECT *
                      FROM StandardDatasetAggregationStorageIndex
                      WHERE (StandardDatasetAggregationStorageRowId = @StandardDatasetAggregationStorageRowId)
                        AND (StandardDatasetAggregationStorageIndexRowId > @StandardDatasetAggregationStorageIndexRowId)
                     )
        BEGIN
          SELECT TOP 1
             @StandardDatasetAggregationStorageIndexRowId = StandardDatasetAggregationStorageIndexRowId
            ,@IndexName = 'IX_CUSTOM_' + REPLACE(CAST(IndexGuid AS varchar(100)), '-', '')
            ,@PrimaryKeyInd = PrimaryKeyInd
          FROM StandardDatasetAggregationStorageIndex
          WHERE (StandardDatasetAggregationStorageRowId = @StandardDatasetAggregationStorageRowId)
            AND (StandardDatasetAggregationStorageIndexRowId > @StandardDatasetAggregationStorageIndexRowId)
          ORDER BY StandardDatasetAggregationStorageIndexRowId
          
          SET @IndexId = NULL
          SET @TableNameWithSchema = QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName)
          
          IF (@PrimaryKeyInd = 1)
          BEGIN
            SET @IndexId = 1
          END
          ELSE
          BEGIN
            SELECT @IndexId = indid
            FROM sysindexes
            WHERE ([name] = @IndexName)
              AND (id = OBJECT_ID(@TableNameWithSchema))
          END
            
          IF (@IndexId IS NOT NULL)
          BEGIN
            SELECT @AvgFragmentationInPercent = avg_fragmentation_in_percent
            FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID(@TableNameWithSchema), @IndexId, NULL, NULL)
            WHERE (alloc_unit_type_desc = 'IN_ROW_DATA') -- exclude blobs
            
            IF (@AvgFragmentationInPercent >= @MinAvgFragmentationInPercentToOptimize)
            BEGIN
              -- check to see if we optimized this index
              -- within last 2 optimization intervals and
              -- it did not reduce fragmentation
              IF (NOT EXISTS (SELECT *
                              FROM StandardDatasetOptimizationHistory oh
                                    JOIN StandardDatasetTableMap m ON (oh.StandardDatasetTableMapRowId = m.StandardDatasetTableMapRowId)
                                    JOIN StandardDatasetAggregation a ON (m.DatasetId = a.DatasetId) AND (m.AggregationTypeId = a.AggregationTypeId)
                              WHERE (oh.StandardDatasetTableMapRowId = @StandardDatasetTableMapRowId)
                                AND (oh.StandardDatasetAggregationStorageIndexRowId = @StandardDatasetAggregationStorageIndexRowId)
                                AND (oh.OptimizationStartDateTime > DATEADD(minute, -2 * a.IndexOptimizationIntervalMinutes, GETUTCDATE()))
                                AND (oh.AfterAvgFragmentationInPercent >= oh.BeforeAvgFragmentationInPercent)
                                AND (oh.StandardDatasetOptimizationHistoryRowId = (SELECT TOP 1 StandardDatasetOptimizationHistoryRowId
                                                                                   FROM StandardDatasetOptimizationHistory
                                                                                   WHERE (StandardDatasetTableMapRowId = @StandardDatasetTableMapRowId)
                                                                                     AND (StandardDatasetAggregationStorageIndexRowId = @StandardDatasetAggregationStorageIndexRowId)
                                                                                     AND (OptimizationStartDateTime IS NOT NULL)
                                                                                   ORDER BY CreatedDateTime DESC
                                                                                  ))
                             )
                 )
              BEGIN
                SET @FoundNonoptimalIndexInd = 1
                BREAK
              END
            END
            
            -- check stats update date
            IF (STATS_DATE(OBJECT_ID(@TableNameWithSchema), @IndexId) IS NULL)
               OR
               (STATS_DATE(OBJECT_ID(@TableNameWithSchema), @IndexId) < DATEADD(hour, -@StatisticsMaxAgeHours, GETDATE()))
            BEGIN
              SET @FoundNonoptimalIndexInd = 1
              BREAK
            END
          END
        END
        
        IF (@FoundNonoptimalIndexInd = 1) BREAK
      END
      
      IF (@FoundNonoptimalIndexInd = 0) AND (@InsertInd = 0)
      BEGIN
        SET @Statement = 
          'UPDATE StandardDatasetTableMap'
        + ' SET OptimizedInd = 1'
        + '    ,StartDateTime = (SELECT MIN([DateTime]) FROM ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@MainTableName) + ' (TABLOCK))'
        + '    ,EndDateTime = (SELECT MAX([DateTime]) FROM ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@MainTableName) + ' (TABLOCK))'
        + ' WHERE (StandardDatasetTableMapRowId = ' + CAST (@StandardDatasetTableMapRowId AS varchar(15)) + ')'

        EXECUTE(@Statement)
        
        -- create check constraint on the table to 
        -- ensure optimizer can use it
        DECLARE
           @TableStartDateTime datetime
          ,@TableEndDateTime datetime
          
        SELECT
           @TableStartDateTime = StartDateTime
          ,@TableEndDateTime = EndDateTime
        FROM StandardDatasetTableMap
        WHERE (StandardDatasetTableMapRowId = @StandardDatasetTableMapRowId)
        
        SET @Statement = ' IF EXISTS (SELECT * FROM sys.check_constraints WHERE name = ''CHK_DateTime_' + @MainTableName + ''' AND parent_object_id = OBJECT_ID(''' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@MainTableName) + '''))'
                       + '  ALTER TABLE ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@MainTableName)
                       + '   DROP CONSTRAINT ' + QUOTENAME('CHK_DateTime_' + @MainTableName)
                       + '  ALTER TABLE ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@MainTableName) + ' WITH NOCHECK'
                       + '   ADD CONSTRAINT ' + QUOTENAME('CHK_DateTime_' + @MainTableName) + ' CHECK ([DateTime] BETWEEN ''' + CONVERT(varchar(100), @TableStartDateTime, 121) + '''' 
                       + '         AND ''' + CONVERT(varchar(100), @TableEndDateTime, 121) + ''')' 
        EXECUTE (@Statement)
        
        -- end date may be far in the future
        -- due to multiple reasons
        -- set table map date to "today" if
        -- it is far in the future, but leave 
        -- constraints "real"
        IF (@TableEndDateTime > DATEADD(month, 1, GETUTCDATE()))
        BEGIN
          UPDATE StandardDatasetTableMap
          SET EndDateTime = GETUTCDATE()
          WHERE (StandardDatasetTableMapRowId = @StandardDatasetTableMapRowId)
        END
      END
    END

    --********************************************************
    -- Optimize next index in queue
    
    SET @StandardDatasetOptimizationHistoryRowId = 0
    SET @IndexOptimized = 0
    
    WHILE EXISTS (SELECT *
                  FROM StandardDatasetOptimizationHistory h
                          JOIN StandardDatasetAggregationStorageIndex i ON (h.StandardDatasetAggregationStorageIndexRowId = i.StandardDatasetAggregationStorageIndexRowId)
                          JOIN StandardDatasetAggregationStorage s ON (s.StandardDatasetAggregationStorageRowId = i.StandardDatasetAggregationStorageRowId)
                          JOIN StandardDatasetTableMap m ON (s.DatasetId = m.DatasetId) AND (s.AggregationTypeId = m.AggregationTypeId)
                  WHERE (m.DatasetId = @DatasetId)
                    AND (h.StandardDatasetTableMapRowId = m.StandardDatasetTableMapRowId)
                    AND (h.OptimizationStartDateTime IS NULL)
                    AND (StandardDatasetOptimizationHistoryRowId > @StandardDatasetOptimizationHistoryRowId)
                 )
    BEGIN
      SELECT TOP 1
         @StandardDatasetOptimizationHistoryRowId = h.StandardDatasetOptimizationHistoryRowId
        ,@StandardDatasetAggregationStorageIndexRowId = h.StandardDatasetAggregationStorageIndexRowId
        ,@TableName = s.BaseTableName + '_' + m.TableNameSuffix
        ,@InsertInd = m.InsertInd
        ,@IndexName = 'IX_CUSTOM_' + REPLACE(CAST(i.IndexGuid AS varchar(100)), '-', '')
        ,@PrimaryKeyInd = i.PrimaryKeyInd
        ,@StatisticsMaxAgeHours = a.StatisticsMaxAgeHours
        ,@StatisticsUpdateSamplePercentage = a.StatisticsUpdateSamplePercentage
        ,@OnlineRebuildPossibleInd =
            CASE
              WHEN ISNULL(i.OnlineRebuildPossibleInd, 1) = 1 THEN 1
              WHEN DATEADD(day, 1, ISNULL(i.OnlineRebuildLastPerformedDateTime, '19000101')) < GETUTCDATE() THEN 1
              ELSE 0
            END
        ,@CanPerformBlockingOptimizationInd =
            CASE
              WHEN (DATEDIFF(minute, CONVERT(char(8), GETDATE(), 112) + ' ' + d.BlockingMaintenanceDailyStartTime, GETDATE()) < d.BlockingMaintenanceDurationMinutes)
                THEN 1
              ELSE 0
            END
      FROM StandardDatasetOptimizationHistory h
              JOIN StandardDatasetAggregationStorageIndex i ON (h.StandardDatasetAggregationStorageIndexRowId = i.StandardDatasetAggregationStorageIndexRowId)
              JOIN StandardDatasetAggregationStorage s ON (s.StandardDatasetAggregationStorageRowId = i.StandardDatasetAggregationStorageRowId)
              JOIN StandardDatasetTableMap m ON (s.DatasetId = m.DatasetId) AND (s.AggregationTypeId = m.AggregationTypeId)
              JOIN StandardDatasetAggregation a ON (s.DatasetId = a.DatasetId) AND (s.AggregationTypeId = a.AggregationTypeId)
              JOIN StandardDataset d ON (d.DatasetId = m.DatasetId)
      WHERE (m.DatasetId = @DatasetId)
        AND (h.StandardDatasetTableMapRowId = m.StandardDatasetTableMapRowId)
        AND (h.OptimizationStartDateTime IS NULL)
        AND (StandardDatasetOptimizationHistoryRowId > @StandardDatasetOptimizationHistoryRowId)
      ORDER BY h.CreatedDateTime

      SET @IndexId = NULL
      SET @TableNameWithSchema = QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName)
      
      IF (@PrimaryKeyInd = 1)
      BEGIN
        SELECT @IndexId = 1
        
        SELECT @IndexName = i.name
        FROM sys.indexes i
        WHERE (index_id = 1)
          AND (object_id = OBJECT_ID(@TableNameWithSchema))
      END 
      ELSE
      BEGIN
        SELECT @IndexId = indid
        FROM sysindexes
        WHERE ([name] = @IndexName)
          AND (id = OBJECT_ID(@TableNameWithSchema))
      END
        
      IF (@IndexId IS NOT NULL)
      BEGIN
        SELECT @AvgFragmentationInPercent = avg_fragmentation_in_percent
        FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID(@TableNameWithSchema), @IndexId, NULL, NULL)
        WHERE (alloc_unit_type_desc = 'IN_ROW_DATA') -- exclude blobs
      END

      SET @OptimizationStartDateTime = GETUTCDATE()
      
      IF ((@IndexId IS NULL) OR (@AvgFragmentationInPercent < @MinAvgFragmentationInPercentToOptimize))
      BEGIN
        -- don't optimize indexes with low fragmentation
        UPDATE StandardDatasetOptimizationHistory
        SET OptimizationStartDateTime = @OptimizationStartDateTime
           ,OptimizationDurationSeconds = 0
           ,BeforeAvgFragmentationInPercent = @AvgFragmentationInPercent
           ,AfterAvgFragmentationInPercent = @AvgFragmentationInPercent
           ,OptimizationMethod = CASE WHEN @IndexId IS NULL THEN 'index doesn''t exist' ELSE 'no optimization' END
        WHERE (StandardDatasetOptimizationHistoryRowId = @StandardDatasetOptimizationHistoryRowId)
      END
      ELSE
      BEGIN
        SET @Statement = 'ALTER INDEX ' + QUOTENAME(@IndexName) + ' ON ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName)
        SET @IndexRebuild = 1

        IF ((@AvgFragmentationInPercent > @MinAvgFragmentationInPercentToRebuild) OR (@InsertInd = 0))
        BEGIN
          SET @OnlineRebuildInd = 0
          
          -- try online rebuild if possible
          IF (@OnlineRebuildPossibleInd = 1)
          BEGIN
            BEGIN TRY
              IF (@DebugLevel > 2)
              BEGIN
                SET @DebugMessage = 'Starting online optimization (rebuild) of table ' + @TableName + ' index ' + @IndexName
                
                EXEC DebugMessageInsert
                   @DatasetId = @DatasetId
                  ,@MessageLevel = 3
                  ,@MessageText = @DebugMessage
              END
              
              SET @OptimizationStartDateTime = GETUTCDATE()
              
              SET @EffectiveStatement = @Statement + ' REBUILD WITH (ONLINE=ON, FILLFACTOR=' + CASE @InsertInd WHEN 0 THEN '100' ELSE '80' END + ')'
              EXECUTE (@EffectiveStatement)
              
              SET @IndexOptimized = 1
              SET @OnlineRebuildInd = 1

              IF (@DebugLevel > 2)
              BEGIN
                SET @DebugMessage = 'Finished online optimization (rebuild) of table ' + @TableName + ' index ' + @IndexName
                SET @OperationDurationMs = ABS(DATEDIFF(ms, GETUTCDATE(), @OptimizationStartDateTime))
                
                EXEC DebugMessageInsert
                   @DatasetId = @DatasetId
                  ,@MessageLevel = 3
                  ,@MessageText = @DebugMessage
                  ,@OperationDurationMs = @OperationDurationMs
              END
            END TRY
            BEGIN CATCH
              SELECT 
                 @ErrorNumber = ERROR_NUMBER()
                ,@ErrorSeverity = ERROR_SEVERITY()
                ,@ErrorState = ERROR_STATE()
                ,@ErrorLine = ERROR_LINE()
                ,@ErrorProcedure = ISNULL(ERROR_PROCEDURE(), '-')
                ,@ErrorMessageText = ERROR_MESSAGE()

              IF (@DebugLevel > 2)
              BEGIN
                SET @DebugMessage = 'Online rebuild failed for table ' + @TableName + ' index ' + @IndexName
                                    + '. Error number ' + CAST(@ErrorNumber AS varchar(10))
                                    + ' Message: ' + @ErrorMessageText
                
                EXEC DebugMessageInsert
                   @DatasetId = @DatasetId
                  ,@MessageLevel = 3
                  ,@MessageText = @DebugMessage
              END
            END CATCH
            
            UPDATE StandardDatasetAggregationStorageIndex
            SET OnlineRebuildPossibleInd = @IndexOptimized
               ,OnlineRebuildLastPerformedDateTime = @OptimizationStartDateTime
            WHERE (StandardDatasetAggregationStorageIndexRowId = @StandardDatasetAggregationStorageIndexRowId)
          END
          
          -- when online rebuild fails, perform blocking rebuild or reorg
          IF (@IndexOptimized = 0)
          BEGIN
            IF (@CanPerformBlockingOptimizationInd = 1)
            BEGIN
              SET @EffectiveStatement = @Statement + ' REBUILD WITH (FILLFACTOR=' + CASE @InsertInd WHEN 0 THEN '100' ELSE '80' END + ')'
              SET @IndexRebuild = 1
            END
            ELSE
            BEGIN
              IF (@InsertInd = 1)
              BEGIN
                SET @EffectiveStatement = @Statement + ' REORGANIZE'
                SET @IndexRebuild = 0
              END
              ELSE
              BEGIN
                -- don't do "can't do rebuild - reorg instead" on a non-insert table
                -- to avoid endless fruitless reorgs
                SET @EffectiveStatement = NULL
              END
            END
          END
          ELSE
          BEGIN
            SET @EffectiveStatement = NULL
          END
        END
        ELSE
        BEGIN
          -- reorg
          SET @EffectiveStatement = @Statement + ' REORGANIZE'
          SET @IndexRebuild = 0
        END
        
        IF (@EffectiveStatement IS NOT NULL)
        BEGIN
          IF (@DebugLevel > 2)
          BEGIN
            SET @DebugMessage = 'Starting optimization of table ' + @TableName + ' index ' + @IndexName
            SET @DebugMessage = @DebugMessage + '. Method: index ' + CASE @IndexRebuild WHEN 0 THEN 'reorg' ELSE 'rebuild' END
            
            EXEC DebugMessageInsert
               @DatasetId = @DatasetId
              ,@MessageLevel = 3
              ,@MessageText = @DebugMessage
          END

          EXECUTE(@EffectiveStatement)
          SET @IndexOptimized = 1

          IF (@DebugLevel > 2)
          BEGIN
            SET @DebugMessage = 'Finished optimization of table ' + @TableName + ' index ' + @IndexName
            SET @OperationDurationMs = ABS(DATEDIFF(ms, GETUTCDATE(), @OptimizationStartDateTime))
            
            EXEC DebugMessageInsert
               @DatasetId = @DatasetId
              ,@MessageLevel = 3
              ,@MessageText = @DebugMessage
              ,@OperationDurationMs = @OperationDurationMs
          END
        END
      END
      
      IF (@IndexOptimized = 1)
      BEGIN
        SELECT @AfterAvgFragmentationInPercent = avg_fragmentation_in_percent
        FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID(@TableNameWithSchema), @IndexId, NULL, NULL)
        WHERE (alloc_unit_type_desc = 'IN_ROW_DATA') -- exclude blobs

        UPDATE StandardDatasetOptimizationHistory
        SET OptimizationStartDateTime = @OptimizationStartDateTime
           ,OptimizationDurationSeconds = ABS(DATEDIFF(second, @OptimizationStartDateTime, GETUTCDATE()))
           ,BeforeAvgFragmentationInPercent = @AvgFragmentationInPercent
           ,AfterAvgFragmentationInPercent = @AfterAvgFragmentationInPercent
           ,OptimizationMethod = CASE @IndexRebuild
                                   WHEN 1 THEN CASE @OnlineRebuildInd
                                                 WHEN 1 THEN 'online'
                                                 ELSE 'offline'
                                               END + ' rebuild'
                                   ELSE 'reorganize'
                                 END
        WHERE (StandardDatasetOptimizationHistoryRowId = @StandardDatasetOptimizationHistoryRowId)

        BREAK
      END

      -- check/update statistics on the index
      SET @StatisticUpdatedInd = 0
      
      IF (@IndexId IS NOT NULL)
      BEGIN
        -- check this index stats
        IF (STATS_DATE(OBJECT_ID(@TableNameWithSchema), @IndexId) < DATEADD(hour, -@StatisticsMaxAgeHours, GETDATE()))
           OR
           (STATS_DATE(OBJECT_ID(@TableNameWithSchema), @IndexId) IS NULL)
        BEGIN
          SET @Statement = 'UPDATE STATISTICS ' + @TableNameWithSchema + ' ' + QUOTENAME(@IndexName)
          SET @StatisticsUpdateMethod = 'update stats'
        
          IF (@StatisticsUpdateSamplePercentage > 0)
          BEGIN
            IF (@StatisticsUpdateSamplePercentage >= 100)
            BEGIN
              SET @Statement = @Statement + ' WITH FULLSCAN'
              SET @StatisticsUpdateMethod = @StatisticsUpdateMethod + ' fullscan'
            END
            ELSE
            BEGIN
              SET @Statement = @Statement + ' WITH SAMPLE ' + CAST(@StatisticsUpdateSamplePercentage AS varchar(10)) + ' PERCENT'
              SET @StatisticsUpdateMethod = @StatisticsUpdateMethod + ' sample ' + CAST(@StatisticsUpdateSamplePercentage AS varchar(10)) + '%'
            END
          END
          
          SET @StatisticsUpdateStartDateTime = GETUTCDATE()
          
          EXECUTE (@Statement)
          
          SET @StatisticsUpdateDurationSeconds = ABS(DATEDIFF(second, @StatisticsUpdateStartDateTime, GETUTCDATE()))
          
          -- do not consider quick stats updates
          IF (@StatisticsUpdateDurationSeconds > 0)
          BEGIN
            SET @StatisticUpdatedInd = 1
          END
          
          INSERT StandardDatasetOptimizationHistory (
             StandardDatasetTableMapRowId
            ,StandardDatasetAggregationStorageIndexRowId
            ,OptimizationStartDateTime
            ,OptimizationDurationSeconds
            ,BeforeAvgFragmentationInPercent
            ,AfterAvgFragmentationInPercent
            ,OptimizationMethod
          )
          SELECT
             StandardDatasetTableMapRowId
            ,StandardDatasetAggregationStorageIndexRowId
            ,@StatisticsUpdateStartDateTime
            ,@StatisticsUpdateDurationSeconds
            ,BeforeAvgFragmentationInPercent
            ,AfterAvgFragmentationInPercent
            ,@StatisticsUpdateMethod
          FROM StandardDatasetOptimizationHistory
          WHERE (StandardDatasetOptimizationHistoryRowId = @StandardDatasetOptimizationHistoryRowId)
        END
      END

      -- do only one lengthy operation      
      IF ((@IndexOptimized = 1) OR (@StatisticUpdatedInd = 1))
      BEGIN
        BREAK
      END
    END
    
    IF (@LockSetInd = 1)
    BEGIN
      EXEC @ExecResult = sp_releaseapplock
                 @Resource = @LockResourceName
                ,@LockOwner = 'Session'
                
      SET @LockSetInd = 0
    END
  END TRY
  BEGIN CATCH
    IF (@@TRANCOUNT > 0)
      ROLLBACK TRAN
  
    IF (@LockSetInd = 1)
    BEGIN
      EXEC @ExecResult = sp_releaseapplock
                 @Resource = @LockResourceName
                ,@LockOwner = 'Session'
    END

    SELECT 
       @ErrorNumber = ERROR_NUMBER()
      ,@ErrorSeverity = ERROR_SEVERITY()
      ,@ErrorState = ERROR_STATE()
      ,@ErrorLine = ERROR_LINE()
      ,@ErrorProcedure = ISNULL(ERROR_PROCEDURE(), '-')
      ,@ErrorMessageText = ERROR_MESSAGE()

    SET @ErrorInd = 1
  END CATCH

  -- report error if any
  IF (@ErrorInd = 1)
  BEGIN
    IF (@DebugLevel > 0)
    BEGIN
      DECLARE @DebugMessageText nvarchar(max)

      SET @DebugMessageText = N'Failed to optimize data for standard data set. Error ' + CAST(@ErrorNumber AS varchar(15))
                      + ', Procedure ' + @ErrorProcedure
                      + ', Line ' + CAST(@ErrorLine AS varchar(15))
                      + ', Message: '+ @ErrorMessageText
      EXEC DebugMessageInsert
         @DatasetId = @DatasetId
        ,@MessageLevel = 1
        ,@MessageText = @DebugMessageText
    END
      
    DECLARE @AdjustedErrorSeverity int

    SET @AdjustedErrorSeverity = CASE
                                   WHEN @ErrorSeverity > 18 THEN 18
                                   ELSE @ErrorSeverity
                                 END
    
    RAISERROR (777971002, @AdjustedErrorSeverity, 1
      ,@ErrorNumber
      ,@ErrorSeverity
      ,@ErrorState
      ,@ErrorProcedure
      ,@ErrorLine
      ,@ErrorMessageText
    )
  END
END
GO 
 

--    (c) Copyright 2005-2006, Microsoft Corporation, All Rights Reserved    --
--    Proprietary and confidential to Microsoft Corporation                  --
--                                                                           --
--    File: DatabaseMaintenanceSprocs.sql                                    --
--                                                                           --
--    Contents: This file contains the stored procedures that perform        --
--      database maintenance.                                                --
-------------------------------------------------------------------------------

--
-- Sproc Name: p_IncrementalPopulateDomainTable
-- Description: Incrementally populate the DomainTable table which contains the tables
-- that we will optimze indexes for. As new tables show up via MPs they will incrementally added
-- to the DomainTable table.
-- @TODO: What if an index has been added to an existing table.
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'p_IncrementalPopulateDomainTable')
    DROP PROCEDURE dbo.p_IncrementalPopulateDomainTable
GO

CREATE PROCEDURE dbo.p_IncrementalPopulateDomainTable
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @Err int
    DECLARE @DatasetId uniqueidentifier
    DECLARE @TableName nvarchar(256)

    SET @DatasetId = '94BE6DB6-EB7E-4C76-9BF5-7569DFE54F96'

WHILE (EXISTS (SELECT 1
                FROM sys.objects O
                JOIN sys.schemas S
                    ON O.schema_id = S.schema_id
                JOIN sys.indexes I
                    ON O.object_id = I.object_id
                WHERE O.type_desc = 'USER_TABLE'
                AND O.name NOT LIKE 'Event[_]__'
                AND O.name NOT LIKE 'PerformanceData[_]__'
                AND I.type_desc <> 'HEAP'
                AND I.name NOT IN (SELECT IndexName FROM DomainTableIndex DTI 
                                   JOIN DomainTable DT ON DTI.DomainTableRowId = DT.DomainTableRowId
                                   WHERE DT.TableName = QUOTENAME(S.name) + '.' + QUOTENAME(O.name))))
BEGIN
    SELECT TOP 1 @TableName = QUOTENAME(S.name) + '.' + QUOTENAME(O.name)
                FROM sys.objects O
                JOIN sys.schemas S
                    ON O.schema_id = S.schema_id
                JOIN sys.indexes I
                    ON O.object_id = I.object_id
                WHERE O.type_desc = 'USER_TABLE'
                AND O.name NOT LIKE 'Event[_]__'
                AND O.name NOT LIKE 'PerformanceData[_]__'
                AND I.type_desc <> 'HEAP'
                AND I.name NOT IN (SELECT IndexName FROM DomainTableIndex DTI 
                                   JOIN DomainTable DT ON DTI.DomainTableRowId = DT.DomainTableRowId
                                   WHERE DT.TableName = QUOTENAME(S.name) + '.' + QUOTENAME(O.name)) 
                ORDER BY QUOTENAME(S.name) + '.' + QUOTENAME(O.name)

        EXEC @Err = DomainTableRegisterIndexOptimization @TableName = @TableName, @DatasetId = @DatasetId, @IncludeClusteredIndex = 1
        IF (@Err <> 0)
            GOTO Err
    END

    RETURN 0
Err:
    RETURN 1
END

GO

--
-- Sproc Name: p_OptimizeIndexes
-- Description: Reuses the index optimization stored proc written for the data warehouse. Simply
-- calls into this sproc with the correct parameters.
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'p_OptimizeIndexes')
    DROP PROCEDURE dbo.p_OptimizeIndexes
GO

CREATE PROCEDURE dbo.p_OptimizeIndexes
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @Err int
    DECLARE @DatasetId uniqueidentifier

    -- If there were any nex indexes defined on existing tables or on new tables add them
    -- to the DomainTable and DomanTableIndex tables.
    EXEC @Err = dbo.p_IncrementalPopulateDomainTable
    IF (@Err <> 0)
        GOTO Err

    SET @DatasetId = '94BE6DB6-EB7E-4C76-9BF5-7569DFE54F96'
    
    EXEC @Err = DomainTableIndexOptimize
       @DatasetId                               = @DatasetId
      ,@MinAvgFragmentationInPercentToOptimize  = 30
      ,@TargetFillfactor                        = 80
      ,@BlockingMaintenanceStartTime            = '00:00'
      ,@BlockingMaintenanceDurationMinutes      = 1440
      ,@StatisticsUpdateMaxDurationSeconds      = 900 -- 5 * 60 (Normally it takes less than a minute to complete)
      ,@StatisticsUpdateMaxStatAgeHours         = 0   -- Since we run this sproc only once a day, we want to make sure that auto stat updates don't prevent us from updating stats with FULL scan.
      ,@StatisticsSamplePercentage              = 100 -- Update stats with FULL scan.
      ,@MinAvgFragmentationInPercentToReorg     = 15
      ,@NumberOfIndexesToOptimize               = 0

    IF (@Err <> 0)
        GOTO Err

    RETURN 0
Err:
    RETURN 1
END

GO

--
-- Sproc Name: p_UpdateStatistics
-- Description: Simply forwards the call to sp_updatestats.
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'p_UpdateStatistics')
    DROP PROCEDURE dbo.p_UpdateStatistics
GO

CREATE PROCEDURE dbo.p_UpdateStatistics
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @Err int

    EXEC @Err = sp_updatestats
    IF (@Err <> 0)
        GOTO Err

    RETURN 0
Err:
    RETURN 1
END

GO

---------------------------------------------------------------------------------
--  (c) Copyright 2004-2006 Microsoft Corporation, All Rights Reserved         --
--  Proprietary and confidential to Microsoft Corporation                      --
--                                                                             --
--  File:      SecuritySprocs.sql                                              --
--                                                                             --
--  Contents: Sprocs to create logins, grant permission to db, etc             --
---------------------------------------------------------------------------------

--
-- Sproc Name: p_SetupCreateLogin
-- Description: Creates a SQL login in the server, grants it access to the database
--              and adds it to the given role.
-- Caller: Setup
--         This sproc will be called by setup after the setup script runs.
--
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'p_SetupCreateLogin' AND ROUTINE_TYPE = 'PROCEDURE')
    DROP PROCEDURE dbo.p_SetupCreateLogin
GO

CREATE PROCEDURE dbo.p_SetupCreateLogin
(
    @LoginName sysname,
    @RoleName sysname
)
AS
BEGIN

    DECLARE @Sid varbinary(85)
    DECLARE @UserName sysname
    DECLARE @Err int
    DECLARE @Qry NVARCHAR(4000)

    SET NOCOUNT ON  

    -- Verifying if Login already has access to the server
    IF NOT EXISTS (SELECT * FROM master..syslogins WHERE UPPER(RTRIM(LTRIM([name]))) = UPPER(RTRIM(LTRIM(@LoginName))))
    BEGIN
		SELECT @Qry = 'CREATE LOGIN [' + @LoginName + '] FROM WINDOWS'

        -- Granting the login access to the server
        EXEC(@Qry)
        
        SET @Err = @@ERROR
 
        IF (@Err <> 0) 
        BEGIN
            GOTO Error_Exit
        END
    END

    -- Select the sid of the login. Querying for the sid is the only
    -- way to be certain that the login doesn't already have permissions
    -- in the database.
    SELECT @Sid = sid FROM master..syslogins WHERE UPPER(RTRIM(LTRIM([loginname]))) = UPPER(RTRIM(LTRIM(@LoginName)))

    -- We must have a sid by now, otherwise it's an error.    
    IF (@Sid IS NULL) GOTO Error_Exit

    -- Verify if the sid already has access to the database
    SELECT @UserName = [name] FROM sysusers WHERE [sid] = @Sid 

    -- If the name is NULL, the login doesn't have permissions
    -- in the DB yet, so we must add it.
    IF (@UserName IS NULL)
    BEGIN
		SELECT @Qry = 'CREATE USER [' + @LoginName + '] FOR LOGIN [' + @LoginName + ']'

        -- Grant the login access to this database. 
        -- We are making the user name in the database match the login name.
        EXEC(@Qry)

        SET @Err = @@ERROR
 
        IF (@Err <> 0) 
        BEGIN
            GOTO Error_Exit
        END

        -- Update the user name in the DB with the login name, since
        -- that's the name we gave in sp_grantdbaccess. We will need to
        -- have the correct UserName when calling sp_addrolemember.
        SET @UserName = @LoginName
    END
    -- When the given login was the one that created the database, 
    -- SQL Server automatically gives it permission to the database and assigns
    -- user dbo to the login. 
    ELSE IF @UserName = 'dbo'
    BEGIN
        -- If the login is already the dbo, there's no point in assigning it
        -- to any other roles (actually, SQLServer won't let you). So we just
        -- leave the sproc, since the login already has more than enough
        -- permissions.
        GOTO Success_Exit
    END    

    -- Adding the user to the given role (that should have been created
    -- already at the time the script was run). We must use the user name
    -- (which might not necessarily be identical to the LoginName).
    EXEC sp_addrolemember @RoleName, @UserName

    SET @Err = @@ERROR
 
    IF (@Err <> 0) 
    BEGIN
        GOTO Error_Exit
    END

Success_Exit:

    RETURN 0

Error_Exit:

    RETURN 1

END
GO

--
-- Sproc Name: p_GrantAlterLogin
-- Description: Grants alter login permission to the given login
--
-- Caller: Setup
--         This sproc will be called by setup after the setup script runs.
--
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'p_GrantAlterLogin' AND ROUTINE_TYPE = 'PROCEDURE')
    DROP PROCEDURE dbo.p_GrantAlterLogin
GO

CREATE PROCEDURE dbo.p_GrantAlterLogin
(
    @LoginName sysname
)
AS
BEGIN

    DECLARE @Err int
    DECLARE @stmt nvarchar(4000)

    SET NOCOUNT ON  

    -- Form grant alter statement
    SELECT @stmt = 'EXEC master..sp_addsrvrolemember '
    SELECT @stmt = @stmt + QUOTENAME(@LoginName, ']') + ', ''securityadmin''; '
    EXEC (@stmt)

    SET @Err = @@ERROR
    IF (@Err <> 0) 
    BEGIN
       GOTO Error_Exit
    END        

Success_Exit:

    RETURN 0

Error_Exit:

    RETURN 1

END

GO

if object_id ( 'etl.AddSource', 'p' ) is not null 
    drop procedure etl.AddSource
go
create procedure etl.AddSource	
							  @SourceTypeName nvarchar(128),
							  @SourceGuid	  uniqueidentifier,
							  @SourceName	  nvarchar(512) 		
						  
/*
	Gets the list of all modules for a given Job. 

	Parameters: @Job it is name of the Job the possible values are user defined jobs
	
	Usage: 
	declare @SourceId int
	exec @SourceId  = etl.AddSource 'ServiceManager','e0f61ecb-d038-6115-9b39-282c5e769c07','IncidentMG'	
	select @SourceId 
	
*/
as
begin
set nocount on 
set xact_abort on

	declare @SourceID int = 0, @RowCount int = 0  

    begin tran
	if (select COUNT(*) from etl.SourceType (tablock) where SourceTypeName = @SourceTypeName) =0
	begin
                insert into etl.SourceType (SourceTypeId, SourceTypeName)
                select max(SourceTypeId) + 1, @SourceTypeName 
                from etl.SourceType 
		
		if (@@rowcount <> 1)
		begin
			raiserror ('Could not create entry for source type in etl metadata tables %s', 16,1,@SourceTypeName)
			return @SourceID
		end	

	end		
	
	if (select COUNT(*) from etl.Source (tablock) where SourceGuid = @SourceGuid) =0
	begin
		insert into etl.Source (SourceName, SourceGuid, SourceTypeId)
		select @SourceName, @SourceGuid, st.SourceTypeId
		from etl.SourceType st
		left join etl.Source s on s.SourceName = @SourceName and s.SourceTypeId = st.SourceTypeId
		where SourceTypeName = @SourceTypeName		
		    and s.SourceId is null
		
		select @RowCount = @@rowcount, @SourceID = SCOPE_IDENTITY()
		
		if (@RowCount  <> 1)
		begin
			raiserror ('Could not create entry for data source in etl metadata tables %s', 16,1,@SourceName)
			return @SourceID
		end	
	end	
    commit tran

	if (@SourceID = 0)
	begin 
		select @SourceID = s.SourceId		
		from etl.Source s 
			join etl.SourceType st on (s.SourceTypeId = st.SourceTypeId)
		where s.SourceGuid = @SourceGuid	
	end
	
	select @SourceID 
	
	return 0 

set xact_abort off
set nocount on
end

go

IF OBJECT_ID ( 'etl.ReCreatePartition', 'p' ) is not null 
    DROP PROCEDURE etl.ReCreatePartition
GO

CREATE PROCEDURE etl.ReCreatePartition
    @EntityGuid    UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON
    SET XACT_ABORT ON

    /*
    ************************************************************************************
    *
    *   Step 1: Update TablePartition entries for existing Partitions with new EntityId
    *   Step 2: Add Primary Keys for all existing Partitions
    *   Step 3: Add CHECK constraints to all existing Partitions
    *
        begin tran
        EXEC etl.ReCreatePartition
            @entityGuid = '9B50AA2C-6632-3B79-8B44-1D041E8D78FA'

        ComputerHostsLogicalDiskFact_2009_Sep
        rollback tran

        EXEC etl.RecreatePartition
            @entityGuid = '2ADB9DAF-D08A-5A7A-4CCB-488789CC8A8B'
    ************************************************************************************
    */
    DECLARE @errorNumber        INT,
            @errorSeverity      INT,
            @errorState         INT,
            @errorLine          INT,
            @errorProcedure     NVARCHAR(256),
            @errorMessage       NVARCHAR(MAX),
            @task               NVARCHAR(512)

    declare @RelationalEntityName nvarchar(512), @PartitionName nvarchar(512), 
            @WarehouseEntityId  int,  @colList varchar(max), 
            @NextMonthDate int, @MinDate int, @MaxDate int

    DECLARE @utcDate                DATETIME        = GETUTCDATE()

    DECLARE @dateKeyColumnName      NVARCHAR(512),
            @currentMonthId         TINYINT         = DATEPART(MONTH, @utcDate),
            @currentMonthDate       INT             = CONVERT(NVARCHAR(8), @utcDate, 112),
            @currentMinDate         INT             = 0,
            @currentMaxDate         INT             = 0,
            @currentPartitionName   NVARCHAR(512)   = '',
            @currentPartitionId     INT             = 0,
            @startTranCount         INT             = @@TRANCOUNT

    DECLARE @tempSQLScript          NVARCHAR(MAX)   = '',
            @minTemplate            NVARCHAR(MAX)   = '',
            @maxTemplate            NVARCHAR(MAX)   = '',
            @bothTemplate           NVARCHAR(MAX)   = '',
            @columnsList            NVARCHAR(MAX)   = ''

    SELECT  @NextMonthDate          = CONVERT(NVARCHAR(8), DATEADD(MONTH, 1, @utcDate), 112),
            @dateKeyColumnName      = ''

    SELECT      @RelationalEntityName   = WarehouseEntityName, 
                @PartitionName          = etl.PartitionName(WarehouseEntityName, DATEADD(MONTH, 1, @utcDate), null),
                @WarehouseEntityId      = WarehouseEntityId
    FROM        etl.WarehouseEntity e 
    INNER JOIN  etl.WarehouseEntityType t ON
                e.WarehouseEntityTypeId = t.WarehouseEntityTypeId
    WHERE       e.EntityGuid = @EntityGuid
            AND t.WarehouseEntityTypeName = 'Fact'

    SELECT @task = 'Input validation'
    IF (@RelationalEntityName IS NULL)
    BEGIN
        RAISERROR('Invalid entity, cannot create a partition ', 16, 1)
        RETURN -1
    END

    BEGIN TRY
        BEGIN TRANSACTION
        SELECT @task = 'Initializing dateKeyColumnName.'
        SELECT  @dateKeyColumnName =    CASE
                                            WHEN wc.ColumnName = 'DateKey' OR wc.ColumnName = '[DateKey]' THEN 'DateKey'
                                            WHEN wc.ColumnName = 'WeekKey' OR wc.ColumnName = '[WeekKey]' THEN 'WeekKey'
                                            WHEN wc.ColumnName = 'MonthKey' OR wc.ColumnName = '[MonthKey]' THEN 'MonthKey'
                                            ELSE @dateKeyColumnName
                                        END
        FROM    etl.WarehouseColumn wc
        WHERE   EntityId = @WarehouseEntityId

        --
        -- Step 1: Update TablePartition entries for pre-existing Partitions
        --
        SELECT @task = 'Step 1: Update TablePartition entries for pre-existing Partitions'
        UPDATE tblPar SET
                EntityId = @WarehouseEntityId
        FROM    etl.TablePartition tblPar
        INNER JOIN  sys.tables existingPartitions ON
                    tblPar.PartitionName = existingPartitions.name
        LEFT JOIN   etl.WarehouseEntity whEntity ON
                    tblPar.EntityId = whEntity.WarehouseEntityId
        WHERE       tblPar.WarehouseEntityName = @RelationalEntityName
            AND     whEntity.WarehouseEntityId IS NULL -- Partition should not belong to other Entities

        SELECT  @tempSQLScript	= '',
                @minTemplate = 'ALTER TABLE %TABLENAME% ALTER COLUMN %COLUMNNAME% %COLUMNTYPE% NOT NULL'

        SELECT  @task           = 'Preparing alter table script iteratively'
        SELECT  @tempSQLScript  = @tempSQLScript + CHAR(13) + REPLACE(REPLACE(REPLACE(@minTemplate, '%TABLENAME%', tblPar.PartitionName), '%COLUMNNAME%', whCols.ColumnName), '%COLUMNTYPE%', etl.GetColumnTypeDefinition(tblPar.PartitionName, REPLACE(REPLACE(whCols.ColumnName, '[', ''), ']', '')))
        FROM    etl.WarehouseColumn whCols
        INNER JOIN etl.TablePartition tblPar ON
				whCols.EntityId = tblPar.EntityId
		INNER JOIN sys.tables sysTbls ON
		        tblPar.PartitionName = sysTbls.name
		LEFT JOIN sys.columns sysCols ON
		        sysTbls.object_id = sysCols.object_id
		    and replace(replace(whCols.ColumnName, '[', ''), ']', '') = sysCols.name
		    and sysCols.is_nullable = 0
        WHERE   whCols.EntityId = @WarehouseEntityId
            AND whCols.Nullable = 0
            AND sysCols.name is null

        IF(@tempSQLScript <> '')
        BEGIN
            SELECT  @task = 'Executing NOT NULL script'
            SELECT @tempSQLScript
			PRINT @tempSQLScript
			EXEC (@tempSQLScript)
        END

        --
        -- Step 2: Add Primary Keys to all existing Partitions
        --
        SELECT @task = 'Step 2: Add Primary Keys to all existing Partitions'
        EXEC etl.CreatePrimaryKeyForPartition
            @WarehouseEntityId      = @WarehouseEntityId,
            @CurrentPartitionName   = NULL

        SELECT @task = 'Step 3: Add Foreign Keys to all existing Partitions'
        EXEC etl.CreateForeignKeyForPartition
            @WarehouseEntityId      = @WarehouseEntityId,
            @CurrentPartitionName   = NULL

        --
        -- Step 3: Add Check Constraints to existing Partitions
        --
        SELECT @task = 'Step 3: Add Check Constraints to existing Partitions'
        SELECT @minTemplate = 'ALTER TABLE %CURRENTPARTITIONNAME% WITH CHECK ADD CONSTRAINT %CONSTRAINTNAME% CHECK (%DATEKEYCOLUMNNAME% >= %CURRENTMINDATE%)'
        SELECT @maxTemplate = 'ALTER TABLE %CURRENTPARTITIONNAME% WITH CHECK ADD CONSTRAINT %CONSTRAINTNAME% CHECK (%DATEKEYCOLUMNNAME% <= %CURRENTMAXDATE%)'
        SELECT @bothTemplate = 'ALTER TABLE %CURRENTPARTITIONNAME% WITH CHECK ADD CONSTRAINT %CONSTRAINTNAME% CHECK ((%DATEKEYCOLUMNNAME% >= %CURRENTMINDATE%) AND (%DATEKEYCOLUMNNAME% <= %CURRENTMAXDATE%))'
        SELECT @tempSQLScript = ''

        SELECT @task = 'Step 3.1: Preparing Check Constraint script'
        SELECT      @tempSQLScript = @tempSQLScript + CHAR(13) +
                    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                        CASE
                            WHEN tblPar.RangeStartDate IS NOT NULL AND tblPar.RangeEndDate IS NULL THEN @minTemplate
                            WHEN tblPar.RangeStartDate IS NULL AND tblPar.RangeEndDate IS NOT NULL THEN @maxTemplate
                            WHEN tblPar.RangeStartDate IS NOT NULL AND tblPar.RangeEndDate IS NOT NULL THEN @bothTemplate
                            ELSE ''
                        END,
                        '%CURRENTPARTITIONNAME%', tblPar.PartitionName),
                        '%CONSTRAINTNAME%', etl.NormalizeNameForLength(tblPar.PartitionName + '_Chk', 128)),
                        '%DATEKEYCOLUMNNAME%', sysCol.Name),
                        '%CURRENTMINDATE%', ISNULL(tblPar.RangeStartDate, 0)),
                        '%CURRENTMAXDATE%', ISNULL(tblPar.RangeEndDate, 0))
        FROM        etl.TablePartition tblPar
        INNER JOIN  etl.WarehouseColumn etlCol ON (tblPar.EntityId = etlCol.EntityId)
        INNER JOIN  sys.tables sysTbls ON
                    tblPar.PartitionName = sysTbls.name
        LEFT JOIN   sys.check_constraints checkCnst ON
                    sysTbls.object_id = checkCnst.parent_object_id
                AND checkCnst.Name = etl.NormalizeNameForLength(tblPar.PartitionName + '_Chk', 128)
        INNER JOIN  sys.columns sysCol ON (sysTbls.object_id = sysCol.object_id AND REPLACE(REPLACE(etlCol.ColumnName, '[', ''), ']', '') = sysCol.name)
        WHERE       tblPar.EntityId = @WarehouseEntityId
                AND checkCnst.name IS NULL
                    -- we only support partitioning on these three columns. hourly grain facts are required to have DateKey column
                AND etlCol.ColumnName IN ('DateKey', 'WeekKey', 'MonthKey', '[DateKey]', '[WeekKey]', '[MonthKey]')

        IF(@tempSQLScript <> '')
        BEGIN
            SELECT @task = 'Step 3.2: Executing Check Constraint script'
            PRINT @tempSQLScript
            EXEC(@tempSQLScript)
        END

        SELECT @task = 'Updating the View by invoking etl.CreateView procedure.'
        EXEC etl.CreateView @EntityGuid, 'Fact'

        SELECT @task = 'Committing Transaction and returning.'
        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        IF(@@TRANCOUNT > @startTranCount) ROLLBACK TRANSACTION
        DECLARE @errorFmt       VARCHAR(256)

        SELECT  @errorFmt       = N'ErrorNumber="%d" Message="%s" Severity="%d" State="%d" ProcedureName="%s" LineNumber="%d" Task="%s"',
                @errorNumber    = ERROR_NUMBER(),
                @errorMessage   = ERROR_MESSAGE(),
                @errorSeverity  = ERROR_SEVERITY(),
                @errorState     = ERROR_STATE(),
                @errorLine      = ERROR_LINE(),
                @errorProcedure = ERROR_PROCEDURE()

        RAISERROR (
            @errorFmt,
            18,
            @errorState,
            @errorNumber,
            @errorMessage,
            @errorSeverity,
            @errorState,
            @errorProcedure,
            @errorLine,
            @task
        )

        RETURN -1
    END CATCH

    SET XACT_ABORT OFF    
    SET NOCOUNT OFF
    RETURN 0
END    
GO

if object_id ( 'etl.AddPartitionEntry', 'p' ) is not null 
    drop procedure etl.AddPartitionEntry
go
create procedure etl.AddPartitionEntry
                                @EntityGuid    uniqueIdentifier,
                                @utcDate datetime = null,
                                @caller varchar(32) = 'Deployer'
                                
/*
    Creates a partition for entities.    
    
    Note that only facts will have multiple partitions.  Dimensions and outriggers will only have a single partition.
    
    Parameters: @EntityGuid is guid of the fact that needs partition created.
    
    sp_help ComputerHostsPhysicalDiskFact_2009_May
    select * from etl.WarehouseEntity
    select * from etl.TablePartition
    delete etl.TablePartition where partitionid = 28
    Usage: exec etl.AddPartitionEntry '2ADB9DAF-D08A-5A7A-4CCB-488789CC8A8B'

    exec etl.UninstallPartition '2ADB9DAF-D08A-5A7A-4CCB-488789CC8A8B'

    exec etl.AddPartitionEntry '2ADB9DAF-D08A-5A7A-4CCB-488789CC8A8B', default, default
    declare @utcDate datetime = dateadd(month, 2, getutcdate())
    exec etl.AddPartitionEntry '2ADB9DAF-D08A-5A7A-4CCB-488789CC8A8B', @utcDate, default
    declare @utcDate datetime = dateadd(month, -2, getutcdate())
    exec etl.AddPartitionEntry '2ADB9DAF-D08A-5A7A-4CCB-488789CC8A8B', @utcDate, ''
*/
as
begin
    set nocount on
    set xact_abort on

    --Do not run this on DWCMDB
    if ((select COUNT(*) from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'TablePartition') = 0)
    begin
        return 0
    end

    declare @RelationalEntityName nvarchar(512), @PartitionName nvarchar(512),
            @MonthId tinyint, @WarehouseEntityId  int,  @colList varchar(max),
            @Partitionsql nvarchar(max), @MonthDate int, @MinDate int, @MaxDate int, @WarehouseEntityType nvarchar(512)

    declare @currentUTC datetime = getutcdate()
    select @utcDate = isnull(@utcDate, @currentUTC)

    select @MonthId = DATEPART(month, @utcDate), @MonthDate = CONVERT(nvarchar(8),  @utcDate, 112)

    select @RelationalEntityName = WarehouseEntityName, @WarehouseEntityId = WarehouseEntityId, @WarehouseEntityType = t.WarehouseEntityTypeName
    from etl.WarehouseEntity e
        join etl.WarehouseEntityType t on (e.WarehouseEntityTypeId = t.WarehouseEntityTypeId)
    where e.EntityGuid = @EntityGuid

    if(@WarehouseEntityType <> 'Fact')
    begin
        begin transaction
        insert into etl.TablePartition(PartitionName, EntityId,RangeStartDate, RangeEndDate,CreatedDate, WarehouseEntityName, InsertedBatchId, UpdatedBatchId)
        select @RelationalEntityName, @WarehouseEntityId, NULL, NULL, GETUTCDATE(), @RelationalEntityName, 0, 0
        where not exists(select PartitionName from etl.TablePartition where PartitionName = @RelationalEntityName)				
        commit transaction
        return 0
        set nocount off
    end
    else
    begin
        select @PartitionName = etl.PartitionName (@RelationalEntityName, @utcDate, null)
    end

    declare @PKCount int = 0
    select @PKCount = count(distinct sysPKs.parent_object_id)
    from sys.key_constraints sysPKs
    inner join etl.TablePartition tblPar on
                sysPKs.parent_object_id = OBJECT_ID(tblPar.PartitionName)
    where tblPar.EntityId = @WarehouseEntityId

    if(@MonthDate < CONVERT(nvarchar(8),  @currentUTC, 112))
    begin
        raiserror('Invalid date specified, Period cannot be older than the current Month.',16,1)
        return -1
    end

    if (@RelationalEntityName is null)
    begin
        raiserror('Invalid Fact table, Fact entry does not exist in system tables',16,1)
        return -1
    end

    --
    -- Deployer should've created the Partition before calling this procedure
    --
    if ((select COUNT(*) from INFORMATION_SCHEMA.TABLES where TABLE_NAME = @PartitionName) <> 1)
    begin
        -- HACKHACK
        -- Resolution to bug: 226520
        -- Try using a partition name for which there is a matching physical table
        -- If there is a tablepartition entry for this entity, use that partition name instead.
        set @PartitionName = null
        select @PartitionName = (select top 1 name from sys.tables t where name like @RelationalEntityName + '[_]%' and name not like '%bulkstg' order by create_date desc)
        select @PartitionName = ISNULL((select top 1 PartitionName from etl.TablePartition where EntityId = @WarehouseEntityId order by PartitionId desc), @PartitionName)

        if(@PartitionName is null)
        begin
            raiserror('Partition %s is not created, cannot add an entry for it',16,1, @PartitionName)
            return -1
        end
    end

    if(@caller = 'Deployer' and @PKCount <> 1 and exists (select 'x' from etl.TablePartition where EntityId = @WarehouseEntityId))
    begin
        raiserror('Zeor or more than one Partition with Primary Key exists. During MP Deployment, only one Partition for the WarehouseEntity is allowed to have Primary Key defined.',16,1)
        return -1
    end

    declare @previousPartitionId int = 0
    select @previousPartitionId = max(PartitionId)
    from etl.TablePartition
    where EntityId = @WarehouseEntityId
        and PartitionName <> @PartitionName

    begin transaction
    if(@previousPartitionId <> 0 and (select RangeEndDate from etl.TablePartition where PartitionId = @previousPartitionId) is null)
    begin
        select @MaxDate = max(DateKey)
        from dbo.DateDim d
        where d.MonthNumber = datepart(month, @utcDate)
            and d.YearNumber = datename(yy, @utcDate)
            
        update etl.TablePartition set
            RangeEndDate = @MaxDate
        where PartitionId = @previousPartitionId
    end

    select @MinDate = case when @previousPartitionId = 0 then null else min(d.DateKey) end, @MaxDate = null
    from dbo.DateDim d
    where d.DateKey > (select RangeEndDate from etl.TablePartition where PartitionId = @previousPartitionId)

    insert into etl.TablePartition(PartitionName, EntityId,RangeStartDate, RangeEndDate,CreatedDate, WarehouseEntityName, InsertedBatchId, UpdatedBatchId)
    select @PartitionName, @WarehouseEntityId, @MinDate, @MaxDate, GETUTCDATE(), @RelationalEntityName, 0, 0
    where not exists(select PartitionName from etl.TablePartition where PartitionName = @PartitionName)

    --
    -- AddPartitionEntry is presently only called for the first time
    -- the Entity is installed OR re-installed
    -- If the call is being made for a re-install then make sure to re-include all the
    -- pre-existing partitions
    --
    EXEC etl.ReCreatePartition @EntityGuid = @EntityGuid

    exec etl.CreateView @EntityGuid, 'Fact'
    commit transaction

    return 0
    set nocount off
end    
go

if object_id ( 'etl.UpdateEntitySchema', 'p' ) is not null 
    drop procedure etl.UpdateEntitySchema
go
create procedure etl.UpdateEntitySchema							  
										@EntitySchemaXml xml											
/*
	Gets the list of all modules for a given Job. 

	Parameters: @Job it is name of the Job the possible values are user defined jobs
	
	Usage: etl.UpdateEntitySchema 	
		'<EntitySchema>
			<RelationalEntity>
				<EntityName>MTV_Computer</EntityName>
				<EntityType>Inbound</EntityType>
				<EntityGuid>f0f61ecb-d038-6115-9b39-282c5e769c09</EntityGuid>
			</RelationalEntity>
			<Schema>
				<Columns>
					<Column>
						<ColumnName></ColumnName>
						<DataType></DataType>
						<ColumnLength></ColumnLength>
						<Nullable></Nullable>
						<IsIdentity></IsIdentity>
						<ReferenceEntityName></ReferenceEntityName>
						<ReferenceEntityGuid></ReferenceEntityGuid>
						<ReferenceEntityType></ReferenceEntityType>
						<ReferenceColumnName></ReferenceColumnName>
					</Column>
					<Column>
						<ColumnName></ColumnName>
						<DataType></DataType>
						<ColumnLength></ColumnLength>
						<Nullable></Nullable>
						<IsIdentity></IsIdentity>
						<ReferenceEntityName></ReferenceEntityName>
						<ReferenceEntityGuid></ReferenceEntityGuid>
						<ReferenceEntityType></ReferenceEntityType>
						<ReferenceColumnName></ReferenceColumnName>											
					</Column>
				</Columns>
			</Schema>
		</EntitySchema>'
	
*/
as
begin
set nocount on 
	
	 declare @RelationalEntityName nvarchar(512), @EntityGuid	uniqueIdentifier,
			 @WarehouseEntityType  nvarchar(128), @WarehouseEntityId int  
	
	select  @RelationalEntityName = p.value('(/EntitySchema/RelationalEntity/EntityName/text())[1]', 'nvarchar(512)'),
			@WarehouseEntityType = p.value('(/EntitySchema/RelationalEntity/EntityType/text())[1]', 'nvarchar(128)'),
			@EntityGuid = p.value('(/EntitySchema/RelationalEntity/EntityGuid/text())[1]', 'uniqueIdentifier')			
	from @EntitySchemaXml.nodes('/EntitySchema/RelationalEntity') N(p)
		
	select 
		N.P.value('ColumnName[1]', 'nvarchar(255)') as ColumnName,
		N.P.value('DataType[1]', 'nvarchar(128)') as DataType,
	    N.P.value('ColumnLength[1]', 'int') as ColumnLength, 
	    N.P.value('Nullable[1]', 'int') as Nullable,	   
	    N.P.value('IsIdentity[1]', 'int') as IsIdentity, 
	    N.P.value('ReferenceEntityName[1]', 'nvarchar(512)') as ReferenceEntityName, 
	    N.P.value('ReferenceEntityGuid[1]', 'uniqueIdentifier') as ReferenceEntityGuid, 	    
	    N.P.value('ReferenceEntityType[1]', 'nvarchar(512)') as ReferenceEntityType, 
	    N.P.value('ReferenceColumnName[1]', 'nvarchar(512)') as ReferenceColumnName  into #columns
	from @EntitySchemaXml.nodes('/EntitySchema/Schema/Columns/Column') N(P)
		
	select @WarehouseEntityId = WarehouseEntityId
	from etl.WarehouseEntity e 
		join etl.WarehouseEntityType t on (e.WarehouseEntityTypeId = t.WarehouseEntityTypeId)
	where SourceId = 1 and WarehouseEntityName = @RelationalEntityName
		and EntityGuid = @EntityGuid and t.WarehouseEntityTypeName = @WarehouseEntityType	
	
		
	merge etl.WarehouseColumn AS target
    using (
		
			SELECT distinct @WarehouseEntityId as EntityId, C.ColumnName, 
				  C.DataType, C.ColumnLength
				, C.Nullable, C.IsIdentity, RE.WarehouseEntityId as ReferenceEntityId
				, REC.ColumnId as ReferenceColumnId			
			from #columns C 
					left join etl.WarehouseEntity RE on (C.ReferenceEntityName = RE.WarehouseEntityName)													
													and (C.ReferenceEntityGuid = RE.EntityGuid)
					left join etl.WarehouseEntityType ET on (RE.WarehouseEntityTypeId = ET.WarehouseEntityTypeId)
													and (C.ReferenceEntityType = ET.WarehouseEntityTypeName)
					left  join etl.WarehouseColumn REC on (REC.EntityId = RE.WarehouseEntityId)
										and (REC.ColumnName = C.ReferenceColumnName)	
			) as source 
			on (target.EntityId = source.EntityId)	and (target.ColumnName = source.ColumnName)
			
	when matched then 		
			update set 
				   DataType = source.DataType,
				   ColumnLength = source.ColumnLength,							   
				   Nullable = source.Nullable,
				   IsIdentity = source.IsIdentity,
				   ReferenceEntityId = source.ReferenceEntityId,
				   ReferenceColumnId = source.ReferenceColumnId
		
	when not matched by target						
		then insert (EntityId, ColumnName, DataType, ColumnLength, Nullable,
					IsIdentity, ReferenceEntityId, ReferenceColumnId)
			values	(source.EntityId, source.ColumnName, source.DataType, source.ColumnLength, source.Nullable,
					source.IsIdentity, source.ReferenceEntityId, source.ReferenceColumnId)	
		
	when not matched by source and target.EntityId = @WarehouseEntityId
	then delete;
	
	if (@@error <> 0)
	begin
		raiserror ('Could not add relational entity  %s', 16,1,@RelationalEntityName)
		return -1
	end	
		
	return 0

set nocount on 
end

go

					
if object_id ( 'etl.AddRelationalEntity', 'p' ) is not null 
    drop procedure etl.AddRelationalEntity
go
create procedure etl.AddRelationalEntity							  
										@EntityXml xml,
										@EntitySchemaXml xml = null
/*
	Gets the list of all modules for a given Job. 

	Parameters: @Job it is name of the Job the possible values are user defined jobs
	
	Usage: etl.AddRelationalEntity 	
		'<RelationalEntity>
			<EntityName>MTV_Computer</EntityName>
			<EntityType>Inbound</EntityType>
			<EntityGuid>f0f61ecb-d038-6115-9b39-282c5e769c09</EntityGuid>
			<SourceName>IncidentMG</SourceName>
			<SourceGuid>e0f61ecb-d038-6115-9b39-282c5e769c07</SourceGuid>
			<SourceType>ServiceManager</SourceType>
		</RelationalEntity>'
	
*/
as
begin
set nocount on 
	
	 declare @RelationalEntityName nvarchar(512), @EntityGuid	uniqueIdentifier,
			 @WarehouseEntityType  nvarchar(128), @SourceName nvarchar(512),
			 @SourceType		   nvarchar(128), @SourceGuId uniqueIdentifier,
			 @SourceId			   int,      @WarehouseEntityTypeId int, @Exists int = 0 
	
	select  @RelationalEntityName = p.value('(/RelationalEntity/EntityName/text())[1]', 'nvarchar(512)'),
			@WarehouseEntityType = p.value('(/RelationalEntity/EntityType/text())[1]', 'nvarchar(128)'),
			@EntityGuid = p.value('(/RelationalEntity/EntityGuid/text())[1]', 'uniqueIdentifier'),
			@SourceName = p.value('(/RelationalEntity/SourceName/text())[1]', 'nvarchar(512)'),
			@SourceGuId = p.value('(/RelationalEntity/SourceGuid/text())[1]', 'uniqueIdentifier'),
			@SourceType = p.value('(/RelationalEntity/SourceType/text())[1]', 'nvarchar(128)')
	from @EntityXml.nodes('/RelationalEntity') N(p)
			
			
	select @SourceId = SourceId 
	from etl.Source s join etl.SourceType t on (t.SourceTypeId = s.SourceTypeId)
	where SourceGuid = @SourceGuId and SourceName = @SourceName and t.SourceTypeName = @SourceType
	
	select @WarehouseEntityTypeId = ET.WarehouseEntityTypeId
	from etl.WarehouseEntityType ET 
	where ET.WarehouseEntityTypeName = @WarehouseEntityType 
	
	
	/*Check for valid Job to create the batch for*/
	if (select count(*) from etl.WarehouseEntity
		 where EntityGuid = @EntityGuid and SourceId = @SourceId 
				and WarehouseEntityTypeId = @WarehouseEntityTypeId) != 0        
	begin /*working around the bug in deployment infra*/
		--raiserror ('WarehouseEntity with this name already exists %s', 1,1,@RelationalEntityName)
		--return -1
		if (@EntitySchemaXml is not null)
			exec etl.UpdateEntitySchema @EntitySchemaXml
			
  		--On Upgrade/Reinstall, we need to ensure that partition entry
  		--for non-facts are in the TablePartition table
  		--so cubes can process
  		if (@WarehouseEntityType <> 'Fact')
			exec etl.AddPartitionEntry @EntityGuid
				
		return 0 
	end		
		
	insert into etl.WarehouseEntity (WarehouseEntityName, EntityGuid,SourceId, WarehouseEntityTypeId)
	select @RelationalEntityName, @EntityGuid, @SourceId, @WarehouseEntityTypeId
	
	if (@@rowcount <> 1)
	begin
		raiserror ('Could not add relational entity  %s', 16,1,@RelationalEntityName)
		return -1
	end	
	
	--Insert metadata
	if (@EntitySchemaXml is not null)
			exec etl.UpdateEntitySchema @EntitySchemaXml
	
	exec etl.AddPartitionEntry @EntityGuid
		
	return 0

set nocount on 
end

go

if object_id ( 'etl.CreateView', 'p' ) is not null 
    drop procedure etl.CreateView
go
create procedure etl.CreateView							  
								@EntityGuid			   uniqueIdentifier,								
								@WarehouseEntityType   nvarchar(128)
/*
	Gets the list of all modules for a given Job. 

	Parameters: @Job it is name of the Job the possible values are user defined jobs
	
	Usage: etl.CreateView 	
		
*/
as
begin
set nocount on 
	
	declare @RelationalEntityName nvarchar(512), @ViewName  nvarchar(128), 
	@WarehouseEntityId int, @colList varchar(max), @viewsql nvarchar(max),
	@partitionlist varchar(max) 

	select @RelationalEntityName = WarehouseEntityName, 
			@ViewName = case when len(ViewName) < 128 then ViewName else etl.NormalizeNameForLength(ViewName, 126) + 'vw' end, @WarehouseEntityId = WarehouseEntityId 
	from etl.WarehouseEntity e 
		join etl.WarehouseEntityType t on (e.WarehouseEntityTypeId = t.WarehouseEntityTypeId)
	where e.EntityGuid = @EntityGuid and t.WarehouseEntityTypeName = @WarehouseEntityType


	if (@RelationalEntityName is null) 
	begin
		raiserror('Invalid entity, cannot create a view ',16,1)
		return -1
	end

	/*
	For Dimensions, we need to inner join with the information schema columns table because
	during the deployment of dim extensions (only generated by class extensions), it is 
	possible to have columns in the etl.warehousecolumn table which have not yet
	been added to the table schema and would fail when create view is called.  We need
	to parse out those columns
	*/
	 if (@WarehouseEntityType = 'Dimension')
		 begin
			 select @colList = (select distinct + CHAR(10) + CHAR(9) + '[' + c.COLUMN_NAME + ']' +  N',' AS [text()]
			 FROM etl.WarehouseColumn w inner join etl.WarehouseEntity e on (e.WarehouseEntityId = w.EntityId)
			 inner join INFORMATION_SCHEMA.COLUMNS c on (e.WarehouseEntityName = c.TABLE_NAME 
			 and  c.COLUMN_NAME = Replace(Replace(w.ColumnName, '[', ''), ']', ''))
			 where w.EntityId = @WarehouseEntityId and c.TABLE_NAME = @RelationalEntityName			 
			 for xml path(''))
		 end
	 else
		 begin
 			select @colList = (select distinct + CHAR(10) + CHAR(9) + ColumnName + N',' AS [text()]
			FROM etl.WarehouseColumn where EntityId = @WarehouseEntityId
			for xml path(''))
		 end

	if (@WarehouseEntityType = 'Fact')
		begin
			if not exists (select 1 from INFORMATION_SCHEMA.VIEWS where TABLE_NAME = @ViewName)
				set @viewsql = N'CREATE VIEW [dbo].['  + @ViewName +N']' + CHAR(10) + N' AS '+ CHAR(10) 
			else
				set @viewsql = N'ALTER VIEW [dbo].['  + @ViewName  +N']'+ CHAR(10) + N' AS ' + CHAR(10) 
			 
			select @colList = left(@colList, len(@colList)-1) 			
			
			select @partitionlist = 
					(	select  N' SELECT  ' + @colList + N' FROM ' + partitionname +  CHAR(10) + CHAR(9) + CHAR(10) + N' UNION ALL ' +  CHAR(10) + CHAR(9) + CHAR(10) as [text()]
						from etl.TablePartition tblPar
						inner join sys.tables sysTbls on (tblPar.PartitionName = sysTbls.name)
						where EntityId = @WarehouseEntityId 
						order by RangeStartDate
						for xml path('')
					)			
			
			select @viewsql = @viewsql + left(@partitionlist, len(@partitionlist)-13) + CHAR(10) 			
			
			exec (@viewsql)
		
			execute sp_refreshview @ViewName;
		end
	else
		begin
			if not exists (select 1 from INFORMATION_SCHEMA.VIEWS where TABLE_NAME = @ViewName)
				set @viewsql = N'CREATE VIEW [dbo].['  + @ViewName +N']' + CHAR(10) + N' AS '+ CHAR(10) + N' SELECT  '
			else
				set @viewsql = N'ALTER VIEW [dbo].['  + @ViewName  +N']'+ CHAR(10) + N' AS ' + CHAR(10) + N' SELECT  '
			 
			select @viewsql = @viewsql + left(@colList, len(@colList)-1) + CHAR(10) + N' from ' + CHAR(9) + N' dbo.[' + @RelationalEntityName + N']'
			
			exec (@viewsql)
			
			execute sp_refreshview @ViewName;
		end 
	return 0

set nocount on 
end

go
IF EXISTS(SELECT 1 FROM sys.procedures WHERE name = 'CreatePrimaryKeyForPartition' AND schema_id = SCHEMA_ID('etl'))
BEGIN
    DROP PROCEDURE etl.CreatePrimaryKeyForPartition
END
GO

CREATE PROCEDURE etl.CreatePrimaryKeyForPartition (
    @WarehouseEntityId      INT,
    @CurrentPartitionName   NVARCHAR(512)   = NULL
    )
AS
BEGIN
    /*
    ***************************************************************************************************
    *   Step 1: Get the most recent partition name
    *   Step 2: Concat Primary Key Columns list
    *   Step 3: Prepare Primary Key Script
    *   Step 4: Execute Primary Key Script
    ***************************************************************************************************
    *
        EXEC etl.CreatePrimaryKeyForPartition
            @WarehouseEntityId = 21,
            @CurrentPartitionName = 'TestPartition'
    ***************************************************************************************************
    */

    SET NOCOUNT ON
    SET XACT_ABORT ON

    DECLARE @errorNumber                    INT,
            @errorSeverity                  INT,
            @errorState                     INT,
            @errorLine                      INT,
            @errorProcedure                 NVARCHAR(256),
            @errorMessage                   NVARCHAR(MAX),
            @task                           NVARCHAR(512)

    DECLARE @PKName                         NVARCHAR(512),
            @PKScript                       NVARCHAR(MAX),
            @PKScriptTemplate               NVARCHAR(MAX),
            @PKColumnsList                  NVARCHAR(MAX),
            @PartitionToCopyPropertiesFrom  NVARCHAR(512),
            @MaxPartitionId                 INT,
            @ClusterType					VARCHAR(32)

    BEGIN TRY
        SELECT  @task   = 'Input validation'
        IF(ISNULL(@WarehouseEntityId, 0) = 0)
        BEGIN
		    RAISERROR('Invalid Input supplied. WarehouseEntityId cannot be NULL or Zero.', 16, 1)
		    RETURN -1
        END

        SELECT  @task               = 'Init'
        SELECT  @PKName             = 'PK_' + @CurrentPartitionName,
                @PKScript           = '',
                @PKScriptTemplate   = 'ALTER TABLE %TABLENAME% WITH CHECK ADD CONSTRAINT %PKNAME% PRIMARY KEY %CLUSTERTYPE% (%PKCOLUMNS%)',
                @PKColumnsList      = '',
                @MaxPartitionId     = ISNULL((SELECT MAX(PartitionId) FROM etl.TablePartition WHERE EntityId = @WarehouseEntityId AND PartitionName <> @CurrentPartitionName), 0),
                @ClusterType		= ''

        SELECT  @task = 'Getting PartitionName to copy from'
        SELECT  @PartitionToCopyPropertiesFrom = MAX(PartitionName)
        FROM etl.TablePartition tblPar
        inner join sys.key_constraints sysPK on
                OBJECT_ID(tblPar.PartitionName) = sysPK.parent_object_id
        WHERE EntityId = @WarehouseEntityId
            and sysPK.type = 'PK'

        PRINT   @PartitionToCopyPropertiesFrom
        if(@PartitionToCopyPropertiesFrom = '')
        begin
            RAISERROR('There are no Partitions with Primary Key defined. Key cannot be copied.', 16, 1)
            RETURN -1
        end

        SELECT      @task                           = 'Preparing PKColumnsList'
        SELECT      @PKColumnsList = PKCols.name + ', ' + @PKColumnsList,
					@ClusterType = CASE WHEN PKIdx.type = 1 THEN 'CLUSTERED' WHEN PKIdx.type = 2 THEN 'NONCLUSTERED' END
        FROM        sys.key_constraints PK
        INNER JOIN  sys.indexes PKIdx ON PKIdx.name = PK.name
        INNER JOIN  sys.index_columns PKIdxCols ON PKIdx.object_id = PKIdxCols.object_id AND PKIdx.index_id = PKIdxCols.index_id
        INNER JOIN  sys.columns PKCols on PKIdxCols.object_id = PKCols.object_id AND PKIdxCols.column_id = PKCols.column_id
        WHERE       PK.parent_object_id = OBJECT_ID(@PartitionToCopyPropertiesFrom)
            AND     PK.type = 'PK'
        ORDER by    PKIdxCols.index_column_id DESC

        SELECT      @task           = 'Deleting trailing "," from PKColumnsList'
        SELECT      @PKColumnsList  = LEFT(@PKColumnsList, LEN( ISNULL(NULLIF( LTRIM(RTRIM(@PKColumnsList)), ''), ',')) - 1)
		
        IF(@PKColumnsList <> '')
        BEGIN
            SELECT  @task               = 'Preparing PKScriptTemplate'
            SELECT  @PKScriptTemplate   = REPLACE(@PKScriptTemplate, '%CLUSTERTYPE%', @ClusterType)
            SELECT  @PKScriptTemplate   = REPLACE(@PKScriptTemplate, '%PKCOLUMNS%', @PKColumnsList)

            PRINT @CurrentPartitionName

            SELECT      @PKScript = @PKScript + CHAR(13) + REPLACE( REPLACE(@PKScriptTemplate, '%TABLENAME%', tblPar.PartitionName), '%PKNAME%', etl.NormalizeNameForLength('PK_' + tblPar.PartitionName, 128))
            FROM        etl.TablePartition tblPar
		    INNER JOIN  sys.tables sysTbls ON
		                tblPar.PartitionName = sysTbls.name
            LEFT JOIN   sys.key_constraints PK ON
                        OBJECT_ID(tblPar.PartitionName) = PK.parent_object_id
            WHERE       tblPar.EntityId = @WarehouseEntityId
                    AND tblPar.PartitionName = ISNULL(@CurrentPartitionName, tblPar.PartitionName)
                    AND PK.parent_object_id IS NULL

            PRINT @PKScript
            EXEC (@PKScript)
        END

        RETURN 0;
     END TRY
    BEGIN CATCH
        DECLARE @errorFmt       VARCHAR(256)

        SELECT  @errorFmt       = N'ErrorNumber="%d" Message="%s" Severity="%d" State="%d" ProcedureName="%s" LineNumber="%d" Task="%s"',
                @errorNumber    = ERROR_NUMBER(),
                @errorMessage   = ERROR_MESSAGE(),
                @errorSeverity  = ERROR_SEVERITY(),
                @errorState     = ERROR_STATE(),
                @errorLine      = ERROR_LINE(),
                @errorProcedure = ERROR_PROCEDURE()

        RAISERROR (
            @errorFmt,
            18,
            @errorState,
            @errorNumber,
            @errorMessage,
            @errorSeverity,
            @errorState,
            @errorProcedure,
            @errorLine,
            @task
        )
        RETURN -1
    END CATCH
END
GO
IF EXISTS(SELECT 1 FROM sys.procedures WHERE name = 'CreateForeignKeyForPartition' AND schema_id = SCHEMA_ID('etl'))
BEGIN
    DROP PROCEDURE etl.CreateForeignKeyForPartition
END
GO

CREATE PROCEDURE etl.CreateForeignKeyForPartition (
    @WarehouseEntityId      INT,
    @CurrentPartitionName   NVARCHAR(512)   = NULL
    )
AS
BEGIN
    /*
    ***************************************************************************************************
    *   Step 1: Get the most recent partition name
    *   Step 2: Concat Foreign Key Column List
    *   Step 3: Prepare Foreign key Script
    *   Step 4: Execute Foreign Key Script
    ***************************************************************************************************
    *
        select * from etl.WarehouseEntity where WarehouseEntityId = 68
        drop table TestPartition
        select * into TestPartition from ComputerHostsLogicalDiskFact_2009_Sep where 1 = 2

        EXEC etl.CreateForeignKeyForPartition
            @WarehouseEntityId = 27,
            @CurrentPartitionName = 'TestPartition'
    ***************************************************************************************************
    */

    SET NOCOUNT ON
    SET XACT_ABORT ON

    DECLARE @errorNumber                    INT,
            @errorSeverity                  INT,
            @errorState                     INT,
            @errorLine                      INT,
            @errorProcedure                 NVARCHAR(256),
            @errorMessage                   NVARCHAR(MAX),
            @task                           NVARCHAR(512)

    DECLARE @FKName                         NVARCHAR(512),
            @FKScriptTemplate               NVARCHAR(MAX),
            @FKScript                       NVARCHAR(MAX),
            @PartitionToCopyPropertiesFrom  NVARCHAR(512),
            @MaxPartitionId                 INT

    BEGIN TRY
        SELECT  @task   = 'Input validation'
        IF(ISNULL(@WarehouseEntityId, 0) = 0)
        BEGIN
		    RAISERROR('Invalid Input supplied. WarehouseEntityId cannot be NULL or Zero.', 16, 1)
		    RETURN -1
        END

        SELECT  @task               = 'Init'
        SELECT  @FKScriptTemplate   = 'ALTER TABLE [%PARTITIONNAME%] WITH CHECK ADD CONSTRAINT [%FKNAME%] FOREIGN KEY (%FKCOLUMNSLIST%) REFERENCES [%TARGETTABLENAME%](%TARGETCOLUMNSLIST%)',
                @FKScript           = '',
                @MaxPartitionId     = ISNULL((SELECT MAX(PartitionId) FROM etl.TablePartition WHERE EntityId = @WarehouseEntityId AND PartitionName <> @CurrentPartitionName), 0)

        SELECT  @task                           = 'Getting PartitionName to copy from'
        SELECT  @PartitionToCopyPropertiesFrom  = ISNULL((SELECT PartitionName FROM etl.TablePartition WHERE PartitionId = @MaxPartitionId), '')

        SELECT  @PartitionToCopyPropertiesFrom = MAX(PartitionName)
        FROM etl.TablePartition tblPar
        inner join sys.foreign_keys sysFK on
                OBJECT_ID(tblPar.PartitionName) = sysFK.parent_object_id
        WHERE EntityId = @WarehouseEntityId

        PRINT   @PartitionToCopyPropertiesFrom
        if(@PartitionToCopyPropertiesFrom = '')
        begin
            RAISERROR('There are no Partitions with Foriegn Key defined. Key cannot be copied.', 16, 1)
            RETURN -1
        end

        SELECT  @task       = 'Preparing PKColumnsList'
        SELECT  @FKScript   = @FKScript + CHAR(13) + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@FKScriptTemplate, '%PARTITIONNAME%', tblPar.PartitionName), '%FKNAME%', etl.NormalizeNameForLength('FK_' + tblPar.PartitionName + '_' + fn.SourceFKColumnsList + '_' + OBJECT_NAME(FK.Referenced_Object_Id), 128)), '%FKCOLUMNSLIST%', fn.SourceFKColumnsList), '%TARGETTABLENAME%', OBJECT_NAME(FK.referenced_object_id)), '%TARGETCOLUMNSLIST%', fn.TargetFKColumnsList)
        FROM    sys.foreign_keys FK
        CROSS APPLY etl.ConcatForeignKeyColumns(FK.Name) fn
        CROSS JOIN etl.TablePartition tblPar
        LEFT JOIN sys.foreign_keys existingFK ON
                OBJECT_ID(tblPar.PartitionName) = existingFK.parent_object_id
        WHERE   FK.parent_object_id = OBJECT_ID(@PartitionToCopyPropertiesFrom)
            AND fn.SourceFKColumnsList <> ''
            AND tblPar.PartitionName = ISNULL(@CurrentPartitionName, tblPar.PartitionName)
            AND tblPar.EntityId = @WarehouseEntityId
            AND existingFK.name IS NULL

        IF(@FKScript <> '')
        BEGIN
            SELECT  @task = 'Executing FKScript'
            PRINT @FKScript
            EXEC (@FKScript)
        END

        RETURN 0;
     END TRY
    BEGIN CATCH
        DECLARE @errorFmt       VARCHAR(256)

        SELECT  @errorFmt       = N'ErrorNumber="%d" Message="%s" Severity="%d" State="%d" ProcedureName="%s" LineNumber="%d" Task="%s"',
                @errorNumber    = ERROR_NUMBER(),
                @errorMessage   = ERROR_MESSAGE(),
                @errorSeverity  = ERROR_SEVERITY(),
                @errorState     = ERROR_STATE(),
                @errorLine      = ERROR_LINE(),
                @errorProcedure = ERROR_PROCEDURE()

        RAISERROR (
            @errorFmt,
            18,
            @errorState,
            @errorNumber,
            @errorMessage,
            @errorSeverity,
            @errorState,
            @errorProcedure,
            @errorLine,
            @task
        )
        RETURN -1
    END CATCH
END
GO
IF EXISTS(SELECT 1 FROM sys.procedures WHERE name = 'CreateIndexesForPartition' AND schema_id = SCHEMA_ID('etl'))
BEGIN
    DROP PROCEDURE etl.CreateIndexesForPartition
END
GO

CREATE PROCEDURE etl.CreateIndexesForPartition (
    @WarehouseEntityId      INT,
    @CurrentPartitionName   NVARCHAR(512)   = NULL
    )
AS
BEGIN
    /*
    ***************************************************************************************************
    *   Step 1: Get the most recent partition name
    *   Step 2: Concat Foreign Key Column List
    *   Step 3: Prepare Foreign key Script
    *   Step 4: Execute Foreign Key Script
    ***************************************************************************************************
    *
        select * from etl.WarehouseEntity where WarehouseEntityId = 68
        drop table TestPartition
        select * into TestPartition from ComputerHostsLogicalDiskFact_2009_Sep where 1 = 2

        EXEC etl.CreateIndexesForPartition
            @WarehouseEntityId = 27,
            @CurrentPartitionName = 'TestPartition'
    ***************************************************************************************************
    */

    SET NOCOUNT ON
    SET XACT_ABORT ON

    DECLARE @errorNumber                    INT,
            @errorSeverity                  INT,
            @errorState                     INT,
            @errorLine                      INT,
            @errorProcedure                 NVARCHAR(256),
            @errorMessage                   NVARCHAR(MAX),
            @task                           NVARCHAR(512)

    DECLARE @IXName                         NVARCHAR(512),
            @IXScriptTemplate1              NVARCHAR(MAX),
            @IXScriptTemplate2              NVARCHAR(MAX),
            @IXScript                       NVARCHAR(MAX),
            @PartitionToCopyPropertiesFrom  NVARCHAR(512),
            @MinPartitionId                 INT

    BEGIN TRY
        SELECT  @task   = 'Input validation'
        IF(ISNULL(@WarehouseEntityId, 0) = 0)
        BEGIN
		    RAISERROR('Invalid Input supplied. WarehouseEntityId cannot be NULL or Zero.', 16, 1)
		    RETURN -1
        END

        SELECT  @task               = 'Init'
        SELECT  @IXScriptTemplate1  = 'IF NOT EXISTS(SELECT * FROM sys.indexes IX WHERE IX.name = ''%INDEXNAME%'') CREATE %CLUSTERTYPE% INDEX %INDEXNAME% ON [%PARTITIONNAME%](%COLUMNSLIST%)',
                @IXScriptTemplate2  = 'IF NOT EXISTS(SELECT * FROM sys.indexes IX WHERE IX.name = ''%INDEXNAME%'') CREATE %CLUSTERTYPE% INDEX %INDEXNAME% ON [%PARTITIONNAME%](%COLUMNSLIST%) INCLUDE(%INCLUDECOLUMNSLIST%)',
                @IXScript           = '',
                @MinPartitionId     = ISNULL((SELECT MIN(PartitionId) FROM etl.TablePartition WHERE EntityId = @WarehouseEntityId AND PartitionName <> @CurrentPartitionName), 0)

        SELECT  @task                           = 'Getting PartitionName to copy from'
        SELECT  @PartitionToCopyPropertiesFrom  = ISNULL((SELECT PartitionName FROM etl.TablePartition WHERE PartitionId = @MinPartitionId), '')

        PRINT   @PartitionToCopyPropertiesFrom
        IF NOT EXISTS(SELECT 'x' FROM sys.indexes WHERE object_id = OBJECT_ID(@PartitionToCopyPropertiesFrom) AND is_primary_key = 0 AND type_desc <> 'HEAP')
        BEGIN
            -- no indexes to copy
            RETURN 0;
        END

        SELECT  @task = 'Preparing IXColumnsList'
        SELECT  @IXScript = @IXScript + CHAR(13) + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CASE WHEN etl.ConcatIndexColumns(IX.name, 1) = '' THEN @IXScriptTemplate1 ELSE @IXScriptTemplate2 END,
                                                        '%INDEXNAME%', etl.NormalizeNameForLength(CASE WHEN IX.type_desc = 'CLUSTERED' THEN 'CI' ELSE 'NCI' END + CAST(IX.index_id AS VARCHAR(32)) + '_' + tblPar.PartitionName, 128)),
                                                        '%CLUSTERTYPE%', CASE WHEN IX.type = 1 THEN 'CLUSTERED' ELSE 'NONCLUSTERED' END),
                                                        '%PARTITIONNAME%', tblPar.PartitionName COLLATE Latin1_General_CI_AS_KS_WS),
                                                        '%COLUMNSLIST%', etl.ConcatIndexColumns(IX.name, 0)),
                                                        '%INCLUDECOLUMNSLIST%', etl.ConcatIndexColumns(IX.name, 1))
        FROM    sys.indexes IX
        CROSS JOIN etl.TablePartition tblPar
        WHERE   IX.object_id = OBJECT_ID(@PartitionToCopyPropertiesFrom)
	        AND IX.type IN (1, 2) -- clustered/nonclustered
	        AND IX.is_primary_key = 0
            AND tblPar.EntityId = @WarehouseEntityId
            AND tblPar.PartitionName = ISNULL(@CurrentPartitionName, tblPar.PartitionName)
            AND tblPar.PartitionName <> @PartitionToCopyPropertiesFrom

        IF(@IXScript <> '')
        BEGIN
            SELECT  @task = 'Executing Index creation script'
            PRINT @IXScript
            EXEC (@IXScript)
        END

        RETURN 0;
     END TRY
    BEGIN CATCH
        DECLARE @errorFmt       VARCHAR(256)

        SELECT  @errorFmt       = N'ErrorNumber="%d" Message="%s" Severity="%d" State="%d" ProcedureName="%s" LineNumber="%d" Task="%s"',
                @errorNumber    = ERROR_NUMBER(),
                @errorMessage   = ERROR_MESSAGE(),
                @errorSeverity  = ERROR_SEVERITY(),
                @errorState     = ERROR_STATE(),
                @errorLine      = ERROR_LINE(),
                @errorProcedure = ERROR_PROCEDURE()

        RAISERROR (
            @errorFmt,
            18,
            @errorState,
            @errorNumber,
            @errorMessage,
            @errorSeverity,
            @errorState,
            @errorProcedure,
            @errorLine,
            @task
        )
        RETURN -1
    END CATCH
END
GO
IF OBJECT_ID ( 'etl.CreatePartition', 'p' ) is not null 
    DROP PROCEDURE etl.CreatePartition
GO

CREATE PROCEDURE etl.CreatePartition                              
    @EntityGuid    UNIQUEIDENTIFIER,
    @utcDate DATETIME = NULL
AS
BEGIN
    SET NOCOUNT ON
    SET XACT_ABORT ON

    /*
    ************************************************************************************
    *
    *   Step 1: Create new Partition
    *   Step 2: Create Primary KEYS
    *   Step 3: Create Foreign KEYS
    *   Step 4: Add a MaxDate Check constraint for the most recent older Partition
    *   Step 5: Add a MinDate Check constraint for the new Partition
    *   Step 6: Create/Update Partition View.
    *
        begin tran
        EXEC etl.CreatePartition
            @entityGuid = '9B50AA2C-6632-3B79-8B44-1D041E8D78FA'

        ComputerHostsLogicalDiskFact_2009_Sep
        rollback tran

        EXEC etl.CreatePartition
            @entityGuid = '2ADB9DAF-D08A-5A7A-4CCB-488789CC8A8B'

        declare @dt datetime = dateadd(month, 3, getutcdate())
        EXEC etl.CreatePartition
            @entityGuid = '2ADB9DAF-D08A-5A7A-4CCB-488789CC8A8B',
            @utcDate = @dt

        CREATE PROCEDURE etl.DropPartition
            @warehouseEntityId      INT,
            @warehouseEntityType    NVARCHAR(128),
            @entityGuid             UNIQUEIDENTIFIER,
            @partitionId            INT

        exec etl.DropPartition 34, 'fact', '2ADB9DAF-D08A-5A7A-4CCB-488789CC8A8B', 2010020102

        declare @dt datetime = dateadd(month, -10, getutcdate())
        EXEC etl.CreatePartition
            @entityGuid = '2ADB9DAF-D08A-5A7A-4CCB-488789CC8A8B',
            @utcDate = @dt

    ************************************************************************************
    */
    DECLARE @errorNumber        INT,
            @errorSeverity      INT,
            @errorState         INT,
            @errorLine          INT,
            @errorProcedure     NVARCHAR(256),
            @errorMessage       NVARCHAR(MAX),
            @task               NVARCHAR(512)

    declare @RelationalEntityName nvarchar(512), @PartitionName nvarchar(522), 
            @WarehouseEntityId  int,  @colList varchar(max), 
            @tempSQLScript nvarchar(max), @NextMonthDate int, @MinDate int, @MaxDate int

    SELECT @utcDate = ISNULL(@utcDate, GETUTCDATE())

    DECLARE @dateKeyColumnName      NVARCHAR(512),
            @currentMonthId         TINYINT         = DATEPART(MONTH, @utcDate),
            @currentMonthDate       INT             = CONVERT(NVARCHAR(8), @utcDate, 112),
            @currentMinDate         INT             = 0,
            @currentMaxDate         INT             = 0,
            @currentPartitionName   NVARCHAR(512)   = '',
            @currentPartitionId     INT             = 0,
            @startTranCount         INT             = @@TRANCOUNT,
            @temp                   NVARCHAR(128)   = '',
            @fileGroupName          SYSNAME

    SELECT  @NextMonthDate          = CONVERT(NVARCHAR(8), DATEADD(MONTH, 1, @utcDate), 112),
            @dateKeyColumnName      = ''

    SELECT      @RelationalEntityName   = WarehouseEntityName, 
                @PartitionName          = etl.PartitionName(WarehouseEntityName, DATEADD(MONTH, 1, @utcDate), 1),
                @WarehouseEntityId      = WarehouseEntityId,
                @fileGroupName          = etl.GetNextFileGroupName(e.WarehouseEntityId)
    FROM        etl.WarehouseEntity e
    INNER JOIN  etl.WarehouseEntityType t ON
                e.WarehouseEntityTypeId = t.WarehouseEntityTypeId
    WHERE       e.EntityGuid = @EntityGuid
            AND t.WarehouseEntityTypeName = 'Fact'

    SELECT @task = 'Input validation'
    IF (@RelationalEntityName IS NULL)
    BEGIN
        RAISERROR('Invalid entity, cannot create a partition ', 16, 1)
        RETURN -1
    END

    --
    -- Partition we need to create somehow already exists; return
    --
    SELECT @task = 'Checking if the Partition we want to create is already present.'
    IF      EXISTS (SELECT 1 FROM etl.TablePartition WHERE PartitionName = @PartitionName)
        OR  EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_NAME = @PartitionName)
    BEGIN
        RETURN 0;
    END

    BEGIN TRY
        BEGIN TRANSACTION
        SELECT @task = 'Initializing dateKeyColumnName.'
        SELECT  @dateKeyColumnName =    CASE
                                            WHEN wc.ColumnName = 'DateKey' OR wc.ColumnName = '[DateKey]' THEN 'DateKey'
                                            WHEN wc.ColumnName = 'WeekKey' OR wc.ColumnName = '[WeekKey]' THEN 'WeekKey'
                                            WHEN wc.ColumnName = 'MonthKey' OR wc.ColumnName = '[MonthKey]' THEN 'MonthKey'
                                            ELSE @dateKeyColumnName
                                        END
        FROM    etl.WarehouseColumn wc
        WHERE   EntityId = @WarehouseEntityId

        --
        -- Get Info about the most recent Partition, if present.
        --
        SELECT @task = 'Retrieving info about the most recent Partition, present.'
        SELECT TOP 1    @currentPartitionId = PartitionId,
                        @currentPartitionName = PartitionName,
                        @currentMinDate = RangeStartDate,
                        @currentMaxDate = RangeEndDate
        FROM            etl.TablePartition
        WHERE           EntityId = @WarehouseEntityId
        ORDER BY        PartitionId DESC

        --
        -- Calculate Min and Max dates for the new Partition we are about to create, using the logic:
        -- reg MaxDate: This will ALWAYS be NULL (implying there is no MaxDate constraint). This is done to catch a scenario where DWMaintenance job does not run for a few months
        -- reg MinDate: If the Partition we are about to create is the very first partition (ie, no other Partitions exist), then
        --              MinDate will be NULL (implying there is no MinDate Check constraint). This is done to catch a scenario where we may have to deal with historical data
        --              If, however, at least 1 partition already exists, then MinDate will be set to the 1st day of the next month
        --
        SELECT @task = 'Calculating MinDate and MaxDate values for the new Partition we are about to create.'
        SELECT    @MinDate = CASE WHEN @currentPartitionId = 0 THEN NULL ELSE MIN(d.DateKey) END,
                @MaxDate = NULL
        FROM    dbo.DateDim d
        WHERE   etl.MonthId(d.DateKey) = etl.MonthId(@NextMonthDate)

        SELECT @task = 'Adding record to the etl.TablePartition table.'
        INSERT INTO etl.TablePartition(PartitionName, EntityId,RangeStartDate, RangeEndDate,CreatedDate, WarehouseEntityName)
        SELECT @PartitionName, @WarehouseEntityId, @MinDate, @MaxDate, GETUTCDATE(), @RelationalEntityName
        WHERE NOT EXISTS (SELECT PartitionName from etl.TablePartition WHERE PartitionName = @PartitionName)

        SELECT @task = 'Preparing Column list from etl.WarehouseColumn table.'
        SELECT @colList = (SELECT DISTINCT 
                                        + CHAR(10) + CHAR(9) + ColumnName 
                                        + ' ' + DataType 
                                        + CASE  --Adding column length
                                            WHEN DataType IN ('nvarchar', 'nchar', 'varchar', 'char')
                                                 THEN '(' + cast(ColumnLength as NVARCHAR) + ') '
                                            WHEN DataType IN ('decimal')
                                                 THEN REPLACE(etl.GetColumnTypeDefinition(@currentPartitionName, ColumnName), DataType, '') + ' '
                                            ELSE ' '
                                          END
                                        + CASE Nullable WHEN 0 THEN 'NOT NULL' ELSE 'NULL' END
                                        + N',' AS [text()]
                            FROM etl.WarehouseColumn
                            WHERE EntityId = @WarehouseEntityId
                            FOR XML PATH(''))

        --
        -- Time to prepare script for creating a new Partition,
        -- Create table, CreatePrimaryKey, CreateForeignKey
        --
        SELECT @task = 'Preparing CREATE TABLE SQL script.'
        SELECT @tempSQLScript = N'IF NOT EXISTS(SELECT ''x'' FROM sys.tables WHERE name = ''' + @PartitionName + ''') CREATE TABLE [dbo].['  + @PartitionName + N']' + CHAR(10) + N' ( '+ CHAR(10) + LEFT(@colList, len(@colList)-1) + CHAR(10) + N' ) '
        SELECT @fileGroupName = etl.GetNextFileGroupName(@WarehouseEntityId)
        IF(@fileGroupName IS NOT NULL) SELECT @tempSQLScript = @tempSQLScript + ' ON ' + @fileGroupName + CHAR(10)

        SELECT @task = 'Executing CREATE TABLE SQL script.'
        PRINT @tempSQLScript
        EXEC (@tempSQLScript)
        SELECT @tempSQLScript = ''

        SELECT @task = 'Invoking etl.CreatePrimaryKeyForPartition procedure.'
        EXEC etl.CreatePrimaryKeyForPartition
            @WarehouseEntityId      = @WarehouseEntityId,
            @CurrentPartitionName   = @PartitionName

        SELECT @task = 'Invoking etl.CreateForeignKeyForPartition procedure.'
        EXEC etl.CreateForeignKeyForPartition
            @WarehouseEntityId      = @WarehouseEntityId,
            @CurrentPartitionName   = @PartitionName

        SELECT @task = 'Invoking etl.CreateIndexesForPartition procedure.'
        EXEC etl.CreateIndexesForPartition
            @WarehouseEntityId      = @WarehouseEntityId,
            @CurrentPartitionName   = @PartitionName

        --
        -- Now for CHECK CONSTRAINTS
        --
        -- If a partition already exists and there is no check constraint on the MaxDate,
        -- then make sure to add a constraint.
        -- This is done so because we are about to create a new partition to hold data
        -- where date > MaxDate or current partition
        --
        IF(@currentPartitionId <> 0 AND ISNULL(@currentMaxDate, 0) = 0)
        BEGIN
            SELECT @task = 'Calculating MaxDate value for the existing Partition.'
            SELECT    @currentMaxDate = MAX(d.DateKey)
            FROM    dbo.DateDim d
            WHERE   etl.MonthId(d.DateKey) = etl.MonthId(@currentMonthDate)

            SELECT @task = 'Updating etl.TablePartition table to set the RangeEndDate for the existing Partition.'
            UPDATE  tblPar SET
                    RangeEndDate = @currentMaxDate
            FROM    etl.TablePartition AS tblPar
            WHERE   tblPar.PartitionId = @currentPartitionId

            -- if a constraint already exists on the datekeycolumn, we should drop it
            -- and recreate a new one with the correct constraints.
            -- This is necessary because, for SQL server to recognize a view as a Partition View,
            -- all the participating table columns should have only 1 constraint defined on them
            SELECT @task = 'Preparing ALTER TABLE SQL script to DROP any existing CHECK constraint on the DATEKEYCOLUMN of the Partition.'
            SELECT @temp = CC.name
            FROM sys.check_constraints (NOLOCK) CC
            JOIN sys.tables (NOLOCK) T ON (CC.parent_object_id = T.object_id)
            JOIN sys.columns (NOLOCK) C ON (T.object_id = C.object_id AND CC.parent_column_id = C.column_id)
            WHERE T.name = @currentPartitionName
            AND C.name = @dateKeyColumnName

            IF(ISNULL(@temp, '') <> '')
            BEGIN
                SELECT @tempSQLScript = 'ALTER TABLE %CURRENTPARTITIONNAME% DROP CONSTRAINT %CONSTRAINTNAME%'
                SELECT @tempSQLScript = REPLACE(@tempSQLScript, '%CURRENTPARTITIONNAME%', @currentPartitionName)
                SELECT @tempSQLScript = REPLACE(@tempSQLScript, '%CONSTRAINTNAME%', @temp)

                SELECT @task = 'Executing ALTER TABLE SQL script to DROP a CHECK constraint on DATEKEYCOLUMN.'
                PRINT @tempSQLScript
                EXEC(@tempSQLScript)
                SELECT @tempSQLScript = ''
            END

            SELECT @task = 'Preparing ALTER TABLE SQL script to ADD a CHECK constraint for the MaxDate value for the exiting Partition.'
            SELECT @tempSQLScript = 'ALTER TABLE %CURRENTPARTITIONNAME% WITH CHECK ADD CONSTRAINT %CONSTRAINTNAME% CHECK ((%DATEKEYCOLUMNNAME% >= %CURRENTMINDATE%) AND (%DATEKEYCOLUMNNAME% <= %CURRENTMAXDATE%))'

            -- If MinDate is null/0 we should not add a min constraint to leave the partition open ended on that side
            IF(ISNULL(@currentMinDate, 0) = 0)
            BEGIN
                SELECT @tempSQLScript = 'ALTER TABLE %CURRENTPARTITIONNAME% WITH CHECK ADD CONSTRAINT %CONSTRAINTNAME% CHECK (%DATEKEYCOLUMNNAME% <= %CURRENTMAXDATE%)'
            END

            SELECT @tempSQLScript = REPLACE(@tempSQLScript, '%CURRENTPARTITIONNAME%', @currentPartitionName)
            SELECT @tempSQLScript = REPLACE(@tempSQLScript, '%DATEKEYCOLUMNNAME%', @dateKeyColumnName)
            SELECT @tempSQLScript = REPLACE(@tempSQLScript, '%CURRENTMINDATE%', ISNULL(@currentMinDate, 0))
            SELECT @tempSQLScript = REPLACE(@tempSQLScript, '%CURRENTMAXDATE%', ISNULL(@currentMaxDate, 0))
            SELECT @tempSQLScript = REPLACE(@tempSQLScript, '%CONSTRAINTNAME%', etl.NormalizeNameForLength(@currentPartitionName + '_Chk', 128))

            SELECT @task = 'Executing ALTER TABLE SQL script to ADD a CHECK constraint for the MaxDate value for the exiting Partition.'
            PRINT @tempSQLScript
            EXEC(@tempSQLScript)
            SELECT @tempSQLScript = ''
        END

        --
        -- If there is already a partition then make sure to set a MinDate check constraint
        -- for the new Parition that is being added
        --
        IF(@currentPartitionId <> 0)
        BEGIN
            SELECT @task = 'Preparing ALTER TABLE SQL script to ADD a CHECK constraint for the MinDate value for the new Partition.'
            SELECT @tempSQLScript = 'ALTER TABLE dbo.%PARTITIONNAME% WITH CHECK ADD CONSTRAINT %CONSTRAINTNAME% CHECK (%DATEKEYCOLUMNNAME% >= %MINDATE%)'
            SELECT @tempSQLScript = REPLACE(@tempSQLScript, '%PARTITIONNAME%', @PartitionName)
            SELECT @tempSQLScript = REPLACE(@tempSQLScript, '%DATEKEYCOLUMNNAME%', @dateKeyColumnName)
            SELECT @tempSQLScript = REPLACE(@tempSQLScript, '%MINDATE%', @MinDate)
            SELECT @tempSQLScript = REPLACE(@tempSQLScript, '%CONSTRAINTNAME%', etl.NormalizeNameForLength(@PartitionName + '_Chk', 128))

            SELECT @task = 'Executing ALTER TABLE SQL script to ADD a CHECK constraint for the MinDate value for the new Partition.'
            PRINT @tempSQLScript
            EXEC (@tempSQLScript);
            SELECT @tempSQLScript = ''
        END

        SELECT @task = 'Updating the View by invoking etl.CreateView procedure.'
        EXEC etl.CreateView @EntityGuid, 'Fact'

        SELECT @task = 'Committing Transaction and returning.'
        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        IF(@@TRANCOUNT > @startTranCount) ROLLBACK TRANSACTION
        DECLARE @errorFmt       VARCHAR(256)

        SELECT  @errorFmt       = N'ErrorNumber="%d" Message="%s" Severity="%d" State="%d" ProcedureName="%s" LineNumber="%d" Task="%s"',
                @errorNumber    = ERROR_NUMBER(),
                @errorMessage   = ERROR_MESSAGE(),
                @errorSeverity  = ERROR_SEVERITY(),
                @errorState     = ERROR_STATE(),
                @errorLine      = ERROR_LINE(),
                @errorProcedure = ERROR_PROCEDURE()

        RAISERROR (
            @errorFmt,
            18,
            @errorState,
            @errorNumber,
            @errorMessage,
            @errorSeverity,
            @errorState,
            @errorProcedure,
            @errorLine,
            @task
        )

        RETURN -1
    END CATCH

    SET XACT_ABORT OFF    
    SET NOCOUNT OFF
    RETURN 0
END    
GO

if object_id ( 'etl.CreatePartitionForFacts', 'p' ) is not null 
    drop procedure etl.CreatePartitionForFacts
go
create procedure etl.CreatePartitionForFacts								
								
/*
	Creates a partition for fact tables.
	
	Usage: etl.CreatePartitionForFacts
		
*/
as
begin
	
	set nocount on 	
	
	declare @FactId uniqueidentifier, @FactName nvarchar(512)
	
	declare factCursor cursor fast_forward 
	for select distinct WarehouseEntityName, EntityGuid
		from etl.WarehouseEntity e 
		join etl.WarehouseEntityType t on (e.WarehouseEntityTypeId = t.WarehouseEntityTypeId)
	   where WarehouseEntityTypeName = 'Fact'		
		
	open factCursor
	fetch next from factCursor 	into @FactName, @FactId

	while @@fetch_status = 0
		begin
			exec etl.CreatePartition @FactId
			
			fetch next from factCursor 	into @FactName, @FactId
		end
	close factCursor
	deallocate factCursor

	return 0

	set nocount off
end	
go

if object_id ( 'etl.DeleteColumn', 'p' ) is not null
    drop procedure etl.DeleteColumn
go

create procedure etl.DeleteColumn

                                 @ColumnsToDeleteXml xml
/*
    Deletes the columns from dimensions view when an extension is uninstalled
    or when a column is excluded.

    Parameters: @ColumnsToDeleteXml it is name of the Job the possible values are user defined jobs

    Usage: etl.DeleteColumn
        '<EntitySchema>
            <RelationalEntity>
                <EntityName>MTV_Computer</EntityName>
                <EntityType>Inbound</EntityType>
                <EntityGuid>f0f61ecb-d038-6115-9b39-282c5e769c09</EntityGuid>
            </RelationalEntity>
            <Schema>
                <Columns>
                    <Column>
                        <ColumnName></ColumnName>
                    </Column>
                    <Column>
                        <ColumnName></ColumnName>
                    </Column>
                </Columns>
            </Schema>
        </EntitySchema>'

*/
as
begin
set nocount on

     declare @RelationalEntityName nvarchar(512), @EntityGuid    uniqueIdentifier,
             @WarehouseEntityType  nvarchar(128), @WarehouseEntityId int

    select  @RelationalEntityName = p.value('(/EntitySchema/RelationalEntity/EntityName/text())[1]', 'nvarchar(512)'),
            @WarehouseEntityType = p.value('(/EntitySchema/RelationalEntity/EntityType/text())[1]', 'nvarchar(128)'),
            @EntityGuid = p.value('(/EntitySchema/RelationalEntity/EntityGuid/text())[1]', 'uniqueIdentifier')
    from @ColumnsToDeleteXml.nodes('/EntitySchema/RelationalEntity') N(p)

    select
        N.p.value('ColumnName[1]', 'nvarchar(255)') as ColumnName into #columns
    from @ColumnsToDeleteXml.nodes('/EntitySchema/Schema/Columns/Column') N(p)

    select @WarehouseEntityId = WarehouseEntityId
    from etl.WarehouseEntity e
        join etl.WarehouseEntityType t on (e.WarehouseEntityTypeId = t.WarehouseEntityTypeId)
    where SourceId = 1 and WarehouseEntityName = @RelationalEntityName
        and EntityGuid = @EntityGuid and t.WarehouseEntityTypeName = @WarehouseEntityType

    delete ec
    from etl.WarehouseColumn ec
        join #columns c on (ec.ColumnName = c.ColumnName or ec.ColumnName = '[' + c.ColumnName + ']')
    where EntityId = @WarehouseEntityId

    if (@@error <> 0)
    begin
        raiserror ('Could not delete columns from relational entity  %s', 16,1,@RelationalEntityName)
        return -1
    end

    return 0

set nocount on
end

go


IF EXISTS(SELECT 1 FROM sys.procedures WHERE name = 'DropCheckConstraintForTable' AND schema_id = SCHEMA_ID('etl'))
BEGIN
    DROP PROCEDURE etl.DropCheckConstraintForTable
END
GO

CREATE PROCEDURE etl.DropCheckConstraintForTable (
	@warehouseEntityId  INT             = NULL,
    @partitionId        INT             = NULL,
    @tableName          NVARCHAR(512)   = NULL,
    @columnName         NVARCHAR(512)   = NULL,
    @constraintName     NVARCHAR(512)   = NULL,
    @excludeTable       NVARCHAR(512)   = NULL,
    @endTobeDropped     VARCHAR(32)     = 'Right' -- 'Right', 'Left', 'Both'
    )
AS
BEGIN
    /*
    ***************************************************************************************************
    *   Step 1: Prep DROP CONSTRAINT script
    *   Step 2: Execute the script
    ***************************************************************************************************
    *
        begin tran
        EXEC etl.DropCheckConstraintForTable
        rollback tran

        begin tran
        EXEC etl.DropCheckConstraintForTable
            @warehouseEntityId = 65,
            @excludeTable = 'WorkItemContainsActivityFact_1900_Jan'
        rollback tran

        begin tran
        EXEC etl.DropCheckConstraintForTable
            @tableName = 'dbo.EntityManagedTypeFact_2009_Sep'
        rollback tran

        begin tran
        EXEC etl.DropCheckConstraintForTable
            @tableName = 'dbo.EntityManagedTypeFact_2009_Sep',
            @columnName = 'DateKey'
        rollback tran

        begin tran
        ALTER TABLE EntityManagedTypeFact_2009_Sep WITH CHECK ADD CONSTRAINT EntityManagedTypeFact_2009_Sep_MaxChk CHECK (DateKey <= 20090930)
        EXEC etl.DropCheckConstraintForTable
            @tableName = 'dbo.EntityManagedTypeFact_2009_Sep',
            @constraintName = 'EntityManagedTypeFact_2009_Sep_MaxChk'
        rollback tran

        begin tran
        ALTER TABLE EntityManagedTypeFact_2009_Sep WITH CHECK ADD CONSTRAINT EntityManagedTypeFact_2009_Sep_MaxChk CHECK (DateKey <= 20090930)
        EXEC etl.DropCheckConstraintForTable
            @tableName = 'dbo.EntityManagedTypeFact_2009_Sep',
            @columnName = 'DateKey'
        rollback tran

        begin tran
        ALTER TABLE EntityManagedTypeFact_2009_Sep WITH CHECK ADD CONSTRAINT TESTTESTTEST CHECK (EntityDimKey <= 20090930)
        ALTER TABLE EntityManagedTypeFact_2009_Sep WITH CHECK ADD CONSTRAINT EntityManagedTypeFact_2009_Sep_MaxChk CHECK (DateKey <= 20090930)
        EXEC etl.DropCheckConstraintForTable
            @tableName = 'dbo.EntityManagedTypeFact_2009_Sep',
            @columnName = 'DateKey'
        rollback tran
    ***************************************************************************************************
    */

    SET NOCOUNT ON

    DECLARE @errorNumber        INT,
            @errorSeverity      INT,
            @errorState         INT,
            @errorLine          INT,
            @errorProcedure     NVARCHAR(256),
            @errorMessage       NVARCHAR(MAX),
            @task               NVARCHAR(512)

    DECLARE @CHKScript          NVARCHAR(MAX)   = '',
            @DropTemplate       NVARCHAR(MAX)   = 'ALTER TABLE %TABLENAME% DROP CONSTRAINT %CHECKCONSTRAINTNAME%',
            @MinChkTemplate     NVARCHAR(MAX)   = 'ALTER TABLE %CURRENTPARTITIONNAME% WITH CHECK ADD CONSTRAINT %CONSTRAINTNAME% CHECK (%DATEKEYCOLUMNNAME% >= %CURRENTMINDATE%)',
            @MaxChkTemplate     NVARCHAR(MAX)   = 'ALTER TABLE %CURRENTPARTITIONNAME% WITH CHECK ADD CONSTRAINT %CONSTRAINTNAME% CHECK (%DATEKEYCOLUMNNAME% <= %CURRENTMAXDATE%)',
            @MinMaxChkTemplate  NVARCHAR(MAX)   = 'ALTER TABLE %CURRENTPARTITIONNAME% WITH CHECK ADD CONSTRAINT %CONSTRAINTNAME% CHECK ((%DATEKEYCOLUMNNAME% >= %CURRENTMINDATE%) AND (%DATEKEYCOLUMNNAME% <= %CURRENTMAXDATE%))'

    BEGIN TRY
        SELECT  @task = 'Init'
        SELECT  @tableName = tblPart.PartitionName
        FROM    etl.TablePartition tblPart
        WHERE   tblPart.EntityId = @warehouseEntityId
            AND tblPart.PartitionId = @partitionId

        IF(OBJECT_ID(@tableName) IS NULL AND NOT EXISTS(SELECT 'x' FROM etl.TablePartition WHERE EntityId = @warehouseEntityId))
        BEGIN
		    RAISERROR('Invalid Input/s provided. Cannot locate Table Object with @warehouseEntityId = %d, @tableName = %s', 16, 1, @warehouseEntityId, @tableName)
		    RETURN -1
        END

        SELECT      @task       = 'Preparing Primary Key Drop script iteratively'
        SELECT      @CHKScript  = @CHKScript + CHAR(13)
                                    + REPLACE(REPLACE(@DropTemplate, '%TABLENAME%', OBJECT_NAME(checkObj.Parent_Object_Id)), '%CHECKCONSTRAINTNAME%', checkObj.Name) + CHAR(13)
                                    + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                                        CASE
                                            -- if 'Both' ends need to be dropped, then the script template = ''
                                            -- if 'Left' end needs to be dropped OR if RangeStartDate is null then script template = maxtemplate, but only if RangeEndDate is not null
                                            -- if 'Right' end needs to be dropped OR if RangeEndDate is null then script template = mintemplate, but only if RangeStarteDate is not null
                                            WHEN (@endTobeDropped = 'Both' OR (tblPart.RangeStartDate IS NULL AND tblPart.RangeEndDate IS NULL)) THEN ''
                                            WHEN (@endTobeDropped = 'Left' OR tblPart.RangeStartDate IS NULL) AND tblPart.RangeEndDate IS NOT NULL THEN @MaxChkTemplate
                                            WHEN (@endTobeDropped = 'Right' OR tblPart.RangeEndDate IS NULL) AND tblPart.RangeStartDate IS NOT NULL THEN @MinChkTemplate
                                            ELSE ''
                                        END,
                                        '%CONSTRAINTNAME%', etl.NormalizeNameForLength(tblPart.PartitionName + '_Chk', 128)),
                                        '%CURRENTMAXDATE%', ISNULL(tblPart.RangeEndDate, 0)),
                                        '%CURRENTMINDATE%', ISNULL(tblPart.RangeStartDate, 0)),
                                        '%DATEKEYCOLUMNNAME%', columnObj.Name),
                                        '%CURRENTPARTITIONNAME%', tblPart.PartitionName)
        FROM        SYS.TABLES tableObj
        INNER JOIN  SYS.COLUMNS columnObj ON
                    tableObj.Object_Id = columnObj.Object_Id
        INNER JOIN  SYS.CHECK_CONSTRAINTS checkObj ON
                    tableObj.Object_Id = checkObj.Parent_Object_Id
                AND columnObj.Column_Id = checkObj.Parent_Column_Id
        INNER JOIN  etl.TablePartition tblPart ON
                    tableObj.Name = tblPart.PartitionName
        WHERE       tableObj.Object_Id = CASE WHEN @tableName IS NOT NULL THEN OBJECT_ID(@tableName) ELSE OBJECT_ID(tblPart.PartitionName) END
                AND (@excludeTable IS NULL OR tableObj.Name <> @excludeTable)
				AND tblPart.EntityId = ISNULL(@warehouseEntityId, tblPart.EntityId)
                AND checkObj.Name = ISNULL(@constraintName, checkObj.Name)
                AND (   (@columnName IS NOT NULL AND columnObj.Name = @columnName)
                    OR  (columnObj.Name IN ('DateKey', 'MonthKey', 'WeekKey'))
                    )

        SELECT  @task   = 'Executing CHKScriptTemplate'
        PRINT   @CHKScript
        IF(@CHKScript <> '')
        BEGIN
            EXEC (@CHKScript)
        END
        RETURN 0;
     END TRY
    BEGIN CATCH
        DECLARE @errorFmt       VARCHAR(256)

        SELECT  @errorFmt       = N'ErrorNumber="%d" Message="%s" Severity="%d" State="%d" ProcedureName="%s" LineNumber="%d" Task="%s"',
                @errorNumber    = ERROR_NUMBER(),
                @errorMessage   = ERROR_MESSAGE(),
                @errorSeverity  = ERROR_SEVERITY(),
                @errorState     = ERROR_STATE(),
                @errorLine      = ERROR_LINE(),
                @errorProcedure = ERROR_PROCEDURE()

        RAISERROR (
            @errorFmt,
            18,
            @errorState,
            @errorNumber,
            @errorMessage,
            @errorSeverity,
            @errorState,
            @errorProcedure,
            @errorLine,
            @task
        )
        RETURN -1
    END CATCH
END
GO

IF OBJECT_ID ( 'etl.DropPartition', 'P' ) IS NOT NULL 
    DROP PROCEDURE etl.DropPartition
GO

CREATE PROCEDURE etl.DropPartition
    @warehouseEntityId          INT,
    @warehouseEntityType        NVARCHAR(128),
    @entityGuid                 UNIQUEIDENTIFIER,
    @partitionId                INT,
    @GroomActiveRelationship    BIT = 0
AS
BEGIN
    SET NOCOUNT ON
    SET XACT_ABORT ON

    DECLARE @errorNumber        INT,
            @errorSeverity      INT,
            @errorState         INT,
            @errorLine          INT,
            @errorProcedure     NVARCHAR(256),
            @errorMessage       NVARCHAR(MAX),
            @task               NVARCHAR(512)

    DECLARE @partitionName          NVARCHAR(512)   = '',
            @followingPartitionName NVARCHAR(512)   = '',
            @minCheckConstraintName NVARCHAR(512)   = '',
            @columnList             NVARCHAR(MAX)   = '',
            @tempScript             NVARCHAR(MAX)   = '',
            @droppedPartRangeStart  INT             = NULL

    BEGIN TRY
        SET @task = N'Retrieving PartitionName for PartitionId: ' + CAST(@partitionId AS VARCHAR(32))
        SELECT  @partitionName = PartitionName,
                @droppedPartRangeStart = RangeStartDate
        FROM    etl.TablePartition
        WHERE   PartitionId = @partitionId

        SET @task = N'Validating PartitionName for PartitionName: ' + @partitionName
        IF NOT EXISTS(SELECT 'x' FROM sys.tables WHERE Name = @partitionName)
        BEGIN
		    RAISERROR(N'PartitionName does not exist.', 16, 1)
        END

        SET @task = N'Retrieving name of the following Partition for the WarehouseEntity'
        SELECT TOP 1 @followingPartitionName = PartitionName
        FROM        etl.TablePartition
        WHERE       EntityId = @warehouseEntityId
                AND PartitionId > @partitionId
        ORDER BY    PartitionId

        SET @task = N'Preparing column list for the Partition.'
        SELECT  @columnList = col.name + ', ' + @columnList
        FROM    sys.columns col
        WHERE   object_id = OBJECT_ID(@partitionName)
        ORDER BY column_id DESC

        SET @columnList = LEFT(@columnList, LEN( ISNULL(NULLIF( LTRIM(RTRIM(@columnList)), ''), ',')) - 1)

        BEGIN TRANSACTION
            SET @task = N'Updating RangeStartDate for @followingPartitionName.'
            UPDATE etl.TablePartition SET
                RangeStartDate = @droppedPartRangeStart
            WHERE PartitionName = @followingPartitionName

            SET @task = N'Deleting entry from table TablePartition.'
            DELETE etl.TablePartition
            WHERE PartitionId = @partitionId

            SET @task = N'Opening MIN Check constraint for the next Partition'
            SET @minCheckConstraintName = etl.NormalizeNameForLength(@followingPartitionName + '_Chk', 128)
            EXEC etl.DropCheckConstraintForTable
	            @warehouseEntityId  = @warehouseEntityId,
                @tableName          = @followingPartitionName,
                @constraintName     = @minCheckConstraintName,
                @endTobeDropped     = 'Left'

            SET @task = N'Saving "Active" facts from partition PartitionName: ' + @partitionName
            IF (@GroomActiveRelationship <> 1 AND @followingPartitionName <> '' AND EXISTS(SELECT 'x' FROM sys.columns WHERE Name = 'DeletedDate' AND object_id = OBJECT_ID(@partitionName)))
            BEGIN
                SET @tempScript = 'INSERT INTO %FOLLOWINGPARTITIONNAME%(%COLUMNLIST%) SELECT %COLUMNLIST% FROM %PARTITIONNAME% WHERE DeletedDate IS NULL'
                SET @tempScript = REPLACE(@tempScript, '%FOLLOWINGPARTITIONNAME%', @followingPartitionName)
                SET @tempScript = REPLACE(@tempScript, '%COLUMNLIST%', @columnList)
                SET @tempScript = REPLACE(@tempScript, '%PARTITIONNAME%', @partitionName)
                
                SET @task = 'Executing script to store "Active" facts'
                PRINT @tempScript
                EXEC(@tempScript)
            END

            SET @task = N'Dropping partition PartitionName: ' + @partitionName
            EXEC('DROP TABLE [dbo].[' + @partitionName + ']')

            SET @task = N'Re-creating View.'
            EXEC etl.CreateView
                @EntityGuid             = @entityGuid,
                @warehouseEntityType    = @warehouseEntityType
        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        IF(@@TRANCOUNT > 0) ROLLBACK TRANSACTION
        
        DECLARE @errorFmt       VARCHAR(256)

        SELECT  @errorFmt       = N'ErrorNumber="%d" Message="%s" Severity="%d" State="%d" ProcedureName="%s" LineNumber="%d" Task="%s"',
                @errorNumber    = ERROR_NUMBER(),
                @errorMessage   = ERROR_MESSAGE(),
                @errorSeverity  = ERROR_SEVERITY(),
                @errorState     = ERROR_STATE(),
                @errorLine      = ERROR_LINE(),
                @errorProcedure = ERROR_PROCEDURE()

        RAISERROR (
            @errorFmt,
            18,
            @errorState,
            @errorNumber,
            @errorMessage,
            @errorSeverity,
            @errorState,
            @errorProcedure,
            @errorLine,
            @task
        )

        RETURN -1
    END CATCH
    
    SET XACT_ABORT OFF
    SET NOCOUNT OFF
    RETURN 0
END
GO


if object_id ( 'etl.PrepareForGrooming', 'p' ) is not null 
    drop procedure etl.PrepareForGrooming
go

CREATE PROCEDURE etl.PrepareForGrooming
AS
BEGIN
    SET NOCOUNT ON
    SET XACT_ABORT ON

    DECLARE @errorNumber        INT,
            @errorSeverity      INT,
            @errorState         INT,
            @errorLine          INT,
            @errorProcedure     NVARCHAR(256),
            @errorMessage       NVARCHAR(MAX),
            @task               NVARCHAR(512)

    DECLARE @retentionDefault   VARCHAR(64),
            @groomingProcedure  VARCHAR(MAX)

    BEGIN TRY

        SET @task = N'Reading Default Grooming RetentionPeriodInMinutes'
        SELECT  @retentionDefault = ConfiguredValue
        FROM    etl.Configuration
        WHERE   ConfigurationFilter = 'DWMaintenance.Grooming'
            AND ConfigurationPath = 'RetentionPeriodInMinutes.Default'

        -- Default to 3mons if configuration is not present
        SELECT @retentionDefault = ISNULL(@retentionDefault, '129600')

        SET @task = N'Reading Default Grooming Procedure'
        SELECT  @groomingProcedure = ConfiguredValue
        FROM    etl.Configuration
        WHERE   ConfigurationFilter = 'DWMaintenance.Grooming.GroomingStoredProcedure'
            AND ConfigurationPath = 'GroomingProcedure.Default'

        SELECT @groomingProcedure = ISNULL(@groomingProcedure, 'EXEC etl.DropPartition @WarehouseEntityId=@WarehouseEntityId, @WarehouseEntityType=@WarehouseEntityType, @EntityGuid=@EntityGuid, @PartitionId=@PartitionId, @GroomActiveRelationship=0')

        SET @task = N'Importing Warehouse entities from etl.WarehouseEntity into etl.WarehouseEntityGroomingInfo'
        INSERT INTO etl.WarehouseEntityGroomingInfo(WarehouseEntityId, RetentionPeriodInMinutes, GroomingStoredProcedure)
        SELECT      whEntity.WarehouseEntityId, CAST(COALESCE(cfg.ConfiguredValue, @retentionDefault) AS INT), COALESCE(cfgProc.ConfiguredValue, @groomingProcedure)
        FROM        etl.WarehouseEntity whEntity
        INNER JOIN  etl.WarehouseEntityType whEntityType ON
                    whEntity.WarehouseEntityTypeId = whEntityType.WarehouseEntityTypeId
        LEFT JOIN   etl.Configuration cfg ON
                    cfg.ConfigurationFilter = 'DWMaintenance.Grooming.RetentionPeriodInMinutes'
                AND whEntity.WarehouseEntityName = cfg.ConfigurationPath
        LEFT JOIN   etl.Configuration cfgProc ON
                    cfgProc.ConfigurationFilter = 'DWMaintenance.Grooming.GroomingStoredProcedure'
                AND whEntity.WarehouseEntityName = cfgProc.ConfigurationPath
        LEFT JOIN   etl.WarehouseEntityGroomingInfo whEntityInfo ON
                    whEntity.WarehouseEntityId = whEntityInfo.WarehouseEntityId
        WHERE       whEntityInfo.WarehouseEntityId IS NULL
                AND whEntityType.WarehouseEntityTypeName = N'Fact'

        SET @task = N'Updating etl.WarehouseEntityGroomingInfo to carry forward any updates to etl.Configuration table'
        UPDATE      groomingInfo SET
                    GroomingStoredProcedure = COALESCE(cfg.ConfiguredValue, @groomingProcedure),
                    UpdatedDate = GETUTCDATE()
        FROM        etl.WarehouseEntityGroomingInfo groomingInfo
        INNER JOIN  etl.WarehouseEntity whEntity ON
                    groomingInfo.WarehouseEntityId = whEntity.WarehouseEntityId
        INNER JOIN  etl.WarehouseEntityType whEntityType ON
                    whEntity.WarehouseEntityTypeId = whEntityType.WarehouseEntityTypeId
        LEFT JOIN   etl.Configuration cfg ON
                    cfg.ConfigurationFilter = 'DWMaintenance.Grooming.GroomingStoredProcedure'
                AND whEntity.WarehouseEntityName = cfg.ConfigurationPath
        WHERE       whEntityType.WarehouseEntityTypeName = N'Fact'
            AND     groomingInfo.GroomingStoredProcedure <> COALESCE(cfg.ConfiguredValue, @groomingProcedure)

        SET @task = N'Adding WarehouseEntityGroomingHistory entries'
        INSERT INTO etl.WarehouseEntityGroomingHistory
        (
                    WarehouseEntityId,
                    PartitionIdTobeGroomed,
                    PartitionName,
                    RangeStartDate,
                    RangeEndDate,
                    PartitionRowCount,
                    PreparationDate,
                    GroomedDate
        )
        SELECT      groomInfo.WarehouseEntityId,
                    partitionInfo.PartitionId,
                    partitionInfo.PartitionName,
                    partitionInfo.RangeStartDate,
                    partitionInfo.RangeEndDate,
                    (SELECT SUM(CASE WHEN (index_id < 2) THEN row_count ELSE 0 END) FROM sys.dm_db_partition_stats WHERE object_id = OBJECT_ID(partitionInfo.PartitionName)) AS PartitionRowCount,
                    GETUTCDATE(),
                    NULL
        FROM        etl.WarehouseEntityGroomingInfo groomInfo
        INNER JOIN  etl.TablePartition partitionInfo ON
                    groomInfo.WarehouseEntityId = partitionInfo.EntityId
                AND partitionInfo.RangeEndDate IS NOT NULL
                AND partitionInfo.RangeEndDate < CONVERT(NVARCHAR(8), DATEADD(MI, -groomInfo.RetentionPeriodInMinutes, GETUTCDATE()), 112)
        LEFT JOIN   etl.WarehouseEntityGroomingHistory alreadyMarkedForGrooming ON
                    groomInfo.WarehouseEntityId = alreadyMarkedForGrooming.WarehouseEntityId
                AND partitionInfo.PartitionId = alreadyMarkedForGrooming.PartitionIdTobeGroomed
        WHERE       alreadyMarkedForGrooming.WarehouseEntityGroomingHistoryId IS NULL
    END TRY
    BEGIN CATCH
        DECLARE @errorFmt       VARCHAR(256)

        SELECT  @errorFmt       = N'ErrorNumber="%d" Message="%s" Severity="%d" State="%d" ProcedureName="%s" LineNumber="%d" Task="%s"',
                @errorNumber    = ERROR_NUMBER(),
                @errorMessage   = ERROR_MESSAGE(),
                @errorSeverity  = ERROR_SEVERITY(),
                @errorState     = ERROR_STATE(),
                @errorLine      = ERROR_LINE(),
                @errorProcedure = ERROR_PROCEDURE()

        RAISERROR (
            @errorFmt,
            @errorSeverity,
            @errorState,
            @errorNumber,
            @errorMessage,
            @errorSeverity,
            @errorState,
            @errorProcedure,
            @errorLine,
            @task
        )

        RETURN -1
    END CATCH

    SET XACT_ABORT OFF
    SET NOCOUNT OFF
    RETURN 0
END
GO

IF OBJECT_ID ( 'etl.PerformGrooming', 'P' ) IS NOT NULL 
    DROP PROCEDURE etl.PerformGrooming
GO

CREATE PROCEDURE etl.PerformGrooming
    @maxPartitionsToGroom       INT = NULL,
    --@terminateAfterMinutes      INT = NULL,
    @warehouseEntityId          INT = NULL,
    @partitionId                INT = NULL
AS
BEGIN
    SET NOCOUNT ON
    SET XACT_ABORT ON

    DECLARE @errorNumber        INT,
            @errorSeverity      INT,
            @errorState         INT,
            @errorLine          INT,
            @errorProcedure     NVARCHAR(256),
            @errorMessage       NVARCHAR(MAX),
            @task               NVARCHAR(512)

    DECLARE @tempEntityGuid             UNIQUEIDENTIFIER,
            @tempEntityId               INT,
            @tempEntityType             NVARCHAR(128),
            @tempPartitionId            INT,
            @groomingHistoryId          BIGINT,
            @groomingStoredProcedure    NVARCHAR(MAX)

    BEGIN TRY
        WHILE(1 = 1)
        BEGIN
            SET @task = 'Retrieving Entity information.'
            SELECT  @tempEntityId = NULL,
                    @tempPartitionId = NULL

            SELECT  TOP 1   @tempEntityId               = whEntity.WarehouseEntityId,
                            @tempEntityType             = whEntityType.WarehouseEntityTypeName,
                            @tempEntityGuid             = whEntity.EntityGuid,
                            @tempPartitionId            = groomHistory.PartitionIdTobeGroomed,
                            @groomingHistoryId          = groomHistory.WarehouseEntityGroomingHistoryId,
                            @groomingStoredProcedure    = groomInfo.GroomingStoredProcedure
            FROM            etl.WarehouseEntityGroomingHistory groomHistory
            INNER JOIN      etl.WarehouseEntityGroomingInfo groomInfo ON
                            groomHistory.WarehouseEntityId = groomInfo.WarehouseEntityId
            INNER JOIN      etl.WarehouseEntity whEntity ON
                            groomHistory.WarehouseEntityId = whEntity.WarehouseEntityId
            INNER JOIN      etl.WarehouseEntityType whEntityType ON
                            whEntity.WarehouseEntityTypeId = whEntityType.WarehouseEntityTypeId
            WHERE           (@warehouseEntityId IS NULL OR whEntity.WarehouseEntityId = @warehouseEntityId)
                AND         (@partitionId IS NULL OR PartitionIdTobeGroomed = @partitionId)
                AND         GroomedDate IS NULL -- determines if the grooming has already taken place for this

            SELECT @task = 'Checking to break the loop. @maxPartitionsToGroom: ' + CASE WHEN @maxPartitionsToGroom IS NULL THEN 'IS NULL' ELSE CAST(@maxPartitionsToGroom AS VARCHAR(32)) END + ' @tempEntityId: ' + CASE WHEN @tempEntityId IS NULL THEN 'IS NULL' ELSE CAST(@tempEntityId AS VARCHAR(32)) END + ' @tempPartitionId: ' + CASE WHEN @tempPartitionId IS NULL THEN 'IS NULL' ELSE CAST(@tempPartitionId AS VARCHAR(32)) END
            PRINT @task
            IF(ISNULL(@maxPartitionsToGroom, 1) = 0 OR @tempEntityId IS NULL OR @tempPartitionId IS NULL)
            BEGIN
                BREAK;
            END

            SET @task = 'Executing groomingStoredProcedure: ' + @groomingStoredProcedure
            EXEC SP_EXECUTESQL
                @groomingStoredProcedure,
                N'@WarehouseEntityId INT, @WarehouseEntityType NVARCHAR(128), @EntityGuid UNIQUEIDENTIFIER, @PartitionId INT',
                @WarehouseEntityId      = @tempEntityId,
                @WarehouseEntityType    = @tempEntityType,
                @EntityGuid             = @tempEntityGuid,
                @PartitionId            = @tempPartitionId

            SET @task = 'Updating WarehouseEntityGroomingHistory for WarehouseEntityGroomingHistoryId: ' + CAST(@warehouseEntityId AS VARCHAR(32))
            UPDATE  groomHistory SET
                    GroomedDate = GETUTCDATE()
            FROM    etl.WarehouseEntityGroomingHistory groomHistory
            WHERE   WarehouseEntityGroomingHistoryId =  @groomingHistoryId

            SELECT  @maxPartitionsToGroom = @maxPartitionsToGroom - 1
        END
    END TRY
    BEGIN CATCH
        DECLARE @errorFmt       VARCHAR(256)

        SELECT  @errorFmt       = N'ErrorNumber="%d" Message="%s" Severity="%d" State="%d" ProcedureName="%s" LineNumber="%d" Task="%s"',
                @errorNumber    = ERROR_NUMBER(),
                @errorMessage   = ERROR_MESSAGE(),
                @errorSeverity  = ERROR_SEVERITY(),
                @errorState     = ERROR_STATE(),
                @errorLine      = ERROR_LINE(),
                @errorProcedure = ERROR_PROCEDURE()

        RAISERROR (
            @errorFmt,
            @errorSeverity,
            @errorState,
            @errorNumber,
            @errorMessage,
            @errorSeverity,
            @errorState,
            @errorProcedure,
            @errorLine,
            @task
        )

        RETURN -1
    END CATCH
    
    SET XACT_ABORT OFF
    SET NOCOUNT OFF
    RETURN 0
END
GO


if object_id ( 'etl.GetPartitionName', 'p' ) is not null 
    drop procedure etl.GetPartitionName
go
create procedure etl.GetPartitionName							  
									@RelationalEntityName nvarchar(512),
									@Month datetime = null
/*
	Creates a partition for fact tables.

	Parameters: @EntityGuid is guid of the fact that needs partition created.
	
	Usage: 
	etl.GetPartitionName 'ComputerHostsOperatingSystemFact'
	declare @dt datetime = getutcdate()
	exec etl.GetPartitionName 'ComputerHostsOperatingSystemFact', @dt
	declare @dt datetime = dateadd(month, 2, getutcdate())
	exec etl.GetPartitionName 'ComputerHostsOperatingSystemFact', @dt
	declare @dt datetime = dateadd(month, -2, getutcdate())
	exec etl.GetPartitionName 'ComputerHostsOperatingSystemFact', @dt
*/
as
begin
	set nocount on 	

	if (isnull(@RelationalEntityName, '') = '') 
	begin
		raiserror('Invalid entity name null',16,1)
		return -1
	end

	select etl.PartitionName (@RelationalEntityName, @Month, null)

	return 0
	set nocount off
end	
go


if object_id ( 'etl.UninstallRelationalEntity', 'p' ) is not null 
    drop procedure etl.UninstallRelationalEntity
go
create procedure etl.UninstallRelationalEntity							  
									           @EntityGuid			uniqueIdentifier,
									           @EntityXml			xml,      
											   @WarehouseEntityType nvarchar(128)
/*
 Gets the list of all modules for a given Job. 

 Parameters: @Job it is name of the Job the possible values are user defined jobs
 
 Usage: etl.UninstallRelationalEntity  
  '<RelationalEntity>
   <EntityName>MTV_Computer</EntityName>
   <EntityType>Inbound</EntityType>
   <EntityGuid>f0f61ecb-d038-6115-9b39-282c5e769c09</EntityGuid>
   <SourceName>IncidentMG</SourceName>
   <SourceGuid>e0f61ecb-d038-6115-9b39-282c5e769c07</SourceGuid>
   <SourceType>ServiceManager</SourceType>
  </RelationalEntity>' 
*/
as
begin
set nocount on 
 
	 declare @EntityId int, @retval int, @EntityName nvarchar(512), @SourceId int,  
	 @SourceGuid uniqueIdentifier, @SourceName nvarchar(512), @SourceType nvarchar(128)
  
	 select  @SourceName = p.value('(/RelationalEntity/SourceName/text())[1]', 'nvarchar(512)'),
			 @SourceGuid = p.value('(/RelationalEntity/SourceGuid/text())[1]', 'uniqueIdentifier'),
			 @SourceType = p.value('(/RelationalEntity/SourceType/text())[1]', 'nvarchar(128)')
	 from @EntityXml.nodes('/RelationalEntity') N(p)
   
	select @SourceId = SourceId 
	from etl.Source s join etl.SourceType t on (t.SourceTypeId = s.SourceTypeId)
	where SourceGuid = @SourceGuid and SourceName = @SourceName and t.SourceTypeName = @SourceType

	select @EntityId = e.WarehouseEntityId, @EntityName = WarehouseEntityName
	from etl.WarehouseEntityType ET 
	join etl.WarehouseEntity e on (e.WarehouseEntityTypeId = ET.WarehouseEntityTypeId)
	where ET.WarehouseEntityTypeName = @WarehouseEntityType and e.EntityGuid = @EntityGuid
	and e.SourceId = @SourceId		
	
	begin transaction	
	
	delete from etl.WarehouseColumn where EntityId = @EntityId
	
	if (@@ERROR <> 0)
	begin
		raiserror ('Could not delete columns for entity %s', 16,1,@EntityName)
		rollback transaction
		return -1
	end				

	delete from etl.WarehouseEntity where WarehouseEntityId = @EntityId
	
	if (@@rowcount <> 1)
	begin
		raiserror ('Could not delete Entity %s', 16,1,@EntityName)
		rollback transaction
		select @retval = -1				
	end				

	select @retval = 0
	commit transaction
		
	return @retval

set nocount on 
end

go

if object_id ( 'etl.UninstallModule', 'p' ) is not null 
    drop procedure etl.UninstallModule
go
create procedure etl.UninstallModule
									@ModuleName nvarchar(512),
									@SourceId  int
/*
	Delete Module
	usage:  			  

	etl.UninstallModule 'TransformComputerDim', 1		
*/
as
begin
set nocount on 

	--To protect against runtime error during string parsing to ensure always close transaction 
	set xact_abort on 

	Declare @ModuleId int, @rowcount int, @retval int
		
	select @ModuleId = ModuleId from etl.WarehouseModule where ModuleName = @ModuleName
	
	begin transaction	
	
	delete from etl.WarehouseModuleDependency where ModuleId = @ModuleId
	
	if (@@rowcount = 0)
	begin
		raiserror ('Could not delete dependencies for Module %s', 16,1,@ModuleName)
		rollback transaction
		select @retval = -1
		goto cleanup
	end				

	delete from etl.WarehouseModule where ModuleId = @ModuleId
	
	if (@@rowcount <> 1)
	begin
		raiserror ('Could not delete Module %s', 16,1,@ModuleName)
		rollback transaction
		select @retval = -1
		goto cleanup
	end				

	select @retval = 0
	commit transaction
	set xact_abort off

cleanup:

	if object_id('tempdb..#Dependencies') is not null
	begin
		drop table #Dependencies
	end
	
	return @retval

set nocount on 
end

go

IF EXISTS(SELECT 1 FROM sys.procedures WHERE name = 'DropPrimaryKeyForTable' AND schema_id = SCHEMA_ID('etl'))
BEGIN
    DROP PROCEDURE etl.DropPrimaryKeyForTable
END
GO

CREATE PROCEDURE etl.DropPrimaryKeyForTable (
	@warehouseEntityId  INT             = NULL,
    @tableName          NVARCHAR(512)   = NULL,
    @excludeTable       NVARCHAR(512)   = NULL
    )
AS
BEGIN
    /*
    ***************************************************************************************************
    *   Step 1: Prepare Primary Key Script iteratively
    *   Step 2: Execute Primary Key Script
    ***************************************************************************************************
    *
        begin tran
        EXEC etl.DropPrimaryKeyForTable
            @tableName = 'dbo.EntityManagedTypeFact_2009_Jul'
        rollback tran

        begin tran
        EXEC etl.DropPrimaryKeyForTable
            @warehouseEntityId = 17
        rollback tran
    ***************************************************************************************************
    */

    SET NOCOUNT ON

    DECLARE @errorNumber        INT,
            @errorSeverity      INT,
            @errorState         INT,
            @errorLine          INT,
            @errorProcedure     NVARCHAR(256),
            @errorMessage       NVARCHAR(MAX),
            @task               NVARCHAR(512)

    DECLARE @PKScript           NVARCHAR(MAX),
            @PKScriptTemplate   NVARCHAR(MAX)

    BEGIN TRY
        SELECT  @task   = 'Input validation'
        IF(ISNULL(@warehouseEntityId, 0) = 0 AND OBJECT_ID(@tableName) IS NULL)
        BEGIN
		    RAISERROR('Invalid Input/s', 16, 1)
		    RETURN -1
        END

        SELECT  @task               = 'Init'
        SELECT  @PKScript           = '',
                @PKScriptTemplate   = 'ALTER TABLE %TABLENAME% DROP CONSTRAINT %PKNAME%'

        SELECT      @task       = 'Preparing Primary Key Drop script iteratively'
        SELECT      @PKScript   = @PKScript + CHAR(13) + REPLACE(REPLACE(@PKScriptTemplate, '%TABLENAME%', OBJECT_NAME(PK.parent_object_id)), '%PKNAME%', PK.name) 
        FROM        sys.key_constraints PK
        LEFT JOIN   etl.TablePartition tblPart ON
                    tblPart.EntityId = @warehouseEntityId
        WHERE       PK.parent_object_id = CASE WHEN @warehouseEntityId IS NOT NULL THEN OBJECT_ID(tblPart.PartitionName) ELSE OBJECT_ID(@tableName) END
                AND PK.type = 'PK'
                AND (@excludeTable IS NULL OR PK.parent_object_id <> OBJECT_ID(@excludeTable)) -- this is to be able to exclude Partition created by RelationalDeployer

        PRINT   @PKScript

        SELECT  @task   = 'Executing PKScriptTemplate'
        IF(@PKScript <> '')
        BEGIN
            EXEC (@PKScript)
        END

        RETURN 0;
     END TRY
    BEGIN CATCH
        DECLARE @errorFmt       VARCHAR(256)

        SELECT  @errorFmt       = N'ErrorNumber="%d" Message="%s" Severity="%d" State="%d" ProcedureName="%s" LineNumber="%d" Task="%s"',
                @errorNumber    = ERROR_NUMBER(),
                @errorMessage   = ERROR_MESSAGE(),
                @errorSeverity  = ERROR_SEVERITY(),
                @errorState     = ERROR_STATE(),
                @errorLine      = ERROR_LINE(),
                @errorProcedure = ERROR_PROCEDURE()

        RAISERROR (
            @errorFmt,
            18,
            @errorState,
            @errorNumber,
            @errorMessage,
            @errorSeverity,
            @errorState,
            @errorProcedure,
            @errorLine,
            @task
        )
        RETURN -1
    END CATCH
END
GO
IF EXISTS(SELECT 1 FROM sys.procedures WHERE name = 'DropForeignKeysForTable' AND schema_id = SCHEMA_ID('etl'))
BEGIN
    DROP PROCEDURE etl.DropForeignKeysForTable
END
GO

CREATE PROCEDURE etl.DropForeignKeysForTable (
	@warehouseEntityId  INT             = NULL,
    @tableName          NVARCHAR(512)   = NULL,
    @excludeTable       NVARCHAR(512)   = NULL
    )
AS
BEGIN
    /*
    ***************************************************************************************************
    *   Step 1: Prepare Foreign Key Drop Script iteratively
    *   Step 2: Execute Script
    ***************************************************************************************************
    *
        begin tran
        EXEC etl.DropForeignKeysForTable
            @tableName = 'dbo.EntityManagedTypeFact_2009_Aug'
        rollback tran

        begin tran
        EXEC etl.DropForeignKeysForTable
            @warehouseEntityId = 17
        rollback tran

        begin tran
        EXEC etl.DropForeignKeysForTable
            @warehouseEntityId = 17,
            @tableName = 'dbo.EntityManagedTypeFact_2009_Aug'
        rollback tran
    ***************************************************************************************************
    */

    SET NOCOUNT ON

    DECLARE @errorNumber        INT,
            @errorSeverity      INT,
            @errorState         INT,
            @errorLine          INT,
            @errorProcedure     NVARCHAR(256),
            @errorMessage       NVARCHAR(MAX),
            @task               NVARCHAR(512)

    DECLARE @FKScriptTemplate   NVARCHAR(MAX),
            @FKScript           NVARCHAR(MAX)

    BEGIN TRY
        SELECT  @task   = 'Input validation'
        IF(ISNULL(@warehouseEntityId, 0) = 0 AND OBJECT_ID(@tableName) IS NULL)
        BEGIN
		    RAISERROR('Invalid Input/s', 16, 1)
		    RETURN -1
        END

        SELECT  @task               = 'Init'
        SELECT  @FKScript           = '',
                @FKScriptTemplate   = 'ALTER TABLE %TABLENAME% DROP CONSTRAINT %FKNAME%'

        SELECT      @task       = 'Preparing Foreign Key Drop script iteratively'
        SELECT      @FKScript   = @FKScript + CHAR(13) + REPLACE(REPLACE(@FKScriptTemplate, '%TABLENAME%', OBJECT_NAME(FK.parent_object_id)), '%FKNAME%', FK.name)
        FROM        sys.foreign_keys FK
        LEFT JOIN   etl.TablePartition tblPart ON
                    tblPart.EntityId = @warehouseEntityId
        WHERE       FK.parent_object_id = CASE WHEN @warehouseEntityId IS NOT NULL THEN OBJECT_ID(tblPart.PartitionName) ELSE OBJECT_ID(@tableName) END
                AND (@excludeTable IS NULL OR FK.parent_object_id <> OBJECT_ID(@excludeTable)) -- this is to be able to exclude Partition created by RelationalDeployer

        PRINT   @FKScript

        SELECT  @task   = 'Executing FKScriptTemplate'
        IF(@FKScript <> '')
        BEGIN
            EXEC (@FKScript)
        END

        RETURN 0;
     END TRY
    BEGIN CATCH
        DECLARE @errorFmt       VARCHAR(256)

        SELECT  @errorFmt       = N'ErrorNumber="%d" Message="%s" Severity="%d" State="%d" ProcedureName="%s" LineNumber="%d" Task="%s"',
                @errorNumber    = ERROR_NUMBER(),
                @errorMessage   = ERROR_MESSAGE(),
                @errorSeverity  = ERROR_SEVERITY(),
                @errorState     = ERROR_STATE(),
                @errorLine      = ERROR_LINE(),
                @errorProcedure = ERROR_PROCEDURE()

        RAISERROR (
            @errorFmt,
            18,
            @errorState,
            @errorNumber,
            @errorMessage,
            @errorSeverity,
            @errorState,
            @errorProcedure,
            @errorLine,
            @task
        )
        RETURN -1
    END CATCH
END
GO
IF EXISTS(SELECT 1 FROM sys.procedures WHERE name = 'DropIndexesForTable' AND schema_id = SCHEMA_ID('etl'))
BEGIN
    DROP PROCEDURE etl.DropIndexesForTable
END
GO

CREATE PROCEDURE etl.DropIndexesForTable (
	@warehouseEntityId  INT             = NULL,
    @tableName          NVARCHAR(512)   = NULL,
    @excludeTable       NVARCHAR(512)   = NULL
    )
AS
BEGIN
    /*
    ***************************************************************************************************
    *   Step 1: Prepare Foreign Key Drop Script iteratively
    *   Step 2: Execute Script
    ***************************************************************************************************
    *
        begin tran
        EXEC etl.DropIndexesForTable
            @tableName = 'BillableTimeHasWorkingUserFact_2010_Jan'
        rollback tran

        begin tran
        EXEC etl.DropIndexesForTable
            @warehouseEntityId = 17
        rollback tran

        BillableTimeHasWorkingUserFact_2010_Jan	1579152671	NCI1_BillableTimeHasWorkingUserFact_2010_Jan
        BillableTimeHasWorkingUserFact_2010_Jan	1579152671	NCI0_BillableTimeHasWorkingUserFact_2010_Jan

        begin tran
        EXEC etl.DropIndexesForTable
            @warehouseEntityId = 17,
            @tableName = 'dbo.EntityManagedTypeFact_2009_Aug'
        rollback tran
    ***************************************************************************************************
    */

    SET NOCOUNT ON

    DECLARE @errorNumber        INT,
            @errorSeverity      INT,
            @errorState         INT,
            @errorLine          INT,
            @errorProcedure     NVARCHAR(256),
            @errorMessage       NVARCHAR(MAX),
            @task               NVARCHAR(512)

    DECLARE @IXScriptTemplate   NVARCHAR(MAX),
            @IXScript           NVARCHAR(MAX)

    BEGIN TRY
        SELECT  @task   = 'Input validation'
        IF(ISNULL(@warehouseEntityId, 0) = 0 AND OBJECT_ID(@tableName) IS NULL)
        BEGIN
		    RAISERROR('Invalid Input/s', 16, 1)
		    RETURN -1
        END

        SELECT  @task               = 'Init'
        SELECT  @IXScript           = '',
                @IXScriptTemplate   = 'IF EXISTS(SELECT * FROM sys.indexes WHERE name = ''%INDEXNAME%'') DROP INDEX [%INDEXNAME%] ON [%TABLENAME%]'

        SELECT      @task       = 'Preparing Index Drop script iteratively'
        SELECT      @IXScript   = @IXScript + CHAR(10) + REPLACE(REPLACE(@IXScriptTemplate, '%TABLENAME%', OBJECT_NAME(IX.object_id)), '%INDEXNAME%', IX.name)
        FROM        sys.indexes IX
        LEFT JOIN   etl.TablePartition tblPart ON
                    tblPart.EntityId = @warehouseEntityId
        WHERE       IX.object_id = CASE WHEN @warehouseEntityId IS NOT NULL THEN OBJECT_ID(tblPart.PartitionName) ELSE OBJECT_ID(@tableName) END
                -- this is to be able to exclude Partition created by RelationalDeployer OR the very first partition
                AND (@excludeTable IS NULL OR IX.object_id <> OBJECT_ID(@excludeTable))
                -- Primary keys will be dropped as part of PK Drop procedures.
                AND IX.is_primary_key = 0
                -- HEAPs always have no name
                AND IX.name IS NOT NULL

        PRINT   @IXScript

        SELECT  @task   = 'Executing Drop Index script'
        IF(@IXScript <> '')
        BEGIN
            EXEC (@IXScript)
        END

        RETURN 0;
     END TRY
    BEGIN CATCH
        DECLARE @errorFmt       VARCHAR(256)

        SELECT  @errorFmt       = N'ErrorNumber="%d" Message="%s" Severity="%d" State="%d" ProcedureName="%s" LineNumber="%d" Task="%s"',
                @errorNumber    = ERROR_NUMBER(),
                @errorMessage   = ERROR_MESSAGE(),
                @errorSeverity  = ERROR_SEVERITY(),
                @errorState     = ERROR_STATE(),
                @errorLine      = ERROR_LINE(),
                @errorProcedure = ERROR_PROCEDURE()

        RAISERROR (
            @errorFmt,
            18,
            @errorState,
            @errorNumber,
            @errorMessage,
            @errorSeverity,
            @errorState,
            @errorProcedure,
            @errorLine,
            @task
        )
        RETURN -1
    END CATCH
END
GO
IF EXISTS(SELECT 1 FROM sys.procedures WHERE name = 'DropNonNullConstraintForTable' AND schema_id = SCHEMA_ID('etl'))
BEGIN
    DROP PROCEDURE etl.DropNonNullConstraintForTable
END
GO

CREATE PROCEDURE etl.DropNonNullConstraintForTable (
	@warehouseEntityId  INT             = NULL,
    @tableName          NVARCHAR(512)   = NULL,
    @columnsList        XML             = NULL,
    @excludeTable       NVARCHAR(512)   = NULL
    )
AS
BEGIN
    /*
    ***************************************************************************************************
    *   Step 1: Prepare Temp1 table with a list of all Columns
    *   Step 2: Delete from Temp1 all Columns that do not exist in @columnsList
    *   Step 3: Prepare Alter Table script iteratively
    *   Step 4: Execute Script
    ***************************************************************************************************
    *
        begin tran
        EXEC etl.DropNonNullConstraintForTable
            @tableName = 'ComputerHostsPhysicalDiskFact_2009_Sep',
            @columnsList = '<root><col name="InsertedBatchId" /><col name="UpdatedBatchId" /></root>'
        rollback tran

        begin tran
        EXEC etl.DropNonNullConstraintForTable
            @warehouseEntityId = 17
        rollback tran

        begin tran
        EXEC etl.DropNonNullConstraintForTable
            @warehouseEntityId = 17,
            @tableName = 'dbo.EntityManagedTypeFact_2009_Aug'
        rollback tran
    ***************************************************************************************************
    */

    SET NOCOUNT ON

    DECLARE @errorNumber        INT,
            @errorSeverity      INT,
            @errorState         INT,
            @errorLine          INT,
            @errorProcedure     NVARCHAR(256),
            @errorMessage       NVARCHAR(MAX),
            @task               NVARCHAR(512)

    DECLARE @alterScriptTemplate   NVARCHAR(MAX),
            @alterScript           NVARCHAR(MAX)

    BEGIN TRY
        SELECT  @task   = 'Input validation'
        IF(ISNULL(@warehouseEntityId, 0) = 0 AND OBJECT_ID(@tableName) IS NULL)
        BEGIN
		    RAISERROR('Invalid Input/s', 16, 1)
		    RETURN -1
        END

        IF NOT EXISTS(SELECT colList.p.value('@name', 'NVARCHAR(512)') FROM @columnsList.nodes('/root/col') colList(p))
        BEGIN
            SET @columnsList = NULL
        END
        
        SELECT  @task                   = 'Init'
        SELECT  @alterScript            = '',
                @alterScriptTemplate    = 'ALTER TABLE %TABLENAME% ALTER COLUMN %COLUMNNAME% %COLUMNTYPE% NULL'

        SELECT      @task           = 'Preparing alter table script iteratively'
        SELECT      @alterScript    = @alterScript + CHAR(13) + REPLACE(REPLACE(REPLACE(@alterScriptTemplate, '%TABLENAME%', OBJECT_NAME(cols.object_id)), '%COLUMNNAME%', cols.name), '%COLUMNTYPE%', etl.GetColumnTypeDefinition(OBJECT_NAME(cols.object_id), cols.name))
        FROM        sys.columns cols
        LEFT JOIN   @columnsList.nodes('/root/col') colList(p) on
                    cols.name = colList.p.value('@name', 'NVARCHAR(512)')
        LEFT JOIN   etl.TablePartition tblPart ON
                    tblPart.EntityId = @warehouseEntityId
        WHERE       cols.object_id = CASE WHEN @warehouseEntityId IS NOT NULL THEN OBJECT_ID(tblPart.PartitionName) ELSE OBJECT_ID(@tableName) END
                AND cols.is_identity = 0
                AND cols.is_nullable = 0
                AND cols.is_computed = 0
                AND (@excludeTable IS NULL OR cols.object_id <> OBJECT_ID(@excludeTable)) -- this is to be able to exclude Partition created by RelationalDeployer
                AND (@columnsList IS NULL OR cols.name = colList.p.value('@name', 'NVARCHAR(512)'))

        PRINT   @alterScript

        SELECT  @task   = 'Executing FKScriptTemplate'
        IF(@alterScript <> '')
        BEGIN
            EXEC (@alterScript)
        END

        IF(OBJECT_ID('tempdb..#Temp1') IS NOT NULL) DROP TABLE #Temp1
        RETURN 0;
     END TRY
    BEGIN CATCH
        DECLARE @errorFmt       VARCHAR(256)

        SELECT  @errorFmt       = N'ErrorNumber="%d" Message="%s" Severity="%d" State="%d" ProcedureName="%s" LineNumber="%d" Task="%s"',
                @errorNumber    = ERROR_NUMBER(),
                @errorMessage   = ERROR_MESSAGE(),
                @errorSeverity  = ERROR_SEVERITY(),
                @errorState     = ERROR_STATE(),
                @errorLine      = ERROR_LINE(),
                @errorProcedure = ERROR_PROCEDURE()

        RAISERROR (
            @errorFmt,
            18,
            @errorState,
            @errorNumber,
            @errorMessage,
            @errorSeverity,
            @errorState,
            @errorProcedure,
            @errorLine,
            @task
        )

        IF(OBJECT_ID('tempdb..#Temp1') IS NOT NULL) DROP TABLE #Temp1
        RETURN -1
    END CATCH
END
GO
IF OBJECT_ID ( 'etl.UninstallPartition', 'P' ) IS NOT NULL
    DROP PROCEDURE etl.UninstallPartition
GO

CREATE PROCEDURE etl.UninstallPartition
	@entityGuid                 UNIQUEIDENTIFIER,
	@measuresInFact             XML                 = NULL,
	@partitionCreatedByDeployer VARCHAR(512)        = NULL
AS
BEGIN
SET NOCOUNT ON
    /*
    ************************************************************************************
    *
    *   Step 1: Drop FOREIGN KEYS
    *   Step 2: Drop PRIMARY KEYS
    *   Step 3: Make Measures NULLABLE
    *
        begin tran
        EXEC etl.UninstallPartition
            @entityGuid = '9B50AA2C-6632-3B79-8B44-1D041E8D78FA'
        rollback tran
    ************************************************************************************
    */

    SET NOCOUNT ON

    DECLARE @errorNumber        INT,
            @errorSeverity      INT,
            @errorState         INT,
            @errorLine          INT,
            @errorProcedure     NVARCHAR(256),
            @errorMessage       NVARCHAR(MAX),
            @task               NVARCHAR(512)

	DECLARE @warehouseEntityId  INT,
			@tempSQLScript      NVARCHAR(MAX),
			@partitionName      NVARCHAR(512),
			@partitionId        INT

    BEGIN TRY
        SELECT @task = 'Input validation'
	    IF (@entityGuid IS NULL)
	    BEGIN
		    RAISERROR('Invalid input specified; @entityGuid cannot be NULL.', 16, 1)
		    RETURN -1
	    END

        SELECT  @task = 'Init'
        SELECT  @partitionName = '',
                @partitionId = 0

        SELECT      @task = 'Obtaining WarehosueEntityId that corresponds to @entityGuid'
	    SELECT      @warehouseEntityId = WarehouseEntityId 
	    FROM        etl.WarehouseEntity e 
	    INNER JOIN  etl.WarehouseEntityType t ON (e.WarehouseEntityTypeId = t.WarehouseEntityTypeId)
	    WHERE       e.EntityGuid = @entityGuid
	        AND     t.WarehouseEntityTypeName = 'Fact'

	    IF (@warehouseEntityId IS NULL)
	    BEGIN
		    RAISERROR('WarehouseEntityId could not be found probably due to invalid @entityGuid specification.', 16, 1)
		    RETURN -1
	    END

        -- we do not want all the partitions to be uninstalled
        -- because in case the entity is RE-installed back, we should be able to
        -- recreate all the constraints and indexes
        IF(ISNULL(@partitionCreatedByDeployer, '') = '' OR NOT EXISTS(SELECT 'x' FROM etl.TablePartition WHERE PartitionName = @partitionCreatedByDeployer))
        BEGIN
            SET ROWCOUNT 1

            SELECT  @partitionCreatedByDeployer = PartitionName
            FROM    etl.TablePartition
            WHERE   EntityId = @warehouseEntityId
            ORDER BY ISNULL(RangeStartDate, 0)

            SET ROWCOUNT 0            
        END

        SELECT @task = 'Dropping Indexes'
        EXEC etl.DropIndexesForTable @warehouseEntityId = @warehouseEntityId, @excludeTable = @partitionCreatedByDeployer

        SELECT @task = 'Dropping Foreign Keys'
        EXEC etl.DropForeignKeysForTable @warehouseEntityId = @warehouseEntityId, @excludeTable = @partitionCreatedByDeployer

        SELECT @task = 'Dropping Primary Keys'
        EXEC etl.DropPrimaryKeyForTable @warehouseEntityId = @warehouseEntityId, @excludeTable = @partitionCreatedByDeployer

        SELECT @task = 'Dropping CHECK Constraints'
        EXEC etl.DropCheckConstraintForTable @warehouseEntityId = @warehouseEntityId, @excludeTable = @partitionCreatedByDeployer, @endTobeDropped = 'Both'

        SELECT @task = 'Dropping NOTNULL Constraints'
        EXEC etl.DropNonNullConstraintForTable @warehouseEntityId = @warehouseEntityId, @columnsList = @measuresInFact, @excludeTable = @partitionCreatedByDeployer

	    RETURN 0
    END TRY
    BEGIN CATCH
        DECLARE @errorFmt       VARCHAR(256)

        SELECT  @errorFmt       = N'ErrorNumber="%d" Message="%s" Severity="%d" State="%d" ProcedureName="%s" LineNumber="%d" Task="%s"',
                @errorNumber    = ERROR_NUMBER(),
                @errorMessage   = ERROR_MESSAGE(),
                @errorSeverity  = ERROR_SEVERITY(),
                @errorState     = ERROR_STATE(),
                @errorLine      = ERROR_LINE(),
                @errorProcedure = ERROR_PROCEDURE()

        RAISERROR (
            @errorFmt,
            18,
            @errorState,
            @errorNumber,
            @errorMessage,
            @errorSeverity,
            @errorState,
            @errorProcedure,
            @errorLine,
            @task
        )

        RETURN -1
    END CATCH
    
    SET XACT_ABORT OFF
    SET NOCOUNT OFF
    RETURN 0
END
GO

IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name = N'CollapseProperties')
BEGIN
    EXECUTE ('CREATE PROCEDURE [dbo].[CollapseProperties] AS RETURN 1')
END
GO

ALTER PROCEDURE [dbo].[CollapseProperties] (
    @transformName          VARCHAR(256),
    @transformTemplateType  VARCHAR(256),
    @sourceTableName        VARCHAR(256),
    @batchId                INT,
    @collapseProperties     BIT = 0
    )
AS BEGIN
SET NOCOUNT ON
SET XACT_ABORT ON

	declare @utc datetime = getutcdate()
	--print '1: ' + CONVERT(nvarchar(64), @utc, 109)

    IF(@collapseProperties = 0)
    BEGIN
        RETURN;
    END
--print '2'

    IF @transformTemplateType NOT IN (
        'ConcreteDimension',
        'AbstractDimension',
        'ConcreteSingleRelationshipFact',
        'AbstractSingleRelationshipFact'
    )
    BEGIN
        RETURN;
    END
--print '3'

    declare @quotedTableName sysname
    select @quotedTableName = REPLACE('DWTemp.%TRANSFORMNAME%_Source1', '%TRANSFORMNAME%', @transformName)

    declare @comma char(2) = '', @OR char(4) = ''
    declare @propertiesDeclares nvarchar(max) = ''
    declare @propertiesFlagsDeclares nvarchar(max) = ''

    declare @columnId int = 0, @columnName sysname = '', @flagColumnName sysname = ''
    declare @updatePropTemplate nvarchar(max) = '%PROPVAR% = %PROPCOLUMN% = CASE WHEN @nkey = NKey - 1 THEN CASE WHEN %FLAGPROPCOLUMN% = 0 THEN %PROPVAR% ELSE %PROPCOLUMN% END ELSE %PROPCOLUMN% END'
    declare @updateFlagPropTemplate nvarchar(max) = '%FLAGPROPVAR% = %FLAGPROPCOLUMN% = CASE WHEN @nkey = NKey - 1 THEN CASE WHEN %FLAGPROPVAR% = 1 THEN %FLAGPROPVAR% ELSE %FLAGPROPCOLUMN% END ELSE %FLAGPROPCOLUMN% END'
    declare @updateProp nvarchar(max) = ''
    declare @updateFlagProp nvarchar(max) = ''
    declare @propVar nvarchar(max) = '', @flagPropVar nvarchar(max) = ''
    declare @flagsCheck nvarchar(max) = ''

--print '4'
    while(1=1)
    begin
        select @columnName = ''
        select top 1 @columnId = column_id, @columnName = name, @flagColumnName = REPLACE(name, '!', '?'),
        @propVar = '@property' + CAST(column_id as varchar(32)), @flagPropVar = '@isProperty' + CAST(column_id as varchar(32))
        from sys.columns
        where object_id = OBJECT_ID(@quotedTableName)
        and column_id > @columnId
        and name like '%!%'
        order by column_id
--print '5'
        if(@columnName = '') break;

        select @propertiesDeclares = @propertiesDeclares + @comma + @propVar + ' ' + etl.GetColumnTypeDefinition(@quotedTableName, @columnName)
        select @propertiesFlagsDeclares = @propertiesFlagsDeclares + @comma + @flagPropVar + ' bit = 0'
        select @flagsCheck = @flagsCheck + @OR + '[' + @flagColumnName + '] = 0'

        --print @propVar + ' : ' + @columnName
        select @updateProp = @updateProp + @comma + REPLACE(REPLACE(REPLACE(@updatePropTemplate, '%PROPVAR%', @propVar), '%PROPCOLUMN%', '[' + @columnName + ']'), '%FLAGPROPCOLUMN%', '[' + @flagColumnName + ']')
        select @updateFlagProp = @updateFlagProp + @comma + REPLACE(REPLACE(REPLACE(@updateFlagPropTemplate, '%FLAGPROPVAR%', @flagPropVar), '%FLAGPROPCOLUMN%', '[' + @flagColumnName + ']'), '%FLAGPROPVAR%', @flagPropVar)

        select @comma = ', ', @OR = ' OR '
    end

    IF(@columnId = 0 OR isnull(@propertiesDeclares, '') = '') RETURN;

    declare @updateTemplate nvarchar(max) = N'
    DECLARE @nkey INT = 0
    DECLARE %PROPERTIESDECLARES%
    DECLARE %PROPERTIESFLAGSDECLARES%

    IF EXISTS(SELECT * FROM %TEMPTABLENAME% WHERE (%FLAGSPROPERTIESCHECK%))
    BEGIN
        UPDATE %TEMPTABLENAME% SET
        %SETPROPERTIES%,
        %SETPROPERTIESFLAGS%,
        @nkey = NKey
        OPTION (MAXDOP 1)
    END
    '

    select @updateTemplate = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@updateTemplate,
                                    '%PROPERTIESDECLARES%', @propertiesDeclares),
                                    '%PROPERTIESFLAGSDECLARES%', @propertiesFlagsDeclares),
                                    '%TEMPTABLENAME%', @quotedTableName),
                                    '%SETPROPERTIES%', @updateProp),
                                    '%SETPROPERTIESFLAGS%', @updateFlagProp),
                                    '%FLAGSPROPERTIESCHECK%', @flagsCheck)

	--select @utc = getutcdate()
	--print '2: ' + CONVERT(nvarchar(64), @utc, 109)

    --print @updateTemplate
    exec sp_executesql @updateTemplate

	--select @utc = getutcdate()
	--print '3: ' + CONVERT(nvarchar(64), @utc, 109)

--declare @t nvarchar(max) = 'select * into ' + @quotedTableName + '2 from ' + @quotedTableName
--exec(@t)

SET XACT_ABORT OFF
SET NOCOUNT OFF
END
GO
IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name = N'InitializeTransform')
BEGIN
    EXECUTE ('CREATE PROCEDURE [dbo].[InitializeTransform] AS RETURN 1')
END
GO

ALTER PROCEDURE [dbo].[InitializeTransform] (
    @transformName          VARCHAR(256),
    @transformTemplateType  VARCHAR(256),
    @waterMark              XML,
    @warehouseEntityName    VARCHAR(256),
    @waterMarkType          VARCHAR(32),
    @sourceTableName        VARCHAR(256),
    @utc                    DATETIME,
    @addColumnsWithDefVal   NVARCHAR(MAX) = NULL,
    @isOneToOneCardinality  BIT             = 1,
    @factGrain              VARCHAR(32)     = 'Daily',
    @propertiesList         NVARCHAR(MAX)   = NULL,
    @collapseProperties     BIT             = 0,
    @source1WM              DATETIME OUTPUT,
    @source1MaxWM           DATETIME OUTPUT,
    @batchId                INT OUTPUT
    )
AS BEGIN 
SET NOCOUNT ON 
SET XACT_ABORT ON

    DECLARE @errorNumber            INT,
            @errorSeverity          INT,
            @errorState             INT,
            @errorLine              INT,
            @errorProcedure         NVARCHAR(256),
            @errorMessage           NVARCHAR(MAX),
            @task                   NVARCHAR(512)

    DECLARE @retval                 INT             = -1,
            @err                    INT             = 0,
            @tempName1              VARCHAR(256)    = '',
            @tempName2              VARCHAR(256)    = '',
            @tempScript1            VARCHAR(MAX)    = '',
            @tempScript2            VARCHAR(MAX)    = '',
            @createTempSources      BIT             = 0

    DECLARE @dropTableTemplate      VARCHAR(MAX)    = 'DROP TABLE DWTemp.%TEMPTABLENAME%',
            @sourceTableTemplate    VARCHAR(MAX)    = 'SELECT IDENTITY(INT, 1, 1) AS DWId, CAST(NULL AS INT) AS DKey, CAST(NULL AS INT) AS NKey, * %ADDITIONALCOLUMNS% INTO DWTemp.%TEMPTABLENAME% FROM %SOURCETABLENAME% WHERE 1 = 2',
            @createIndexTemplate    VARCHAR(MAX)    = 'CREATE %CLUSTERINGTYPE% INDEX %INDEXNAME% ON DWTemp.%TEMPTABLENAME%(%COLUMNS%) %INCLUDECOLUMNS%'

    SELECT @task = 'Attempting to acquire applock'
    EXEC @retval = sp_getapplock
                        @Resource = @transformName,
                        @LockMode = 'Exclusive',
                        @LockOwner = 'Session',
                        @LockTimeout = 0,
                        @DbPrincipal = 'public'

    IF(@retval < 0)
    BEGIN
        RAISERROR ('Unable to acquire applock - another instance of the module must already be running.', 18, 1);
    END

    /*
    ***********************************************************************************
    * Shred watermark if this is the first time we are being called
    ***********************************************************************************
    */
    SELECT  @task = 'Reading WaterMark for @source1WM and @BatchId'
    IF(@source1WM IS NULL) -- first time being called
    BEGIN
        SELECT  @source1WM = WaterMark,
                @batchId = BatchId
        FROM    etl.ShredWaterMark(@waterMark)
        WHERE   WarehouseEntityName = @warehouseEntityName
            AND WaterMarkType = @waterMarkType
    END

    SELECT  @source1MaxWM = @utc,
            @addColumnsWithDefVal = CASE WHEN ISNULL(@addColumnsWithDefVal, '') = '' THEN '' ELSE ', ' + @addColumnsWithDefVal END

    /*
    ************************************************************************************************
    * Drop and Re-Create %TRANSFORMNAME%_Source1 table
    ************************************************************************************************
    */
    SELECT @tempName1 = REPLACE('%TRANSFORMNAME%_Source1', '%TRANSFORMNAME%', @transformName)

    IF EXISTS (SELECT 'x' FROM sys.tables WHERE name = @tempName1)
    BEGIN
        SELECT @tempScript1 = REPLACE(@dropTableTemplate, '%TEMPTABLENAME%', @tempName1)
        EXEC (@tempScript1)
    END -- drop existing temp table

    -- DDL for Transform_Source1 table
    SELECT @tempScript1 = REPLACE(REPLACE(REPLACE(@sourceTableTemplate,
                                    '%TEMPTABLENAME%', @tempName1),
                                    '%SOURCETABLENAME%', @sourceTableName),
                                    '%ADDITIONALCOLUMNS%', @addColumnsWithDefVal)
    EXEC(@tempScript1)

    /*
    ************************************************************************************************
    * Create Indicies on the %TRANSFORMNAME%_Source1 table
    ************************************************************************************************
    */
    -- DDL for Clustered Index on Transform_Source1
    SELECT @tempName2 = REPLACE('[CI1_%TEMPTABLENAME%]', '%TEMPTABLENAME%', @tempName1)

    DECLARE @indexColumns NVARCHAR(MAX) = 'DKey, NKey'
    --IF(@transformTemplateType IN ('ConcreteSingleRelationshipFact', 'AbstractSingleRelationshipFact'))
    --BEGIN
    --    SELECT @indexColumns = 'DatasourceId, RelationshipTypeId, RelationshipId, SourceTypeId, TargetTypeId, LastModified'
    --END

    --IF(@transformTemplateType IN ('ConcreteDimension', 'AbstractDimension'))
    --BEGIN
    --    SELECT @indexColumns = 'DatasourceId, BaseManagedEntityId, LastModified'
    --END

    SELECT @tempScript1 = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@createIndexTemplate,
                                '%CLUSTERINGTYPE%', 'CLUSTERED'),
                                '%INDEXNAME%', @tempName2),
                                '%TEMPTABLENAME%', @tempName1),
                                '%COLUMNS%', @indexColumns),
                                '%INCLUDECOLUMNS%', '')
    EXEC(@tempScript1)

    IF((SELECT COUNT(*) FROM sys.columns WHERE object_id = OBJECT_ID('DWTemp.' + @tempName1) AND name IN ('DatasourceId', 'BaseManagedEntityId', 'LastModified')) = 3)
    BEGIN
        -- DDL for non-clustered index1 on Transform_Source1
        SELECT @tempName2 = REPLACE('[NCI1_%TEMPTABLENAME%]', '%TEMPTABLENAME%', @tempName1)
        SELECT @tempScript1 = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@createIndexTemplate,
                                    '%CLUSTERINGTYPE%', 'NONCLUSTERED'),
                                    '%INDEXNAME%', @tempName2),
                                    '%TEMPTABLENAME%', @tempName1),
                                    '%COLUMNS%', 'DatasourceId, BaseManagedEntityId, LastModified'),
                                    '%INCLUDECOLUMNS%', '')
        EXEC(@tempScript1)
    END

    IF @transformTemplateType NOT IN (
        'ConcreteDimension',
        'AbstractDimension',
        'ConcreteSingleRelationshipFact',
        'AbstractSingleRelationshipFact'
    )
    BEGIN
        RETURN;
    END

    /*
    ***************************************************************************************************
    * Now invoke template specific Init procedure, if present
    ***************************************************************************************************
    */
    IF @transformTemplateType IN ('ConcreteSingleRelationshipFact', 'AbstractSingleRelationshipFact')
    BEGIN
        EXEC [dbo].[InitializeSingleRelationshipFactTransform]
            @transformName          = @transformName,
            @transformTemplateType  = @transformTemplateType,
            @sourceTableName        = @sourceTableName,
            @utc                    = @utc,
            @isOneToOneCardinality  = @isOneToOneCardinality,
            @factGrain              = @factGrain,
            @propertiesList         = @propertiesList
    END
    /**************************************************************************************************/

SET XACT_ABORT OFF
SET NOCOUNT OFF
END
GO
IF NOT EXISTS (SELECT * FROM sysobjects WHERE type = 'P' AND name = N'UninitializeTransform')
BEGIN
    EXECUTE ('CREATE PROCEDURE [dbo].[UninitializeTransform] @WaterMark xml AS RETURN 1')
END
GO

ALTER PROCEDURE [dbo].[UninitializeTransform] (
    @transformName          VARCHAR(256),
    @transformTemplateType  VARCHAR(256),
    @waterMark              XML,
    @warehouseEntityName    VARCHAR(256),
    @waterMarkType          VARCHAR(32),
    @source1MaxWM           DATETIME,
    @batchId                INT,
    @inserted               INT,
    @updated                INT
    )
AS BEGIN
SET NOCOUNT ON
SET XACT_ABORT ON

    DECLARE @retval                 INT             = -1,
            @err                    INT             = 0,
            @tempName1              VARCHAR(256)    = '',
            @tempName2              VARCHAR(256)    = '',
            @tempScript1            VARCHAR(MAX)    = '',
            @tempScript2            VARCHAR(MAX)    = ''

    DECLARE @dropTableTemplate      VARCHAR(MAX)    = 'DROP TABLE DWTemp.%TABLENAME%'

    /*
    ************************************************************************************************
    * Drop %TRANSFORMNAME%_Source1 table
    ************************************************************************************************
    */
    SELECT @tempName1 = REPLACE('%TRANSFORMNAME%_Source1', '%TRANSFORMNAME%', @transformName)

    IF EXISTS (SELECT 'x' FROM sys.tables WHERE name = @tempName1)
    BEGIN
        SELECT @tempScript1 = REPLACE(@dropTableTemplate, '%TABLENAME%', @tempName1)
        EXEC (@tempScript1)
    END -- drop existing temp table

    SELECT @tempName1 = REPLACE('%TRANSFORMNAME%_Source2', '%TRANSFORMNAME%', @transformName)

    IF EXISTS (SELECT 'x' FROM sys.tables WHERE name = @tempName1)
    BEGIN
        SELECT @tempScript1 = REPLACE(@dropTableTemplate, '%TABLENAME%', @tempName1)
        EXEC (@tempScript1)
    END -- drop existing temp table

    IF @transformTemplateType IN ('ConcreteSingleRelationshipFact', 'AbstractSingleRelationshipFact')
    BEGIN
        EXEC [dbo].[UninitializeSingleRelationshipFactTransform]
            @transformName          = @transformName,
            @waterMark              = @waterMark,
            @warehouseEntityName    = @warehouseEntityName,
            @waterMarkType          = @waterMarkType,
            @source1MaxWM           = @source1MaxWM,
            @batchId                = @batchId,
            @inserted               = @inserted,
            @updated                = @updated
    END

    /*
    ************************************************************************************************
    * Recompute watermark
    ************************************************************************************************
    */
    SELECT  *
    INTO    #tempTable
    FROM    etl.ShredWaterMark(@WaterMark)

    UPDATE  #tempTable SET
            WaterMark = CONVERT(nvarchar(64), ISNULL(@source1MaxWM, WaterMark), 109)
    WHERE   WaterMarkType = @waterMarkType
--        AND WarehouseEntityName = @warehouseEntityName -- commenting this out to support TxEMTFact manual sproc
                                                         -- which has two data sources (BME and TME)

    SELECT @WaterMark =
        (SELECT ModuleName AS "@ModuleName", ProcessName AS "@ProcessName", @BatchId AS "@BatchId",
        (SELECT DISTINCT WarehouseEntityName AS "@WarehouseEntityName", WarehouseEntityTypeName AS "@WarehouseEntityTypeName", EntityGuid AS "@EntityGuid",
            CASE WarehouseEntityTypeName WHEN 'Inbound' THEN 'DateTime' WHEN 'Enumeration' THEN 'DateTime' ELSE 'BatchId' END AS "@WaterMarkType",
            CASE WarehouseEntityTypeName WHEN 'Inbound' THEN CONVERT(nvarchar(64), WaterMark, 109) WHEN 'Enumeration' THEN CONVERT(nvarchar(64), WaterMark, 109) ELSE CAST(@BatchId AS nvarchar(64)) END AS "@WaterMark"
            FROM #tempTable
            FOR xml path('Entity'),type)
        FROM (SELECT DISTINCT ModuleName, ProcessName FROM #tempTable) a
        FOR xml path('Module'),type)

    SELECT @WaterMark AS WaterMark, @BatchId AS BatchId, @updated AS UpdatedRowCount, @inserted AS InsertedRowCount

    IF OBJECT_ID('Tempdb..#tempTable') IS NOT NULL DROP TABLE #tempTable

    --
    -- Release applock acquired in InitializeTransform sproc
    --
    EXEC sp_releaseapplock
            @Resource = @transformName,
            @LockOwner = 'Session',
            @DbPrincipal = 'public'

SET XACT_ABORT OFF
SET NOCOUNT OFF
END
GO

IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name = N'InitializeTransformLoop')
BEGIN
    EXECUTE ('CREATE PROCEDURE [dbo].[InitializeTransformLoop] AS RETURN 1')
END
GO

ALTER PROCEDURE [dbo].[InitializeTransformLoop] (
    @transformName          VARCHAR(256),
    @transformTemplateType  VARCHAR(256),
    @sourceTableName        VARCHAR(256),
    @utc                    DATETIME,
    @addColumnsWithDefVal   NVARCHAR(MAX) = NULL,
    @targetClassCheck       NVARCHAR(MAX) = '',
    @batchId                INT,
    @collapseProperties     BIT = 0,
    @source1WM              DATETIME OUTPUT,
    @source1MaxWM           DATETIME OUTPUT,
    @rowsToProcess          INT OUTPUT,
    @loopCount              INT OUTPUT
    )
AS BEGIN
SET NOCOUNT ON
SET XACT_ABORT ON

    DECLARE @errorNumber            INT,
            @errorSeverity          INT,
            @errorState             INT,
            @errorLine              INT,
            @errorProcedure         NVARCHAR(256),
            @errorMessage           NVARCHAR(MAX),
            @task                   NVARCHAR(512),
            @startTranCount         INT = @@TRANCOUNT

    DECLARE @retval                 INT             = -1,
            @err                    INT             = 0,
            @source1Name            VARCHAR(256)    = 'DWTemp.' + @transformName + '_Source1',
            @tempName1              VARCHAR(256)    = '',
            @tempName2              VARCHAR(256)    = '',
            @tempScript1            NVARCHAR(MAX)   = '',
            @tempScript2            NVARCHAR(MAX)   = '',
            @scriptForAbstractTypes NVARCHAR(MAX)   = '',
            @batchSize              INT,
            @abstractTypeId         UNIQUEIDENTIFIER,
            @isAbstractType         BIT             = 0

    BEGIN TRY
        SELECT  @batchSize              = CAST(COALESCE(
                                            etl.GetConfigurationInfo('etl.Transform.' + @transformName, 'BatchSize'),
                                            etl.GetConfigurationInfo('etl.Transform.' + @transformTemplateType, 'BatchSize'),
                                            etl.GetConfigurationInfo('etl.Transform', 'BatchSize'),
                                            '50000') -- default to 50,000 rows
                                        AS INT)

        /*
        ***********************************************************************************
        * Increment loop count
        ***********************************************************************************
        */
        SELECT  @loopCount = ISNULL(@loopCount, 0) + 1,
                @addColumnsWithDefVal = CASE WHEN ISNULL(@addColumnsWithDefVal, '') = '' THEN '' ELSE ', ' + @addColumnsWithDefVal END

        -- if it is the first iteration, then retain the value from Watermark xml
        -- else, move the min to the max of the previous loop
        -- and then udpate the max to a new max
        IF(@loopCount > 1) SELECT @source1WM = @source1MaxWM
        SELECT @source1MaxWM = @utc

        /*
        ***********************************************************************************
        * Transfer a batch of rows from inbound source to temp source1
        ***********************************************************************************
        */
        SELECT @task = 'Truncating source1 table'
        SELECT @tempScript1 = 'TRUNCATE TABLE ' + @source1Name
        EXEC(@tempScript1)

        SELECT @task = 'Transferring Inbound to Temp Source'
        SELECT @tempScript1 = '
        INSERT INTO %TEMPTABLENAME%
        SELECT TOP (@batchSize) WITH TIES NULL AS DKey, NULL AS NKey, * %ADDITIONALCOLUMNS%
        FROM    %sourceTable% AS source
        WHERE   source.DWTimestamp >= @source1WM
            AND source.DWTimestamp < @source1MaxWM
            %targetClassCheck%
        ORDER BY DWTimeStamp
        '

        IF @transformTemplateType IN ('ConcreteDimension', 'AbstractDimension')
        BEGIN
        SELECT @tempScript1 = '
        INSERT INTO %TEMPTABLENAME%
        SELECT ROW_NUMBER() OVER(ORDER BY DatasourceId, BaseManagedEntityId, LastModified) AS DKey,
            ROW_NUMBER() OVER(PARTITION BY DatasourceId, BaseManagedEntityId ORDER BY LastModified) AS NKey, * %ADDITIONALCOLUMNS%
        FROM
        (   SELECT TOP (@batchSize) WITH TIES *
            FROM    %sourceTable% AS source
            WHERE   source.DWTimestamp >= @source1WM
                AND source.DWTimestamp < @source1MaxWM
                %targetClassCheck%
            ORDER BY DWTimeStamp
        ) AS A
        '
        END

        -- TODO: pass an explicit flag instead of deducing this here
        IF (@transformTemplateType IN ('ConcreteDimension', 'StateTransition') AND @collapseProperties = 0)
        BEGIN
            SELECT @abstractTypeId = ManagedTypeId
            FROM Staging.ManagedType
            WHERE 'inbound.' + Staging.fn_DeterministicObjectName(N'MTV_', TypeName) = @sourceTableName
                AND IsAbstract = 1

            IF(@abstractTypeId IS NOT NULL)
                SET @isAbstractType = 1
        END

        IF(@isAbstractType = 1)
        BEGIN
            SELECT @tempScript1 = ''
            EXEC Staging.p_GetSelectQueryForAbstractType @abstractTypeId, @tempScript1 OUTPUT

            SELECT @tempScript1 = '
            INSERT INTO %TEMPTABLENAME%
            SELECT ROW_NUMBER() OVER(ORDER BY DatasourceId, BaseManagedEntityId, LastModified) AS DKey,
                ROW_NUMBER() OVER(PARTITION BY DatasourceId, BaseManagedEntityId ORDER BY LastModified) AS NKey, * %ADDITIONALCOLUMNS%
            FROM
            (' + @tempScript1 + ') AS A'

            SELECT @scriptForAbstractTypes = REPLACE(REPLACE(REPLACE(REPLACE(@tempScript1,
                                                            '%BATCHSIZE%', ''), -- read everything
                                                            '%WHERECLAUSE%', 'WHERE   source.DWTimestamp >= @source1WM AND source.DWTimestamp < @source1MaxWM %targetClassCheck%'),
                                                            '%ORDERBYCLAUSE%', ''),
                                                            '%ADDITIONALCOLUMNS%', @addColumnsWithDefVal)

            SELECT @tempScript1 = REPLACE(REPLACE(REPLACE(REPLACE(@tempScript1,
                                                            '%BATCHSIZE%', 'TOP ' + CAST(@batchSize as varchar(32)) + ' WITH TIES '),
                                                            '%WHERECLAUSE%', 'WHERE   source.DWTimestamp >= @source1WM AND source.DWTimestamp < @source1MaxWM %targetClassCheck%'),
                                                            '%ORDERBYCLAUSE%', 'ORDER BY DWTimeStamp'),
                                                            '%ADDITIONALCOLUMNS%', @addColumnsWithDefVal)
            --PRINT @tempScript1
        END

        IF @transformTemplateType IN ('ConcreteSingleRelationshipFact', 'AbstractSingleRelationshipFact')
        BEGIN
        SELECT @tempScript1 = '
        INSERT INTO %TEMPTABLENAME%
        SELECT ROW_NUMBER() OVER(ORDER BY DatasourceId, RelationshipTypeId, RelationshipId, SourceTypeId, TargetTypeId, LastModified) AS DKey,
            ROW_NUMBER() OVER(PARTITION BY DatasourceId, RelationshipTypeId, RelationshipId, SourceTypeId, TargetTypeId ORDER BY LastModified) AS NKey, * %ADDITIONALCOLUMNS%
        FROM
        (
            SELECT TOP (@batchSize) WITH TIES *
            FROM    %sourceTable% AS source
            WHERE   source.DWTimestamp >= @source1WM
                AND source.DWTimestamp < @source1MaxWM
                %targetClassCheck%
            ORDER BY DWTimeStamp
        ) AS A
        '
        END

        SELECT @tempScript1 = REPLACE(REPLACE(REPLACE(REPLACE(@tempScript1,
                                    '%TEMPTABLENAME%', @source1Name),
                                    '%sourceTable%', @sourceTableName),
                                    '%targetClassCheck%', @targetClassCheck),
                                    '%ADDITIONALCOLUMNS%', @addColumnsWithDefVal)

        SELECT @scriptForAbstractTypes = REPLACE(REPLACE(REPLACE(REPLACE(@scriptForAbstractTypes,
                                    '%TEMPTABLENAME%', @source1Name),
                                    '%sourceTable%', @sourceTableName),
                                    '%targetClassCheck%', @targetClassCheck),
                                    '%ADDITIONALCOLUMNS%', @addColumnsWithDefVal)

        SELECT @tempScript2 = '@batchSize INT, @source1WM DATETIME, @source1MaxWM DATETIME'

        SELECT @rowsToProcess = 0

        IF OBJECT_ID(@sourceTableName) IS NOT NULL
        BEGIN
            EXEC sp_executesql
                    @statement      = @tempScript1,
                    @params         = @tempScript2,
                    @batchSize      = @batchSize,
                    @source1WM      = @source1WM,
                    @source1MaxWM   = @source1MaxWM

            SELECT @rowsToProcess = @@ROWCOUNT

            -- FOR PS BUG: 237337
            -- Re-run the read query, only this time, with no limit on the batch size
            -- IE, all rows are read into the team without regard to the batchsize
            -- the WHERE clause still applies: (>= minWM AND < maxWM)
            -- Any concerns about perf impact should be rest assured that this code path
            -- will be executed only in an exceptional scenario
            -- when at least two physical types under the abstract view will have more than
            -- the batchsize (default: 50000) number of rows that match the WHERE clause.
            IF(@rowsToProcess > 2 * @batchSize AND @isAbstractType = 1)
            BEGIN
                SELECT @tempScript1 = 'TRUNCATE TABLE ' + @source1Name
                EXEC(@tempScript1)

                SELECT @rowsToProcess = 0

                EXEC sp_executesql
                        @statement      = @scriptForAbstractTypes,
                        @params         = @tempScript2,
                        @batchSize      = @batchSize,
                        @source1WM      = @source1WM,
                        @source1MaxWM   = @source1MaxWM

                SELECT @rowsToProcess = @@ROWCOUNT
            END
        END

        EXEC [dbo].[CollapseProperties] 
            @transformName          = @transformName,
            @transformTemplateType  = @transformTemplateType,
            @sourceTableName        = @sourceTableName,
            @batchId                = @batchId,
            @collapseProperties     = @collapseProperties

        /*
        ***********************************************************************************
        * Computer Max watermark as shown below
        *
            SELECT @source1MaxWM = (    SELECT MIN(DWTimestamp)
                                        FROM inbound.BaseManagedEntity
                                        WHERE DWTimeStamp > (SELECT MAX(DWTimeStamp) FROM #transformTemp0))

          Note: for Abstract Types we need to compute the Max watermark
          directly from the underlying physical tables in order to avoid a table scan.
        ***********************************************************************************
        */
        SELECT @tempScript1 = '
            DECLARE @t DATETIME = (SELECT MAX(DWTimeStamp) FROM %TEMPTABLENAME%)
            SELECT @source1MaxWM = (    SELECT MIN(DWTimestamp)
                                        FROM %sourceTable%
                                        WHERE DWTimeStamp > @t)
        '

        IF(@isAbstractType = 1)
        BEGIN
            SELECT @tempScript1 = ''
            EXEC Staging.p_GetMaxWMQueryForAbstractType @abstractTypeId, @tempScript1 OUTPUT

            SELECT @tempScript1 = '
                DECLARE @t DATETIME = (SELECT MAX(DWTimeStamp) FROM %TEMPTABLENAME%)
                SELECT @source1MaxWM = (    SELECT MIN(DWTimestamp)
                                            FROM (' + @tempScript1 + ') AS A)'
        END

        SELECT @tempScript1 = REPLACE(REPLACE(REPLACE(@tempScript1,
                                    '%sourceTable%', @sourceTableName),
                                    '%TEMPTABLENAME%', @source1Name),
                                    '%WHERECLAUSE%', 'WHERE source.DWTimestamp > @t')

        SELECT @tempScript2 = '@source1MaxWM DATETIME OUTPUT'

        EXEC sp_executesql
                @statement      = @tempScript1,
                @params         = @tempScript2,
                @source1MaxWM   = @source1MaxWM OUTPUT

        SELECT @source1MaxWM = ISNULL(@source1MaxWM, @utc)

        /*
        ***********************************************************************************
        * Infer datasource
        ***********************************************************************************
        */
        SELECT @task = 'Infer DatasourceDim'
        EXEC @err = dbo.InferDatasourceDimProc
            @sourceTableName    = @source1Name,
            @columnName         = 'DataSourceId',
            @filterColumnName   = 'DWTimeStamp',
            @minTimeStamp       = @source1WM,
            @maxTimeStamp       = @source1MaxWM,
            @batchId            = @batchId

    END TRY
    BEGIN CATCH
    DECLARE @errorFmt       VARCHAR(256)

    SELECT  @errorFmt = N'ErrorNumber="%d" Message="%s" Severity="%d" State="%d" ProcedureName="%s" LineNumber="%d" Task="%s"',
            @errorNumber = ERROR_NUMBER(), @errorMessage = ERROR_MESSAGE(), @errorSeverity = ERROR_SEVERITY(), @errorState = ERROR_STATE(), @errorLine = ERROR_LINE(), @errorProcedure = ERROR_PROCEDURE() 

    IF(@@TRANCOUNT > @startTranCount) ROLLBACK TRANSACTION
    
    RAISERROR (@errorFmt, 18, @errorState, @errorNumber, @errorMessage, @errorSeverity, @errorState, @errorProcedure, @errorLine, @task)
    RETURN -1
    END CATCH

SET XACT_ABORT OFF
SET NOCOUNT OFF
END
GO
IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name = N'UninitializeTransformLoop')
BEGIN
    EXECUTE ('CREATE PROCEDURE [dbo].[UninitializeTransformLoop] AS RETURN 1')
END
GO

ALTER PROCEDURE [dbo].[UninitializeTransformLoop] (
    @transformName          VARCHAR(256),
    @transformTemplateType  VARCHAR(256),
    @utc                    DATETIME,
    @inserted               INT,
    @updated                INT,
    @loopCount              INT,
    @canContinue            BIT OUTPUT
    )
AS BEGIN 
SET NOCOUNT ON 
SET XACT_ABORT ON

    DECLARE @now                    DATETIME = GETUTCDATE(),
            @executionTimeLimit     INT

    SELECT  @executionTimeLimit     = CAST(COALESCE(
                                        etl.GetConfigurationInfo('etl.Transform.' + @transformName, 'ExecutionTimeLimit'),
                                        etl.GetConfigurationInfo('etl.Transform.' + @transformTemplateType, 'ExecutionTimeLimit'),
                                        etl.GetConfigurationInfo('etl.Transform', 'ExecutionTimeLimit'),
                                        '30') -- default to 30 seconds
                                    AS INT)

    SELECT @canContinue = 0
    IF (DATEDIFF(SS, @utc, @now) < @executionTimeLimit
        AND (@inserted > 0 OR @updated > 0)
        AND (@loopCount < 10) -- circuit breaker
    )
        SELECT @canContinue = 1

SET XACT_ABORT OFF
SET NOCOUNT OFF
END
GO
IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name = N'InitializeSingleRelationshipFactTransform')
BEGIN
    EXECUTE ('CREATE PROCEDURE [dbo].[InitializeSingleRelationshipFactTransform] AS RETURN 1')
END
GO

ALTER PROCEDURE [dbo].[InitializeSingleRelationshipFactTransform] (
    @transformName          VARCHAR(256),
    @transformTemplateType  VARCHAR(256),
    @sourceTableName        VARCHAR(256),
    @utc                    DATETIME,

    -- SingleRelationshipFactTransform
    @isOneToOneCardinality  BIT = 0,
    @factGrain              VARCHAR(32) = 'Hourly',
    @propertiesList    NVARCHAR(MAX) = NULL
    )
AS BEGIN 
SET NOCOUNT ON 
SET XACT_ABORT ON

    DECLARE @errorNumber            INT,
            @errorSeverity          INT,
            @errorState             INT,
            @errorLine              INT,
            @errorProcedure         NVARCHAR(256),
            @errorMessage           NVARCHAR(MAX),
            @task                   NVARCHAR(512)

    DECLARE @retval                 INT             = -1,
            @err                    INT             = 0,
            @tempName1              VARCHAR(256)    = '',
            @tempName2              VARCHAR(256)    = '',
            @tempScript1            VARCHAR(MAX)    = '',
            @tempScript2            VARCHAR(MAX)    = ''

    DECLARE @dropTableTemplate      VARCHAR(MAX)    = 'DROP TABLE DWTemp.%TEMPTABLENAME%',
            @createIndexTemplate    VARCHAR(MAX)    = 'CREATE %CLUSTERINGTYPE% INDEX [%INDEXNAME%] ON DWTemp.%TEMPTABLENAME%(%COLUMNS%) %INCLUDECOLUMNS%',
            @sourceTableTemplate    VARCHAR(MAX)    = '
            SELECT
                IDENTITY(int, 1, 1) AS DWId,
                CAST(NULL AS DATETIME) AS CreatedDate,
                CAST(NULL AS DATETIME) AS DeletedDate,
                CAST(NULL AS INT) AS SourceEntityKey,
                CAST(NULL AS INT) AS TargetEntityKey,
                %PROPERTIES%
                %SOURCETABLEBIT%
                CAST(NULL AS INT) AS DateKey,
                CAST(NULL AS INT) AS HourId,
                CAST(NULL AS BIT) AS IsFollowupRelationshipPresent,
                CAST(NULL AS DATETIME) AS LastModified,
                CAST(NULL AS INT) AS SourceEDKey,
                CAST(NULL AS INT) AS TargetEDKey,
                CAST(NULL AS INT) AS RelTypeKey
            INTO DWTemp.%TEMPTABLENAME%
            FROM DWTemp.%TRANSFORMNAME%_Source1 AS source
            WHERE 1 = 2'

    set @propertiesList = NULLIF(@propertiesList, '')

    /*
    ************************************************************************************************
    * Drop and Re-Create %TRANSFORMNAME%_Source2 table
    ************************************************************************************************
    */
    SELECT @tempName1 = REPLACE('%TRANSFORMNAME%_Source2', '%TRANSFORMNAME%', @transformName)

    IF EXISTS (SELECT 'x' FROM sys.tables WHERE name = @tempName1)
    BEGIN
        SELECT @tempScript1 = REPLACE(@dropTableTemplate, '%TEMPTABLENAME%', @tempName1)
        EXEC (@tempScript1)
    END -- drop existing temp table

    -- DDL for Transform_Source2 table
    SELECT @tempScript1 = REPLACE(REPLACE(REPLACE(REPLACE(@sourceTableTemplate,
                                '%TEMPTABLENAME%', @tempName1),
                                '%TRANSFORMNAME%', @transformName),
                                '%PROPERTIES%', CASE WHEN @propertiesList IS NULL THEN '' ELSE @propertiesList END),
                                '%SOURCETABLEBIT%', CASE WHEN @propertiesList IS NULL THEN '' ELSE 'CAST(NULL AS INT) AS  SourceTable,' END)
    EXEC(@tempScript1)

    /*
    ************************************************************************************************
    * Create Indicies on the %TRANSFORMNAME%_Source2 table
    ************************************************************************************************
    */
    -- DDL for Clustered Index on Transform_Source2
    SELECT @tempName2 = REPLACE('CI1_%TEMPTABLENAME%', '%TEMPTABLENAME%', @tempName1)
    SELECT @tempScript1 = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@createIndexTemplate,
                                '%CLUSTERINGTYPE%', 'CLUSTERED'),
                                '%INDEXNAME%', @tempName2),
                                '%TEMPTABLENAME%', @tempName1),
                                '%COLUMNS%', 'DWId'),
                                '%INCLUDECOLUMNS%', '')
    EXEC(@tempScript1)

    -- index1
    SELECT @tempName2 = REPLACE('NCI1_%TEMPTABLENAME%', '%TEMPTABLENAME%', @tempName1)
    SELECT @tempScript1 = REPLACE(REPLACE(REPLACE(REPLACE('CREATE NONCLUSTERED INDEX [%INDEXNAME%] ON DWTemp.%TEMPTABLENAME%(SourceEntityKey %, N_CARDINALITYTARGETKEY%, CreatedDate, DeletedDate %SourceTableFlag%)',
                        '%INDEXNAME%', @tempName2),
                        '%TEMPTABLENAME%', @tempName1),
                        '%, N_CARDINALITYTARGETKEY%', CASE WHEN @isOneToOneCardinality = 1 THEN '' ELSE ', TargetEntityKey' END),
                        '%SourceTableFlag%', CASE WHEN @propertiesList IS NULL THEN '' ELSE ',SourceTable' END )
    EXEC(@tempScript1)

    -- index 2
    SELECT @tempName2 = REPLACE('NCI2_%TEMPTABLENAME%', '%TEMPTABLENAME%', @tempName1)
    SELECT @tempScript1 = REPLACE(REPLACE(REPLACE('CREATE NONCLUSTERED INDEX [%INDEXNAME%] ON DWTemp.%TEMPTABLENAME%(DateKey, %hourId% SourceEntityKey, TargetEntityKey, CreatedDate, DeletedDate)',
                         '%INDEXNAME%', @tempName2),
                         '%TEMPTABLENAME%', @tempName1),
                         '%hourId%', CASE WHEN @factGrain = 'Hourly' THEN 'HourId,' ELSE '' END)
    EXEC(@tempScript1)

    /*
    ************************************************************************************************
    * Drop and Re-Create %TRANSFORMNAME%_TempOneAndHalf table
    ************************************************************************************************
    */
    SELECT @tempName1 = REPLACE('%TRANSFORMNAME%_TempOneAndHalf', '%TRANSFORMNAME%', @transformName)

    IF EXISTS (SELECT 'x' FROM sys.tables WHERE name = @tempName1)
    BEGIN
        SELECT @tempScript1 = REPLACE(@dropTableTemplate, '%TEMPTABLENAME%', @tempName1)
        EXEC (@tempScript1)
    END -- drop existing temp table

    SELECT @sourceTableTemplate = '
        CREATE TABLE DWTemp.%TEMPTABLENAME% (
            DWId INT NOT NULL,
            SourceEntityKey INT,
            %TargetEntityKey%
            CreatedDate DATETIME
        )'

    -- DDL for Transform_Source2 table
    SELECT @tempScript1 = REPLACE(REPLACE(@sourceTableTemplate,
                                '%TEMPTABLENAME%', @tempName1),
                                '%TargetEntityKey%', CASE WHEN @isOneToOneCardinality = 1 THEN '' ELSE 'TargetEntityKey INT,' END)
    EXEC(@tempScript1)

    /*
    ************************************************************************************************
    * Drop and Re-Create %TRANSFORMNAME%_Temp2 table
    ************************************************************************************************
    */
    SELECT @tempName1 = REPLACE('%TRANSFORMNAME%_Temp2', '%TRANSFORMNAME%', @transformName)

    IF EXISTS (SELECT 'x' FROM sys.tables WHERE name = @tempName1)
    BEGIN
        SELECT @tempScript1 = REPLACE(@dropTableTemplate, '%TEMPTABLENAME%', @tempName1)
        EXEC (@tempScript1)
    END -- drop existing temp table

    SELECT @sourceTableTemplate = '
        SELECT          
            CAST(NULL AS INT) AS DateKey,
            %hourId%
            CAST(NULL AS INT) AS SourceEntityKey,
            CAST(NULL AS INT) AS TargetEntityKey,
            %PROPERTIES%
            %SOURCETABLEBIT%
            CAST(NULL AS DATETIME) AS CreatedDate,
            CAST(NULL AS DATETIME) AS DeletedDate          
        INTO DWTemp.%TEMPTABLENAME%
        FROM DWTemp.%TRANSFORMNAME%_Source1 AS source
        WHERE 1 = 2'
        --CREATE TABLE DWTemp.%TEMPTABLENAME% (
        --    DateKey INT,
        --    %hourId%
        --    SourceEntityKey INT,
        --    TargetEntityKey INT,
        --    CreatedDate DATETIME,
        --    DeletedDate DATETIME
        --)'

    -- DDL for Transform_Temp2 table
     SELECT @tempScript1 = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@sourceTableTemplate,
                                '%TEMPTABLENAME%', @tempName1),
                                '%TRANSFORMNAME%', @transformName),
                                '%hourId%', CASE WHEN @factGrain = 'Hourly' THEN 'CAST(NULL AS INT) AS HourId,' ELSE '' END),
                                '%PROPERTIES%', CASE WHEN @propertiesList IS NULL THEN '' ELSE @propertiesList END),
                                '%SOURCETABLEBIT%', CASE WHEN @propertiesList IS NULL THEN '' ELSE 'CAST(NULL AS INT) AS  SourceTable,' END)


    EXEC(@tempScript1)

SET XACT_ABORT OFF
SET NOCOUNT OFF
END
GO
IF NOT EXISTS (SELECT * FROM sysobjects WHERE type = 'P' AND name = N'UninitializeSingleRelationshipFactTransform')
BEGIN
    EXECUTE ('CREATE PROCEDURE [dbo].[UninitializeSingleRelationshipFactTransform] @WaterMark xml AS RETURN 1')
END
GO

ALTER PROCEDURE [dbo].[UninitializeSingleRelationshipFactTransform] (
    @transformName          VARCHAR(256),
    @waterMark              XML,
    @warehouseEntityName    VARCHAR(256),
    @waterMarkType          VARCHAR(32),
    @source1MaxWM           DATETIME,
    @batchId                INT,
    @inserted               INT,
    @updated                INT
    )
AS BEGIN
SET NOCOUNT ON
SET XACT_ABORT ON

    DECLARE @retval                 INT             = -1,
            @err                    INT             = 0,
            @tempName1              VARCHAR(256)    = '',
            @tempName2              VARCHAR(256)    = '',
            @tempScript1            VARCHAR(MAX)    = '',
            @tempScript2            VARCHAR(MAX)    = ''

    DECLARE @dropTableTemplate      VARCHAR(MAX)    = 'DROP TABLE DWTemp.%TABLENAME%'

    /*
    ************************************************************************************************
    * Drop %TRANSFORMNAME%_TempOneAndHalf table
    ************************************************************************************************
    */
    SELECT @tempName1 = REPLACE('%TRANSFORMNAME%_TempOneAndHalf', '%TRANSFORMNAME%', @transformName)

    IF EXISTS (SELECT 'x' FROM sys.tables WHERE name = @tempName1)
    BEGIN
        SELECT @tempScript1 = REPLACE(@dropTableTemplate, '%TABLENAME%', @tempName1)
        EXEC (@tempScript1)
    END -- drop existing temp table

    /*
    ************************************************************************************************
    * Drop %TRANSFORMNAME%_Temp2 table
    ************************************************************************************************
    */
    SELECT @tempName1 = REPLACE('%TRANSFORMNAME%_Temp2', '%TRANSFORMNAME%', @transformName)

    IF EXISTS (SELECT 'x' FROM sys.tables WHERE name = @tempName1)
    BEGIN
        SELECT @tempScript1 = REPLACE(@dropTableTemplate, '%TABLENAME%', @tempName1)
        EXEC (@tempScript1)
    END -- drop existing temp table

SET XACT_ABORT OFF
SET NOCOUNT OFF
END
GO


IF NOT EXISTS (SELECT * FROM sysobjects WHERE type = 'P' AND name = N'SetConfigurationInfo' AND SCHEMA_NAME(uid) = 'ETL')
BEGIN
    EXECUTE ('CREATE PROCEDURE [etl].[SetConfigurationInfo] AS RETURN 1')
END
GO

/*
-- update
begin tran
exec etl.SetConfigurationInfo
    'DWMaintenance.Grooming',
    'RetentionPeriodInMinutes.Default',
    'Int32',
    0
select * from etl.Configuration
rollback tran

-- insert
begin tran
exec etl.SetConfigurationInfo
    'DWMaintenance.Grooming222',
    'RetentionPeriodInMinutes.Default',
    'Int32',
    0
select * from etl.Configuration
rollback tran

-- delete
begin tran
exec etl.SetConfigurationInfo
    'DWMaintenance.Grooming222',
    'RetentionPeriodInMinutes.Default',
    'Int32',
    null
select * from etl.Configuration
rollback tran
*/

ALTER PROCEDURE [etl].[SetConfigurationInfo] (
    @configurationFilter    NVARCHAR(512),
    @configurationPath      NVARCHAR(1024),
    @configuredValueType    VARCHAR(64),
    @configuredValue        NVARCHAR(MAX)
)
AS BEGIN
SET NOCOUNT ON
SET XACT_ABORT ON

    DECLARE @errorNumber        INT,
            @errorSeverity      INT,
            @errorState         INT,
            @errorLine          INT,
            @errorProcedure     NVARCHAR(256),
            @errorMessage       NVARCHAR(MAX),
            @task               NVARCHAR(512)

    BEGIN TRY
    IF(ISNULL(@configurationFilter, '') = '' OR ISNULL(@configurationPath, '') = '')
    BEGIN
        RAISERROR('Invalid input supplied. ConfigurationFilter and ConfigurationPath must be non-null and empty.', 16, 1)
    END

    BEGIN TRANSACTION

    ;
    MERGE etl.Configuration AS target
    USING (
        SELECT  @configurationFilter AS configFilter,
                @configurationPath AS configPath,
                @configuredValueType AS valueType,
                @configuredValue AS value
    ) AS source ON (target.ConfigurationFilter = source.configFilter AND target.ConfigurationPath = source.configPath)
    WHEN MATCHED AND source.value IS NULL THEN
        DELETE
    WHEN MATCHED THEN
        UPDATE SET
            target.ConfiguredValueType  = source.valueType,
            target.ConfiguredValue      = source.value,
            target.ModifiedDateTime     = GETUTCDATE()
    WHEN NOT MATCHED BY target THEN
        INSERT (ConfigurationFilter, ConfigurationPath, ConfiguredValueType, ConfiguredValue, CreatedDateTime, ModifiedDateTime)
        VALUES (source.configFilter, source.configPath, source.valueType, source.value, GETUTCDATE(), GETUTCDATE())
    ;

    UPDATE wegi
        SET wegi.RetentionPeriodInMinutes = @configuredValue
    FROM etl.WarehouseEntityGroomingInfo AS wegi
    JOIN etl.WarehouseEntity AS we
        ON we.WarehouseEntityId = wegi.WarehouseEntityId
    WHERE
        (we.WarehouseEntityName = @configurationPath OR @configurationPath = 'RetentionPeriodInMinutes.Default') AND
        we.WarehouseEntityName NOT IN ('EntityManagedTypeFact', 'EntityRelatesToEntityFact')

    COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        IF(@@TRANCOUNT > 0) ROLLBACK TRANSACTION
        
        DECLARE @errorFmt       VARCHAR(256)

        SELECT  @errorFmt       = N'ErrorNumber="%d" Message="%s" Severity="%d" State="%d" ProcedureName="%s" LineNumber="%d" Task="%s"',
                @errorNumber    = ERROR_NUMBER(),
                @errorMessage   = ERROR_MESSAGE(),
                @errorSeverity  = ERROR_SEVERITY(),
                @errorState     = ERROR_STATE(),
                @errorLine      = ERROR_LINE(),
                @errorProcedure = ERROR_PROCEDURE()

        RAISERROR (
            @errorFmt,
            18,
            @errorState,
            @errorNumber,
            @errorMessage,
            @errorSeverity,
            @errorState,
            @errorProcedure,
            @errorLine,
            @task
        )

        RETURN -1
    END CATCH
    
    SET XACT_ABORT OFF
    SET NOCOUNT OFF
    RETURN 0
END
GO

if exists (select * from INFORMATION_SCHEMA.ROUTINES where routine_name = 'PopulateDateDim')
begin
   drop procedure [dbo].[PopulateDateDim]
end
go

create procedure [dbo].[PopulateDateDim]
										@StartDay  smalldatetime = '20000101',
										@EndDay    smalldatetime =  '20501231'
	as
	set nocount on 

		declare	   @CalDate             smalldatetime, 
				   @DayOfWeek           varchar(32),
				   @DayNumInMonth       tinyInt,   
				   @WeekNumInYear       tinyInt,
				   @CalendarMonth		varchar(32),
				   @MonthNumber		    tinyInt,
				   @YearNumber          smallint,
				   @CalendarQuarter	    char(2),
				   @FiscalQuarter		char(2), 
				   @FiscalMonth			varchar(32),
				   @FiscalYear			char(6), 
				   @IsHoliday			bit,
				   @IsWeekDay			bit,
				   @IsLastDayOfMonth	bit,
				   @DateKey				int	   

	   
	   if (select count(*) from DateDim) = 0
	   begin
			select @CalDate = @StartDay
	   end
	   else
	   begin
			declare	@sMaxDate nvarchar(8), 
					@MaxDate smalldatetime;
		   Select @sMaxDate =  MAX([DateKey]) FROM DateDim;
		   set @MaxDate = CONVERT(smalldatetime, @sMaxDate, 112);
		   set @MaxDate = @MaxDate + 1;	   
		   select @CalDate = @MaxDate;
	   end

	   Begin Transaction  
	   while @CalDate < @EndDay
	   begin 

		   select @DateKey				= CONVERT(nvarchar(8), @CalDate, 112)
		   select @DayOfWeek			= DATENAME(dw, @CalDate) 
		   select @DayNumInMonth		= DATENAME (dd, @CalDate) 	   
		   select @WeekNumInYear		= DATENAME (week, @CalDate) 
		   select @CalendarMonth		= DATENAME(mm,@CalDate) 
		   select @MonthNumber			= DATEPART(month, @CalDate) 
		   select @YearNumber			= DATENAME(yy, @CalDate) 	      
		   select @CalendarQuarter		= 'Q' +  CAST(DATENAME (quarter, @CalDate)as char(1)) 
		   select @FiscalQuarter		= 'Q' +  CAST(isnull(nullif((DATENAME (quarter, @CalDate) + 2)%4,0),4)as char(1))
		   select @FiscalMonth			= isnull(nullif((DATEPART(month, @CalDate) + 6)%12,0),12)
		   select @FiscalYear			= DATENAME(yy, @CalDate) + 1 + isnull(nullif(SIGN(@MonthNumber-7),1),0)
		   select @IsHoliday			= CASE (DATEPART(dw, @CalDate) + @@DATEFIRST)%7  WHEN 0 THEN 1 WHEN 1 THEN 1  Else 0 END 
		   select @IsWeekDay			= CASE (DATEPART(dw, @CalDate) + @@DATEFIRST)%7  WHEN 0 THEN 0 WHEN 1 THEN 0  Else 1 END 
		   select @IsLastDayOfMonth    = CASE @DayNumInMonth WHEN DAY(DATEADD(d, -DAY(DATEADD(m,1,GETUTCDATE())),DATEADD(m,1,GETUTCDATE()))) then 1 else 0 END
		   
		   insert into DateDim (DateKey, CalendarDate, DayOfWeek, DayNumberInMonth, WeekNumberInYear, 
								CalendarMonth, MonthNumber, YearNumber, CalendarQuarter, FiscalQuarter, 
								FiscalMonth, FiscalYear, IsHoliday, IsWeekDay, IsLastDayOfMonth)
			values (@DateKey,@CalDate, @DayOfWeek, @DayNumInMonth, @WeekNumInYear, 
					@CalendarMonth, @MonthNumber, @YearNumber, @CalendarQuarter, @FiscalQuarter,
					@FiscalMonth, @FiscalYear, @IsHoliday, @IsWeekDay, @IsLastDayOfMonth) 	
	

		   select @CalDate = @CalDate + 1

	   end
	   commit transaction  

	set nocount off
go

--if (select count(*) from dbo.DateDim) = 0 
begin
	exec dbo.PopulateDateDim
	print 'Populated DateDim'
end
go




EXEC dbo.p_IncrementalPopulateDomainTable
GO

set nocount on

if (select count(*) from etl.SourceType) = 0 
begin
	print 'Populating: SourceType'
	insert into etl.SourceType (SourceTypeId, SourceTypeName) values (1, 'Warehouse')
	insert into etl.SourceType (SourceTypeId, SourceTypeName) values (2, 'ServiceManager')	
end
go

if (select count(*) from etl.Source) = 0 
begin
	print 'Populating: Source'
	insert into etl.Source (SourceGuid,SourceName, SourceTypeId)
	 values ('00000000-0000-0000-0000-000000000000', 'SCDW',1)	
end
go

if (select count(*) from etl.WarehouseEntityType) = 0 
begin
	print 'Populating WarehouseEntityType' 	
	insert into etl.WarehouseEntityType (WarehouseEntityTypeName)
		 values ('Fact')

	insert into etl.WarehouseEntityType (WarehouseEntityTypeName)
			 values ('Dimension')

	insert into etl.WarehouseEntityType (WarehouseEntityTypeName)
			 values ('Outrigger')			 
	
end
go

if (select count(*) from etl.WarehouseEntity) = 0 
begin

	print 'Populating WarehouseEntity' 	
	
	insert into etl.WarehouseEntity (EntityGuid, SourceId,WarehouseEntityName, WarehouseEntityTypeId)
	select  '00000000-0000-0000-0000-000000000000',1,'DateDim', WarehouseEntityTypeId
	from etl.WarehouseEntityType
	where WarehouseEntityTypeName = 'Dimension'
	
	
end
go


if (select count(*) from etl.WarehouseColumn) = 0 
begin

	print 'Populating: WarehouseColumn'
	exec etl.UpdateEntitySchema 	
		'<EntitySchema>
			<RelationalEntity>
				<EntityName>DateDim</EntityName>
				<EntityType>Dimension</EntityType>
				<EntityGuid>00000000-0000-0000-0000-000000000000</EntityGuid>
			</RelationalEntity>
			<Schema>
				<Columns>
					<Column>
						<ColumnName>DateKey</ColumnName>
						<DataType>int</DataType>
						<ColumnLength>4</ColumnLength>
						<Nullable>0</Nullable>
						<IsIdentity>1</IsIdentity>						
					</Column>				
					<Column>
						<ColumnName>CalendarDate</ColumnName>
						<DataType>datetime</DataType>
						<ColumnLength>4</ColumnLength>
						<Nullable>0</Nullable>
						<IsIdentity>0</IsIdentity>						
					</Column>				
					<Column>
						<ColumnName>DayOfWeek</ColumnName>
						<DataType>nvarchar</DataType>
						<ColumnLength>32</ColumnLength>
						<Nullable>0</Nullable>
						<IsIdentity>0</IsIdentity>						
					</Column>				
					<Column>
						<ColumnName>DayNumberInMonth</ColumnName>
						<DataType>int</DataType>
						<ColumnLength>4</ColumnLength>
						<Nullable>0</Nullable>
						<IsIdentity>0</IsIdentity>
					</Column>				
					<Column>
						<ColumnName>WeekNumberInYear</ColumnName>
						<DataType>int</DataType>
						<ColumnLength>4</ColumnLength>
						<Nullable>0</Nullable>
						<IsIdentity>0</IsIdentity>						
					</Column>			
					<Column>
						<ColumnName>CalendarMonth</ColumnName>
						<DataType>nvarchar</DataType>
						<ColumnLength>32</ColumnLength>
						<Nullable>0</Nullable>
						<IsIdentity>0</IsIdentity>						
					</Column>				
					<Column>
						<ColumnName>MonthNumber</ColumnName>
						<DataType>int</DataType>
						<ColumnLength>4</ColumnLength>
						<Nullable>0</Nullable>
						<IsIdentity>0</IsIdentity>						
					</Column>			
					<Column>
						<ColumnName>YearNumber</ColumnName>
						<DataType>int</DataType>
						<ColumnLength>4</ColumnLength>
						<Nullable>0</Nullable>
						<IsIdentity>0</IsIdentity>						
					</Column>
					<Column>
						<ColumnName>CalendarQuarter</ColumnName>
						<DataType>nvarchar</DataType>
						<ColumnLength>4</ColumnLength>
						<Nullable>0</Nullable>
						<IsIdentity>0</IsIdentity>						
					</Column>									
					<Column>
						<ColumnName>FiscalQuarter</ColumnName>
						<DataType>nvarchar</DataType>
						<ColumnLength>4</ColumnLength>
						<Nullable>0</Nullable>
						<IsIdentity>0</IsIdentity>						
					</Column>
					<Column>
						<ColumnName>FiscalMonth</ColumnName>
						<DataType>int</DataType>
						<ColumnLength>4</ColumnLength>
						<Nullable>0</Nullable>
						<IsIdentity>0</IsIdentity>						
					</Column>		
					<Column>
						<ColumnName>FiscalYear</ColumnName>
						<DataType>int</DataType>
						<ColumnLength>4</ColumnLength>
						<Nullable>0</Nullable>
						<IsIdentity>0</IsIdentity>						
					</Column>		
					<Column>
						<ColumnName>IsHoliday</ColumnName>
						<DataType>int</DataType>
						<ColumnLength>4</ColumnLength>
						<Nullable>0</Nullable>
						<IsIdentity>0</IsIdentity>						
					</Column>		
					<Column>
						<ColumnName>IsWeekDay</ColumnName>
						<DataType>int</DataType>
						<ColumnLength>4</ColumnLength>
						<Nullable>0</Nullable>
						<IsIdentity>0</IsIdentity>						
					</Column>		
						<Column>
						<ColumnName>IsLastDayOfMonth</ColumnName>
						<DataType>int</DataType>
						<ColumnLength>4</ColumnLength>
						<Nullable>0</Nullable>
						<IsIdentity>0</IsIdentity>						
					</Column>		
				</Columns>
			</Schema>
		</EntitySchema>'		

end
go



set nocount off

go

/*
****************************************************************************************************************************************
*    etl Configuration data
*
    SELECT * FROM etl.Configuration
****************************************************************************************************************************************
*/

SELECT *
INTO #TempConfiguration
FROM (          -- 3 months = 1mi * 60mis * 24hrs * 30days * 3mons = 129600
                SELECT 'DWMaintenance.Grooming' AS ConfigurationFilter, '129600' AS ConfiguredValue, 'RetentionPeriodInMinutes.Default' AS ConfigurationPath, 'Int32' AS ConfiguredValueType

    -- 50 years = 50yrs * 365days * 24hrs * 60mins = 26280000
    UNION ALL   SELECT 'DWMaintenance.Grooming.RetentionPeriodInMinutes', '26280000', 'EntityRelatesToEntityFact', 'Int32'
    UNION ALL   SELECT 'DWMaintenance.Grooming.RetentionPeriodInMinutes', '26280000', 'EntityManagedTypeFact', 'Int32'

    -- 50 years for Chargeback monthly and relationship facts
    UNION ALL   SELECT 'DWMaintenance.Grooming.RetentionPeriodInMinutes', '26280000', 'InfraChargebackMonthlyFact', 'Int32'
    UNION ALL   SELECT 'DWMaintenance.Grooming.RetentionPeriodInMinutes', '26280000', 'PrivateCloudContainsVirtualMachineFact', 'Int32'
    UNION ALL   SELECT 'DWMaintenance.Grooming.RetentionPeriodInMinutes', '26280000', 'PrivateCloudRelatesToUsageFact', 'Int32'
    UNION ALL   SELECT 'DWMaintenance.Grooming.RetentionPeriodInMinutes', '26280000', 'PrivateCloudRelatesToDefaultUsageFact', 'Int32'
    UNION ALL   SELECT 'DWMaintenance.Grooming.RetentionPeriodInMinutes', '26280000', 'UsageRelatesToPricesheetFact', 'Int32'
    UNION ALL   SELECT 'DWMaintenance.Grooming.RetentionPeriodInMinutes', '26280000', 'UserRoleRelatesToUsageFact', 'Int32'
    UNION ALL   SELECT 'DWMaintenance.Grooming.RetentionPeriodInMinutes', '26280000', 'VirtualMachineContainsVirtualDiskDriveFact', 'Int32'
    UNION ALL   SELECT 'DWMaintenance.Grooming.RetentionPeriodInMinutes', '26280000', 'VirtualMachineHostsVNicFact', 'Int32'

    -- 1 month = 1mi * 60mis * 24hrs * 30days = 43200 for Chargeback snapshot facts
    UNION ALL   SELECT 'DWMaintenance.Grooming.RetentionPeriodInMinutes', '43200', 'VirtualNicSnapshotFact', 'Int32'
    UNION ALL   SELECT 'DWMaintenance.Grooming.RetentionPeriodInMinutes', '43200', 'VirtualDiskDriveSnapshotFact', 'Int32'

    UNION ALL   SELECT 'DWMaintenance.Grooming.GroomingStoredProcedure', 'EXEC etl.DropPartition @WarehouseEntityId=@WarehouseEntityId, @WarehouseEntityType=@WarehouseEntityType, @EntityGuid=@EntityGuid, @PartitionId=@PartitionId, @GroomActiveRelationship=1', 'GroomingProcedure.Default', 'Int32'
) AS A

DELETE Cfg
FROM etl.Configuration Cfg
LEFT JOIN #TempConfiguration tempCfg ON
        Cfg.ConfigurationFilter     = tempCfg.ConfigurationFilter
    AND Cfg.ConfigurationPath       = tempCfg.ConfigurationPath
WHERE   tempCfg.ConfigurationFilter IS NOT NULL

INSERT INTO etl.Configuration(
        ConfigurationFilter,
        ConfiguredValue,
        ConfigurationPath,
        ConfiguredValueType
        )
SELECT  tempCfg.ConfigurationFilter,
        tempCfg.ConfiguredValue,
        tempCfg.ConfigurationPath,
        tempCfg.ConfiguredValueType
FROM #TempConfiguration tempCfg
LEFT JOIN etl.Configuration Cfg ON
        Cfg.ConfigurationFilter = tempCfg.ConfigurationFilter
    AND Cfg.ConfigurationPath   = tempCfg.ConfigurationPath
WHERE   Cfg.ConfigurationFilter IS NULL

IF OBJECT_ID('tempdb..#TempConfiguration') IS NOT NULL DROP TABLE #TempConfiguration
GO
