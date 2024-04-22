-- set the values below accordingly
use DWStagingAndConfig -- change this if different
declare @IhaveTakenBackupsOfAllDwDatabases nchar(3) = 'NO' -- mofify this to 'YES' in order to make real CHANGES

-------- do not make any changes below this line --------------------------------------------------------
-----------------------------------------------------------------
if (@IhaveTakenBackupsOfAllDwDatabases != 'YES')
begin
	RAISERROR('Please take DW db backups, then modify @IhaveTakenBackupsOfAllDwDatabases to ''YES'' and rerun this script.',0,1) WITH NOWAIT
	return
end
set nocount on
declare @BatchId int
declare @WorkItemId bigint
declare @VertexName nvarchar(256) 
declare @ModuleName nvarchar(256) = 'PeripheralLogicalDiskDim%'
declare @errorSearchpart nvarchar(max) = '%Incorrect syntax near the keyword ''IF''%'
declare @minRetryCount int = 1
declare @phase int = 1

select 'please switch to the ''Messages'' tab'
RAISERROR('Script started.',0,1) WITH NOWAIT

while 1=1
begin

	set @WorkItemId = null
	select	@BatchId = b.BatchId, @WorkItemId = wi.WorkItemId, @VertexName = pm.VertexName
	from infra.Process p
		inner join infra.Batch b on p.ProcessId = b.ProcessId
		inner join infra.WorkItem wi on b.BatchId = wi.BatchId
		inner join infra.ProcessModule pm on wi.ProcessModuleId = pm.ProcessModuleId
		inner join infra.Module m on pm.ModuleId = m.ModuleId
		inner join DeployItemStaging dis on m.ModuleName = dis.DeployItemName
	where p.ProcessName like 'Microsoft.SystemCenter.ConfigurationManager.Datawarehouse.1.Update.%'
	and b.StatusId = 2
	and wi.StatusId = 2 and wi.RetryCount >= @minRetryCount and convert(nvarchar(max),wi.ErrorSummary) like @errorSearchpart
	and m.ModuleName like  'PeripheralLogicalDiskDim%'
	and dis.StatusId = 2 and dis.ForDelete = 0 and dis.Outcome like @errorSearchpart

	if @WorkItemId is null -- keep looping
	begin
		RAISERROR('Problem did NOT happen yet. Sleeping for 30 seconds, then will check again. Please keep the script runnning...',0,1) WITH NOWAIT
		waitfor delay '00:00:30'
		continue
	end

	declare @msg nvarchar(max) = 'Phase #' + convert(char(1),@phase) + ' problem detected. Now fixing...'
	RAISERROR(@msg,0,1) WITH NOWAIT
	------------------------------
	update infra.WorkItem set StatusId=6
	where WorkItemId = @WorkItemId

	delete 
	infra.WorkItemDAG where ParentWorkItemId = @WorkItemId

	update DeployItemStaging set StatusId=6
	where DeployItemId=@VertexName

	if @phase = 1
	begin
		RAISERROR('Fix for phase #1 done. Now waiting for phase #2 to happen...',0,1) WITH NOWAIT
		set @phase=2
		continue
	end
	else
	begin
		RAISERROR('Fix for phase #2 done. Script completed.',0,1) WITH NOWAIT
		break
	end

end
