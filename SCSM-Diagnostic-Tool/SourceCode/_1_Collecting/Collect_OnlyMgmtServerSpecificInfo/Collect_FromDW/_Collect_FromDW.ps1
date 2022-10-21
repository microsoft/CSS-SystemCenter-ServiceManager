function Collect_FromDW() {
#region DO NOT REMOVE THIS! Exit immediately if script is NOT running on a DW mgmt server
if (-not (IsThisScsmDwMgmtServer)) {
    return
}
#endregion

# Collects info that is specific to only DW servers

    Collect_SetDWRoleFound
    Collect_DWJobs    
    Collect_DWJobs_Last5   
    Collect_DWJobSchedules
    Collect_DWEnvironmentInfo
    Collect_TimeDiffBetweenDWMSandSQL
    Collect_DW_MPs
    Collect_Test_BetweenDWMSandSQL 
    Collect_SqlErrorLogFiles_DW

    Collect_SQL_DW_Shared
    Collect_SQL_DWStagingAndConfig

    #region DO NOT MOVE THIS! To be used in subsequent functions
$SQL_DWFactConstraintsIssue=@'
declare @fixFactDiscrepancies bit = 0	-- set this to 1 for real corrections, but Please take a database backup before !!!
										-- set this to 0 to only show the discrepancies and generate a change script to be applied manually.
--------------------------------------------------------------------
set nocount on
declare @overallIssuesFound bit = 0
declare @allIssuesFixed bit = 1
if @fixFactDiscrepancies = 1 
	print '-- Read-write mode. Fixing issues ...';
else
	print '-- Read-only mode. Only generating a change script ...'	
print ''
----------------------------------
--	begin tran --for debugging only
----------------------------------
declare @initialTrancount int 
set @initialTrancount=@@TRANCOUNT
if @initialTrancount > 0
	print  '-- @initialTrancount : ' + cast(@initialTrancount as nvarchar(max)) 
----------------------------------
declare @dec31Exists bit
set @dec31Exists=0
select @dec31Exists=1 from DateDim where DateKey=20201231 --should exist
if @dec31Exists = 0
begin
	set @overallIssuesFound = 1

	print '--current DateDim contains no row for 2020/12/31' 
	declare @dec31Exists_Script nvarchar(max)
	set @dec31Exists_Script='insert into DateDim values (20201231,	''20201231'',	''Thursday'',	31,	53,	''December'',	12,	2020,	''Q4'',	''Q2'',	6,	2021,	0,	1,	1)'
	print @dec31Exists_Script

	if @fixFactDiscrepancies = 1
	begin	
			begin try
				exec sp_executesql @dec31Exists_Script										
			end try
			begin catch
				set @allIssuesFixed = 0
				print 'Error happened with: ' + @dec31Exists_Script
				print ERROR_MESSAGE()
				goto ErrorHappened
			end catch
	end
end
------------------------------------------------------------------------------------
declare @dateCountAfter2021 int
set @dateCountAfter2021=0
select @dateCountAfter2021=count(*) from DateDim where DateKey between 20210101 and 20501231 --should be 10956
if @dateCountAfter2021 < 10956 
begin
	set @overallIssuesFound = 1

	print '--current DateDim contains less rows between 20210101 and 20501231 =>' + cast(@dateCountAfter2021 as nvarchar(max))
	--declare @startByDateKey int
	--select @startByDateKey=max(DateKey) from DateDim 
	--set @startByDateKey= @startByDateKey + 1

	declare @startByDateKey smalldatetime	--7.2
	select @startByDateKey=max(CalendarDate) from DateDim 
	set @startByDateKey= @startByDateKey + 1

	declare @dateCountAfter2021_Script nvarchar(max)
	set @dateCountAfter2021_Script='exec PopulateDateDim '''+convert(char(8),@startByDateKey,112)+''' , ''20501231'' '  --7.2
	print @dateCountAfter2021_Script

	if @fixFactDiscrepancies = 1
	begin	
			begin try
				exec sp_executesql @dateCountAfter2021_Script										
			end try
			begin catch
				set @allIssuesFixed = 0
				print 'Error happened with: ' + @dateCountAfter2021_Script
				print ERROR_MESSAGE()
				goto ErrorHappened
			end catch
	end
end
-------------------------------------------------------------------------------------------
declare @Months table (MonthName char(3),MonthValue tinyint, LastDay tinyint)
insert into @Months values 
('Jan',1,31),
('Feb',2,28),
('Mar',3,31),
('Apr',4,30),
('May',5,31),
('Jun',6,30),
('Jul',7,31),
('Aug',8,31),
('Sep',9,30),
('Oct',10,31),
('Nov',11,30),
('Dec',12,31)
declare @factName sysname
declare @factTableName sysname
declare @factTables table (name sysname, [Year] smallint, [Month] tinyint, YearMonth int)
declare @isFirstIteration bit, @prevPartitionEndDate int
declare @chkStartDate int, @chkEndDate int
declare @issuesFoundForFact bit 
declare @tmpFact_Script nvarchar(max), @tmpFact_Created bit

declare c cursor local FORWARD_ONLY READ_ONLY for
	select we.WarehouseEntityName --V7
	from etl.WarehouseEntity we 
	inner join etl.WarehouseEntityType wet on we.WarehouseEntityTypeId=wet.WarehouseEntityTypeId and wet.WarehouseEntityTypeName='Fact'	
	order by 1
open c; while 1=1 begin; fetch c into @factName; if @@FETCH_STATUS<>0 break;
	
	set @isFirstIteration=1
	set @issuesFoundForFact=0
	set @prevPartitionEndDate=0
	set @tmpFact_Created=0
	
	declare @currentView nvarchar(max)
	select @currentView=definition from sys.objects o join sys.sql_modules m on m.object_id = o.object_id where o.object_id = object_id('dbo.'+ @factName+'vw') and o.type = 'V' 
	declare @isViewCorrect bit
	set @isViewCorrect = 1
	declare @factColumnList nvarchar(max)
	set @factColumnList = ''
	select @factColumnList=@factColumnList+',['+name+']' from sys.columns where object_id=(select object_id from sys.views where name=@factName+'vw') order by column_id
	set @factColumnList = SUBSTRING(@factColumnList,2,80000) 

	delete @factTables
	insert into @factTables (name) 
	select tp.PartitionName --V7
	from etl.WarehouseEntity we 
		inner join etl.WarehouseEntityType wet on we.WarehouseEntityTypeId=wet.WarehouseEntityTypeId and wet.WarehouseEntityTypeName='Fact'	
		inner join etl.TablePartition tp on we.WarehouseEntityName=tp.WarehouseEntityName
	where tp.WarehouseEntityName = @factName
	order by tp.PartitionName

	declare c2 cursor local FORWARD_ONLY READ_ONLY for
		select name from @factTables;
	open c2; while 1=1 begin; fetch c2 into @factTableName; if @@FETCH_STATUS<>0 break;		
		declare @Year smallint, @Month tinyint, @YearMonth int, @YearName char(4), @MonthName char(3)

		set @MonthName=RIGHT(@factTableName,3)
		set @YearName=RIGHT(@factTableName,8); set @YearName=left(@YearName,4)
		set @year=cast(@YearName as smallint)
		select @Month=MonthValue from @Months where MonthName=@MonthName
		update @factTables
		set [Year]=@Year, [Month]=@Month, YearMonth=@Year*100+@Month
		where name=@factTableName
	end; close c2; deallocate c2;

	declare @minYear smallint, @minMonth tinyint, @maxYear smallint, @maxMonth tinyint, @minYearMonth int, @maxYearMonth int, @prevYearMonth int, @nextAvailableYear smallint, @nextAvailableMonth tinyint, @prevMonthLastDay int
	select @minYear=min(YearMonth)/100, @minMonth=min(YearMonth) % 100, @maxYear=max(YearMonth)/100, @maxMonth=max(YearMonth) % 100, @minYearMonth=min(YearMonth), @maxYearMonth=max(YearMonth)	
	from @factTables
	
	print 'begin tran -- '+@factName
	if @fixFactDiscrepancies = 1 
		begin tran -- 

	declare c3 cursor local FORWARD_ONLY READ_ONLY for
		select name, [Year], [Month], YearMonth from @factTables order by YearMonth
	open c3; while 1=1 begin; fetch c3 into @factTableName, @Year, @Month, @YearMonth; if @@FETCH_STATUS<>0 break;

		set @chkStartDate=0
		set @chkEndDate=0

		--calculate new TP range values
		if @YearMonth = @maxYearMonth
		begin
			set @chkStartDate = @YearMonth*100 + 1
			set @chkEndDate=null
		end
		else
		begin			
			select top 1 @nextAvailableYear=[Year], @nextAvailableMonth=[Month]
			from @factTables
			where YearMonth>@YearMonth
			order by YearMonth		
			if @nextAvailableMonth = 1	set @prevMonthLastDay=(@nextAvailableYear-1)*10000+1231
			else	set @prevMonthLastDay=(@nextAvailableYear*10000) + ((@nextAvailableMonth-1)*100) + (select LastDay from @Months where MonthValue=@nextAvailableMonth-1) 
			
			if @isFirstIteration = 1  
				set @chkStartDate = null
			else 			
				set @chkStartDate = @YearMonth*100 + 1			

			set @chkEndDate = @prevMonthLastDay
		end	
		if @chkEndDate % 100 = 28					
			if ((@chkEndDate / 10000) % 4) = 0	
				set @chkEndDate = @chkEndDate+1	
   --------------------------------------------------------------------------------
		--check TP range values 
		declare @currentRangeStartDate int, @currentRangeEndDate int
		select @currentRangeStartDate=RangeStartDate, @currentRangeEndDate=RangeEndDate from etl.TablePartition where PartitionName = @factTableName
		if 	(@currentRangeStartDate is null and @chkStartDate is not null)	or
			(@currentRangeStartDate is not null and @chkStartDate is null)	or
			(@currentRangeStartDate is not null and @chkStartDate is not null and @currentRangeStartDate != @chkStartDate) or
			(@currentRangeEndDate is null and @chkEndDate is not null)	or
			(@currentRangeEndDate is not null and @chkEndDate is null) or
			(@currentRangeEndDate is not null and @chkEndDate is not null and @currentRangeEndDate != @chkEndDate)
		begin
			set @overallIssuesFound = 1; set @issuesFoundForFact = 1;

			print ' --current range in TP for ' +@factTableName + ' : ' + case when @currentRangeStartDate is null then 'null' else cast(@currentRangeStartDate as nvarchar(max)) end + ' ' + case when @currentRangeEndDate is null then 'null' else cast(@currentRangeEndDate as nvarchar(max)) end
			declare @UpdateTPScript nvarchar(max)
			set @UpdateTPScript=N' update etl.TablePartition set RangeStartDate = ' + case when @chkStartDate is null then 'null' else cast(@chkStartDate as nvarchar(max)) end + ', RangeEndDate = ' + case when @chkEndDate   is null then 'null' else cast(@chkEndDate as nvarchar(max)) end +'	where PartitionName = '''+ @factTableName +''''
			print @UpdateTPScript
			
			if @fixFactDiscrepancies = 1	
				begin try
					exec sp_executesql @UpdateTPScript		
				end try
			begin catch
				set @allIssuesFixed = 0
				print 'Error happened with: ' + @UpdateTPScript
				print ERROR_MESSAGE()
				goto ErrorHappened
			end catch
		end
   --------------------------------------------------------------------------------
		--check values in fact table if they match TP Range dates
   		declare @sqlMinMaxInTable nvarchar(max), @MinDateKey int, @MaxDateKey int
		set @sqlMinMaxInTable =N'select @MinDateKey=min(DateKey), @MaxDateKey=max(DateKey) from ' + @factTableName
		exec sp_executesql @sqlMinMaxInTable, N'@MinDateKey int out, @MaxDateKey int out', @MinDateKey out, @MaxDateKey out

		if @chkStartDate is null
		begin 
			if @MaxDateKey > @chkEndDate
			begin
				set @overallIssuesFound = 1; set @issuesFoundForFact = 1;				

				set @tmpFact_Script=' IF OBJECT_ID(''Tmp_'+@factName+''') IS NULL 	select top 0 * into Tmp_'+@factName+' from '+@factName+'vw'
				set @tmpFact_Created=1
				print @tmpFact_Script

				declare @sql_MaxDateKeyGTchkEndDate nvarchar(max), @rowCount_MaxDateKeyGTchkEndDate int
				set @sql_MaxDateKeyGTchkEndDate =N'select @rowCount_MaxDateKeyGTchkEndDate=count(*) from '+@factTableName+' where DateKey > '+cast(@chkEndDate as nvarchar(max))
				exec sp_executesql @sql_MaxDateKeyGTchkEndDate, N'@rowCount_MaxDateKeyGTchkEndDate int out', @rowCount_MaxDateKeyGTchkEndDate out
				print ' --current '+@factTableName+' has '+cast(@rowCount_MaxDateKeyGTchkEndDate as nvarchar(max))+' rows that are greater than the new TP.RangeEndDate ' + cast(@chkEndDate as nvarchar(max))
				declare @MaxDateKeyGTchkEndDate_Script nvarchar(max)
			
				set @MaxDateKeyGTchkEndDate_Script=
				' delete from '+@factTableName+' output '+REPLACE(@factColumnList,'[','deleted.[')+' into Tmp_'+@factName+' ('+@factColumnList+')'				
				+' where DateKey > '+cast(@chkEndDate as nvarchar(max))
				print @MaxDateKeyGTchkEndDate_Script

				if @fixFactDiscrepancies = 1
				begin	
					begin try
						exec sp_executesql @tmpFact_Script
						exec sp_executesql @MaxDateKeyGTchkEndDate_Script										
					end try
					begin catch
						set @allIssuesFixed = 0
						print 'Error happened with: ' + @MaxDateKeyGTchkEndDate_Script
						print ERROR_MESSAGE()
						goto ErrorHappened
					end catch
				end
			end
		end

		else if @chkEndDate is null
		begin 
			if @MinDateKey < @chkStartDate
			begin
				set @overallIssuesFound = 1; set @issuesFoundForFact = 1;

				set @tmpFact_Script=' IF OBJECT_ID(''Tmp_'+@factName+''') IS NULL 	select top 0 * into Tmp_'+@factName+' from '+@factName+'vw'
				set @tmpFact_Created=1
				print @tmpFact_Script

				declare @sql_MinDateKeyLTchkStartDate nvarchar(max), @rowCount_MinDateKeyLTchkStartDate int
				set @sql_MinDateKeyLTchkStartDate =N'select @rowCount_MinDateKeyLTchkStartDate=count(*) from '+@factTableName+' where DateKey < '+cast(@chkStartDate as nvarchar(max))
				exec sp_executesql @sql_MinDateKeyLTchkStartDate, N'@rowCount_MinDateKeyLTchkStartDate int out', @rowCount_MinDateKeyLTchkStartDate out
				print ' --current '+@factTableName+' has '+cast(@rowCount_MinDateKeyLTchkStartDate as nvarchar(max))+' rows that are less than the new TP.RangeStartDate ' + cast(@chkStartDate as nvarchar(max))
				declare @MinDateKeyLTchkStartDate_Script nvarchar(max)

				set @MinDateKeyLTchkStartDate_Script=
				' delete from '+@factTableName+' output '+REPLACE(@factColumnList,'[','deleted.[')+' into Tmp_'+@factName+' ('+@factColumnList+')'				
				+' where DateKey < '+cast(@chkStartDate as nvarchar(max))
				print @MinDateKeyLTchkStartDate_Script

				if @fixFactDiscrepancies = 1
				begin	
					begin try
						exec sp_executesql @tmpFact_Script
						exec sp_executesql @MinDateKeyLTchkStartDate_Script										
					end try
					begin catch
						set @allIssuesFixed = 0
						print 'Error happened with: ' + @MinDateKeyLTchkStartDate_Script
						print ERROR_MESSAGE()
						goto ErrorHappened
					end catch
				end
			end
		end

		else
		begin 
			if @MinDateKey < @chkStartDate or @MaxDateKey > @chkEndDate
			begin
				set @overallIssuesFound = 1; set @issuesFoundForFact = 1;

				set @tmpFact_Script=' IF OBJECT_ID(''Tmp_'+@factName+''') IS NULL 	select top 0 * into Tmp_'+@factName+' from '+@factName+'vw'
				set @tmpFact_Created=1
				print @tmpFact_Script

				declare @sql_MinDateKeyLTchkStartDateORMaxDateKeyGTchkEndDate nvarchar(max), @rowCount_MinDateKeyLTchkStartDateORMaxDateKeyGTchkEndDate int
				set @sql_MinDateKeyLTchkStartDateORMaxDateKeyGTchkEndDate =N'select @rowCount_MinDateKeyLTchkStartDateORMaxDateKeyGTchkEndDate=count(*) from '+@factTableName+' where DateKey < '+cast(@chkStartDate as nvarchar(max))+ ' or DateKey > '+cast(@chkEndDate as nvarchar(max))
				exec sp_executesql @sql_MinDateKeyLTchkStartDateORMaxDateKeyGTchkEndDate, N'@rowCount_MinDateKeyLTchkStartDateORMaxDateKeyGTchkEndDate int out', @rowCount_MinDateKeyLTchkStartDateORMaxDateKeyGTchkEndDate out
				print ' --current '+@factTableName+' has '+cast(@rowCount_MinDateKeyLTchkStartDateORMaxDateKeyGTchkEndDate as nvarchar(max))+' rows that are less than the new TP.RangeStartDate ' + cast(@chkStartDate as nvarchar(max))+' or greater than the new TP.RangeEndDate ' + cast(@chkEndDate as nvarchar(max))
				declare @MinDateKeyLTchkStartDateORMaxDateKeyGTchkEndDate_Script nvarchar(max)
				set @MinDateKeyLTchkStartDateORMaxDateKeyGTchkEndDate_Script=
				' delete from '+@factTableName+' output '+REPLACE(@factColumnList,'[','deleted.[')+' into Tmp_'+@factName+' ('+@factColumnList+')'				
				+' where DateKey < '+cast(@chkStartDate as nvarchar(max))+ ' or DateKey > '+cast(@chkEndDate as nvarchar(max))
				print @MinDateKeyLTchkStartDateORMaxDateKeyGTchkEndDate_Script

				if @fixFactDiscrepancies = 1
				begin	
					begin try
						exec sp_executesql @tmpFact_Script
						exec sp_executesql @MinDateKeyLTchkStartDateORMaxDateKeyGTchkEndDate_Script										
					end try
					begin catch
						set @allIssuesFixed = 0
						print 'Error happened with: ' + @MinDateKeyLTchkStartDateORMaxDateKeyGTchkEndDate_Script
						print ERROR_MESSAGE()
						goto ErrorHappened
					end catch
				end
			end
		end
   --------------------------------------------------------------------------------
		--check constraints
		declare @currentChk nvarchar(max)
		set @currentChk=''
		select @currentChk=definition from sys.check_constraints where name = @factTableName + '_Chk'
		set @currentChk = REPLACE(@currentChk,'(','')
		set @currentChk = REPLACE(@currentChk,')','')

		declare @correctChk nvarchar(max) 
		set @correctChk = ''
		if @chkStartDate is not null
			set @correctChk = '[DateKey]>='+ cast(@chkStartDate as nvarchar(max))
		if @chkStartDate is not null  and @chkEndDate is not null
			set @correctChk = @correctChk + ' AND '
		if @chkEndDate is not null
			set @correctChk = @correctChk + '[DateKey]<='+ cast(@chkEndDate as nvarchar(max))

		declare @checkConstraintCount int --V7
		select @checkConstraintCount=count(*) from sys.check_constraints where parent_object_id=OBJECT_ID(@factTableName)

		declare @chkScript nvarchar(max) 
		set @chkScript= ''
		if @currentChk != @correctChk or @checkConstraintCount > 1
		begin
			set @overallIssuesFound = 1; set @issuesFoundForFact = 1;
			
			if @checkConstraintCount > 1 --V7
			begin
				print ' --current '+ @factTableName+' has more than 1 check constraint : '+cast(@checkConstraintCount as nvarchar(max))
				declare @chkConstraintNameToDelete sysname
				declare cCheckConstraints cursor local FORWARD_ONLY READ_ONLY for
					select name from sys.check_constraints where parent_object_id=OBJECT_ID(@factTableName) 
				open cCheckConstraints; while 1=1 begin; fetch cCheckConstraints into @chkConstraintNameToDelete; if @@FETCH_STATUS<>0 break;
					set @chkScript = @chkScript + ' ALTER TABLE dbo.'+ @factTableName +' DROP CONSTRAINT '+ @chkConstraintNameToDelete +'; ' 
				end; close cCheckConstraints; deallocate cCheckConstraints;
			end
			else if @currentChk != '' 
			begin
				print ' --current '+ @factTableName+'_chk: ' + @currentChk
				set @chkScript = @chkScript + ' ALTER TABLE dbo.'+ @factTableName +' DROP CONSTRAINT '+ @factTableName +'_Chk; '			
			end
					
			set @chkScript = @chkScript + ' ALTER TABLE [dbo].['+ @factTableName +']  WITH CHECK ADD  CONSTRAINT ['+ @factTableName +'_Chk] CHECK  ('+ @correctChk +'); ALTER TABLE [dbo].['+ @factTableName +'] CHECK CONSTRAINT ['+ @factTableName +'_Chk]'
			print @chkScript			
			if @fixFactDiscrepancies = 1	
			begin try
				exec sp_executesql @chkScript				
			end try
			begin catch
				set @allIssuesFixed = 0
				print 'Error happened with: ' + @chkScript
				print ERROR_MESSAGE()				
				goto ErrorHappened
			end catch			
		end

	 --------------------------------------------------------------------------------
	   --check view
		if CHARINDEX(@factTableName, @currentView)=0
		begin
			set @overallIssuesFound = 1; set @issuesFoundForFact = 1;

			set @isViewCorrect = 0
			print ' --'+@factTableName +' not in view.'
		end		

		if @isFirstIteration =1 set @isFirstIteration=0

	end; close c3; deallocate c3; -- of partition cursor
  --------------------------------------------------------------------------------

	--check for orphaned tables
	declare @orphanedTableCount int
	declare @OrphanedTables table (TableName sysname)
	delete @OrphanedTables
	insert into @OrphanedTables
	select t.name
	from etl.WarehouseEntity we 
		inner join etl.WarehouseEntityType wet on we.WarehouseEntityTypeId=wet.WarehouseEntityTypeId and wet.WarehouseEntityTypeName='Fact'	
		inner join sys.tables t on t.name like we.WarehouseEntityName + '\_____\____' escape '\' 
	where we.WarehouseEntityName = @factName
		and not exists(
		select tp.PartitionName
		from etl.WarehouseEntity we 
			inner join etl.WarehouseEntityType wet on we.WarehouseEntityTypeId=wet.WarehouseEntityTypeId and wet.WarehouseEntityTypeName='Fact'	
			inner join etl.TablePartition tp on we.WarehouseEntityName=tp.WarehouseEntityName
		where tp.PartitionName=t.name
	)
	select @orphanedTableCount=count(*) from @OrphanedTables
	-------------------------------------------------------------------------------------------
	--re-create views
	if @isViewCorrect = 0 or @orphanedTableCount > 0 
	begin
		--declare @dropView_Script nvarchar(max)
		--set @dropView_Script=' drop view '+@factName+'vw'
		--print @dropView_Script

		declare @factGuid uniqueidentifier
		select @factGuid=EntityGuid from etl.WarehouseEntity where WarehouseEntityName=@factName
		declare @correctView_Script nvarchar(max)
		set @correctView_Script=' exec etl.CreateView @EntityGuid='''+cast(@factGuid as nvarchar(max)) +''', @WarehouseEntityType=''Fact'' -- ' + @factName
		print @correctView_Script

		if @fixFactDiscrepancies = 1
		begin	
				begin try
					--exec sp_executesql @dropView_Script										
					exec sp_executesql @correctView_Script										
				end try
				begin catch
					set @allIssuesFixed = 0
					print 'Error happened with: ' + @correctView_Script
					print ERROR_MESSAGE()
					goto ErrorHappened
				end catch
		end
	end

	--move rows in orphaned tables to view
	if @orphanedTableCount > 0 
	begin
		set @overallIssuesFound = 1; set @issuesFoundForFact = 1;

		print ' --current @orphanedTableCount for '+@factName+' : ' + cast(@orphanedTableCount as nvarchar(max))
		declare @orphanedTable_Script nvarchar(max) 
		set @orphanedTable_Script=''
		declare @orphanedTableName sysname
		declare cOrphanedTables cursor local FORWARD_ONLY READ_ONLY for
			select TableName from @OrphanedTables
		open cOrphanedTables; while 1=1 begin; fetch cOrphanedTables into @orphanedTableName; if @@FETCH_STATUS<>0 break;

			declare @sql_OrphanedTable nvarchar(max), @rowCount_OrphanedTable int
			set @sql_OrphanedTable =N'select @rowCount_OrphanedTable=count(*) from '+@orphanedTableName
			exec sp_executesql @sql_OrphanedTable, N'@rowCount_OrphanedTable int out', @rowCount_OrphanedTable out
			set @orphanedTable_Script = @orphanedTable_Script +char(13)+' -- '+cast(@rowCount_OrphanedTable as nvarchar(max))+' rows to be moved from orphaned table: '+@orphanedTableName+char(13)

			set @orphanedTable_Script = @orphanedTable_Script 
			+' insert into '+@factName+'vw ('+@factColumnList+') '
			+' select '+@factColumnList 
			+' from dbo.'+@orphanedTableName+';' 
			+' drop table dbo.'+@orphanedTableName+'; ' 		
		end; close cOrphanedTables; deallocate cOrphanedTables;

		set @orphanedTable_Script = ' exec sp_executesql N''' +@orphanedTable_Script+''''
		print @orphanedTable_Script

		if @fixFactDiscrepancies = 1	
		begin try
			exec sp_executesql @orphanedTable_Script		
		end try
		begin catch
			set @allIssuesFixed = 0
			print 'Error happened with: ' + @orphanedTable_Script
			print ERROR_MESSAGE()				
			goto ErrorHappened
		end catch
	end
	-------------------------------------------------------------------------------------------
	--move rows in Tmp_fact tables to view
	--declare @sql_TmpFactExists nvarchar(max), @TmpFactExists int
	--set @sql_TmpFactExists =N'select @TmpFactExists=OBJECT_ID(''Tmp_'+@factName+''')'
	--exec sp_executesql @sql_TmpFactExists, N'@TmpFactExists int out', @TmpFactExists out
	--if @TmpFactExists is not null
	if @tmpFact_Created=1
	begin
		print ' -- inserting into '+@factName+'vw  from Tmp_'+@factName
		declare @fromTmpFactToView_Script nvarchar(max)
		set @fromTmpFactToView_Script=' insert into '+@factName+'vw ('+@factColumnList+') '
		+' select '+@factColumnList
		+' from Tmp_'+@factName
		+'; drop table Tmp_'+@factName
		print @fromTmpFactToView_Script

		if @fixFactDiscrepancies = 1
		begin	
			begin try
				exec sp_executesql @fromTmpFactToView_Script										
			end try
			begin catch
				set @allIssuesFixed = 0
				print 'Error happened with: ' + @fromTmpFactToView_Script
				print ERROR_MESSAGE()
				goto ErrorHappened
			end catch
		end
	end				

	--------------------------------------------
	if @issuesFoundForFact = 1
		print ''

	--------------------------------------------
	print 'commit tran-- '+@factName
	if @fixFactDiscrepancies = 1
		commit tran
	--------------------------------------------
end; close c; deallocate c; --of fact cursor

----------------------------------------------------------------------------------------
declare @result nvarchar(max)
print ''
print '-- *****************************************************************'
print '--     R E S U L T   for database:  ' + DB_NAME() 
print '-- *****************************************************************'
print ''
----------------------------------------------------------------------------------------

if @@TRANCOUNT > @initialTrancount
	goto ErrorHappened
else if @@TRANCOUNT > 0
	print  '-- @@TRANCOUNT : ' + cast(@@TRANCOUNT as nvarchar(max)) 
----------------------------------------------------------------------------------------
-- print '@@TRANCOUNT : '+ cast(@@TRANCOUNT as nvarchar(max))  --for debugging only
-- rollback --for debugging only
----------------------------------------------------------------------------------------

if @overallIssuesFound=0
begin 
	print '-- No issues found.'
	return
end

if @allIssuesFixed=1
begin
	if @fixFactDiscrepancies = 1
		print '-- Issues have been fixed by running the commands listed above.'
	else
		print '-- Change script generated (as above) to fix the issues.'
	return
end

return
--------------------------------------
--------------------------------------
ErrorHappened:

print '-- rolling transaction back if  @@TRANCOUNT > @initialTrancount  :  ' + cast(@@TRANCOUNT as nvarchar(max)) +' > '+ cast(@initialTrancount as nvarchar(max))
print 'if @@TRANCOUNT > @initialTrancount   rollback'
if @@TRANCOUNT > @initialTrancount
begin	
	if @fixFactDiscrepancies = 1
		rollback
end

if @allIssuesFixed=0
begin
	print '-- *********************************************************'
	print '-- Looks like errors happened while running the commands listed above.'
	print ''
	print '-- Please share:'
	print '-- 	 all the messages above'
	print '--    and the result of queries in TroubleshootFactProblems.sql '
	print '-- with Microsoft Support.'
end
  
'@   
$SQL_DWFactConstraintsIssue_ForDebugging=@'
select * from etl.WarehouseEntity order by WarehouseEntityName
select * from etl.WarehouseEntity where WarehouseEntityTypeId=1 order by WarehouseEntityTypeId,WarehouseEntityName
select t.name as TableName, * from sys.check_constraints c inner join sys.tables t on c.parent_object_id=t.object_id order by t.name, c.name
SELECT * FROM etl.TablePartition order by PartitionName
select * from DateDim order by DateKey
select distinct left(name,datalength(name)/2-13)+'vw' as name from sys.check_constraints where name like '%\_____\____\_Chk' escape '\' and definition like '%DateKey%' order by 1
select name from sys.tables where name like '%\_____\____' escape '\' order by name
select t.name from sys.tables t left join sys.check_constraints c on t.object_id=c.parent_object_id where t.name like '%\_____\____' escape '\' and c.name is null order by t.name
select * from sys.objects o join sys.sql_modules m on m.object_id = o.object_id where o.type = 'V' order by name
select v.name,c.name,* from sys.columns c inner join sys.views v on c.object_id=v.object_id where v.name like '%vw' order by v.name,c.name
select tp.PartitionName,tp.RangeStartDate,tp.RangeEndDate,t.name as TableName, c.name as ConstraintName, c.definition, v.name,* 
from etl.WarehouseEntity we
left join etl.TablePartition tp on we.WarehouseEntityId=tp.EntityId 
left join sys.tables t on tp.PartitionName=t.name 
left join sys.check_constraints c on c.parent_object_id=t.object_id 
left join sys.views v on we.ViewName=v.name
where we.WarehouseEntityTypeId=1 
order by we.WarehouseEntityName, tp.PartitionName
----------------------------
/*
	These queries collects diagnostic info about Fact issues, if the CorrectFactProblems SQL script does NOT help. 
	Please run it against the DWRepository, DWDataMart, CMDWDataMart, OMDWDataMart databases.
	Please send the output of each DW database to Microsoft Support. 
	THANK YOU!
*/
set nocount on
IF OBJECT_ID('tempdb..#Result') IS NOT NULL drop table #Result
select 
	-- TP Info
	tp.PartitionName, tp.RangeStartDate, tp.RangeEndDate, tp.WarehouseEntityName as tp_WarehouseEntityName, tp.EntityId as tp_EntityId
	-- Table Info2
	,tblSub.name as TableName, left(tblSub.name ,len(tblSub.name )-9)+'vw' as CalculatedViewFromTablename
	-- Chk Info
	, chk.definition as ConstraintDefinition, chk.name as ConstraintName
	-- WE Info
	, we.WarehouseEntityId, we.WarehouseEntityName, we.WarehouseEntityTypeId, we.ViewName as we_ViewName
	-- Wet Info
	,wet.WarehouseEntityTypeName
into #Result
from etl.TablePartition tp 
	full join etl.WarehouseEntity we  on we.WarehouseEntityName=tp.WarehouseEntityName  --4513
	full join etl.WarehouseEntityType wet on we.WarehouseEntityTypeId=wet.WarehouseEntityTypeId 
	full join (select t.[name] from sys.tables t where t.[name] like '%\_____\____' escape '\'  ) as tblSub on tp.PartitionName=tblSub.name
	left join sys.check_constraints chk on OBJECT_ID(tblSub.[name])=chk.parent_object_id
where wet.WarehouseEntityTypeName='Fact' or wet.WarehouseEntityTypeName is null
order by tblSub.name

alter table #Result 
	add RowsCount bigint, MinDateKey int, MaxDateKey int, TableExistInView bit

declare @TableName sysname, @ViewName nvarchar(514), @sql nvarchar(max)
declare c cursor local FORWARD_ONLY READ_ONLY for
	select TableName, CalculatedViewFromTablename as ViewName
	from #Result where TableName is not null or CalculatedViewFromTablename is not null
open c; while 1=1 begin; fetch c into @TableName, @ViewName;if @@FETCH_STATUS<>0 break;	

	if @TableName is not null
	begin
		declare @Tbl_rowcount int, @Tbl_minDatekey int, @Tbl_maxDateKey int, @Tbl_sql as nvarchar(max)
		set @Tbl_sql=N'select @Tbl_rowcount=count(*), @Tbl_minDatekey=Min(DateKey), @Tbl_maxDateKey=Max(DateKey) from '+@TableName
		exec sp_executesql @Tbl_sql,N'@Tbl_rowcount int out, @Tbl_minDatekey int out, @Tbl_maxDateKey int out',@Tbl_rowcount out, @Tbl_minDatekey out, @Tbl_maxDateKey out
		update #Result
		set RowsCount=@Tbl_rowcount, MinDateKey=@Tbl_minDatekey, MaxDateKey=@Tbl_maxDateKey
		where TableName=@TableName
	end

	if @ViewName is not null
	begin
		declare @View_charindex int,  @View_sql as nvarchar(max)
		set @View_sql=N'
		select @View_charindex=CHARINDEX('''+@TableName+''',
					(select definition from sys.objects o join sys.sql_modules m on m.object_id = o.object_id where o.object_id = object_id('''+@ViewName+''') and o.type = ''V'')  
				)
		'
		exec sp_executesql @View_sql,N'@View_charindex int out',@View_charindex out
		update #Result
		set TableExistInView=case when @View_charindex > 0 then 1 else 0 end
		where TableName=@TableName
	end
end; close c; deallocate c;
select db_name() as DbName,* from #Result order by TableName
--
select * from etl.Configuration
--
SELECT WarehouseEntityName, wet.WarehouseEntityTypeName, we.WarehouseEntityId, wegi.RetentionPeriodInMinutes,wegi.RetentionPeriodInMinutes/60/24 as InDays,wegi.RetentionPeriodInMinutes/60/24/365 as InYears,CreatedDate,UpdatedDate
FROM etl.WarehouseEntity (nolock) we
JOIN etl.WarehouseEntityType (nolock) wet on we.WarehouseEntityTypeId = wet.WarehouseEntityTypeId 
JOIN etl.WarehouseEntityGroomingInfo (nolock) wegi on wegi.WarehouseEntityId = we.WarehouseEntityId
order by 1
--
select * from etl.WarehouseEntityGroomingHistory order by PartitionName
'@
$SQL_DWFactEntityUpgradeIssue=@'
-- https://docs.microsoft.com/en-us/system-center/scsm/upgrade-service-manager?view=sc-sm-2019#preventing-mpsync-jobs-from-railing
;WITH FactName  
AS (  
       select w.WarehouseEntityName from etl.WarehouseEntity w  
       join etl.WarehouseEntityType t on w.WarehouseEntityTypeId = t.WarehouseEntityTypeId  
       where t.WarehouseEntityTypeName = 'Fact'  
),FactList  
AS (  
    SELECT  PartitionName, p.WarehouseEntityName,  
            RANK() OVER ( PARTITION BY p.WarehouseEntityName ORDER BY PartitionName ASC ) AS RK  
    FROM    etl.TablePartition p  
       join FactName f on p.WarehouseEntityName = f.WarehouseEntityName  
)  
, FactPKList  
AS (  
    SELECT  f.WarehouseEntityName, a.TABLE_NAME, a.COLUMN_NAME, b.CONSTRAINT_NAME, f.RK,  
            CASE WHEN b.CONSTRAINT_NAME = 'PK_' + f.WarehouseEntityName THEN 1 ELSE 0 END AS DefaultConstraints  
    FROM    FactList f  
    JOIN    INFORMATION_SCHEMA.KEY_COLUMN_USAGE a ON f.PartitionName = a.TABLE_NAME  
    JOIN    INFORMATION_SCHEMA.TABLE_CONSTRAINTS b ON a.CONSTRAINT_NAME = b.CONSTRAINT_NAME AND b.CONSTRAINT_TYPE = 'Primary key'  
)  
, FactWithoutDefaultConstraints  
AS (  
    SELECT  a.*  
    FROM    FactPKList a  
    LEFT JOIN FactPKList b ON b.WarehouseEntityName = a.WarehouseEntityName AND b.DefaultConstraints = 1  
    WHERE   b.WarehouseEntityName IS NULL AND a.RK = 1  
)  
, FactPKListStr  
AS (  
    SELECT  DISTINCT f1.WarehouseEntityName, f1.TABLE_NAME, f1.CONSTRAINT_NAME, F.COLUMN_NAME AS PKList  
    FROM    FactWithoutDefaultConstraints f1  
    CROSS APPLY (  
                    SELECT  '[' + COLUMN_NAME + '],'  
                    FROM    FactWithoutDefaultConstraints f2  
                    WHERE   f2.TABLE_NAME = f1.TABLE_NAME  
                    ORDER BY COLUMN_NAME  
                FOR  
                   XML PATH('')  
                ) AS F (COLUMN_NAME)  
)  
SELECT  'ALTER TABLE [dbo].[' + f.TABLE_NAME + '] DROP CONSTRAINT [' + f.CONSTRAINT_NAME + ']' + CHAR(13) + CHAR(10) +  
        'ALTER TABLE [dbo].[' + f.TABLE_NAME + '] ADD CONSTRAINT [PK_' + f.WarehouseEntityName + '] PRIMARY KEY NONCLUSTERED (' + SUBSTRING(f.PKList, 1, LEN(f.PKList) -1) + ')' + CHAR(13) + CHAR(10)  
FROM    FactPKListStr f
OPTION (QUERYTRACEON 9481)
'@
$SQL_DWFKIssues = @'
print 'Checking for potential SSAS "The attribute key cannot be found" issues inside database:   ' + db_name()
print ''

declare @MissingRows nvarchar(max), @ParmDefinition nvarchar(max), @retval int, @MissingTables nvarchar(max), @error int, @error_message nvarchar(4000), @IssuesFound bit
declare @ForeignSchema sysname, @ForeignTable sysname, @ForeignColumn sysname, @ReferencedSchema sysname, @ReferencedTable sysname, @ReferencedColumn sysname
set @IssuesFound=0

declare c1 cursor local FORWARD_ONLY READ_ONLY for
	select fkS.name as ForeignSchema, fkT.name as ForeignTable, fkC.name as ForeignColumn, rfS.name as ReferencedSchema, rfT.name as ReferencedTable, rfC.name as ReferencedColumn	
	from DWRepository.sys.foreign_key_columns fkcols
	inner join DWRepository.sys.foreign_keys fkeys on fkcols.constraint_object_id=fkeys.object_id
	inner join DWRepository.sys.tables fkT on fkcols.parent_object_id = fkT.object_id
	inner join DWRepository.sys.columns fkC on fkcols.parent_column_id=fkC.column_id and fkcols.parent_object_id=fkC.object_id
	inner join DWRepository.sys.schemas fkS on fkT.schema_id=fkS.schema_id
	inner join DWRepository.sys.tables rfT on fkcols.referenced_object_id = rfT.object_id
	inner join DWRepository.sys.columns rfC on fkcols.referenced_column_id=rfC.column_id and fkcols.referenced_object_id=rfC.object_id
	inner join DWRepository.sys.schemas rfS on rfT.schema_id=rfS.schema_id
	where fkeys.is_disabled=0
	order by 1,2,3
open c1; while 1=1 begin; fetch c1 into @ForeignSchema, @ForeignTable, @ForeignColumn, @ReferencedSchema, @ReferencedTable, @ReferencedColumn; if @@FETCH_STATUS<>0 break;		
	set @ParmDefinition = N'@retvalOUT int OUTPUT'
	set @MissingTables='
	if (NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = ''[ForeignSchema]'' AND TABLE_NAME = ''[ForeignTable]''))
	or (NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = ''[ReferencedSchema]'' AND TABLE_NAME = ''[ReferencedTable]''))
		set @retvalOUT=1
	else
		set @retvalOUT=0
	return'	
    set @MissingTables = REPLACE(@MissingTables,'[ForeignSchema]',@ForeignSchema)
	set @MissingTables = REPLACE(@MissingTables,'[ForeignTable]',@ForeignTable)
	set @MissingTables = REPLACE(@MissingTables,'[ReferencedSchema]',@ReferencedSchema)
	set @MissingTables = REPLACE(@MissingTables,'[ReferencedTable]',@ReferencedTable)
	set @retval = 0
	exec sp_executesql @MissingTables, @ParmDefinition, @retvalOUT=@retval OUTPUT
	if @retval=1
		continue

	set @MissingRows='select @retvalOUT=count(*) from [ForeignSchema].[ForeignTable] as ForeignTable where ForeignTable.[ForeignColumn] is not null and  NOT exists(select * from [ReferencedSchema].[ReferencedTable] as ReferencedTable	where ForeignTable.[ForeignColumn]=ReferencedTable.[ReferencedColumn])'
	set @MissingRows = REPLACE(@MissingRows,'[ForeignSchema]',@ForeignSchema)
	set @MissingRows = REPLACE(@MissingRows,'[ForeignTable]',@ForeignTable)
	set @MissingRows = REPLACE(@MissingRows,'[ForeignColumn]',@ForeignColumn)
	set @MissingRows = REPLACE(@MissingRows,'[ReferencedSchema]',@ReferencedSchema)
	set @MissingRows = REPLACE(@MissingRows,'[ReferencedTable]',@ReferencedTable)
	set @MissingRows = REPLACE(@MissingRows,'[ReferencedColumn]',@ReferencedColumn)	
	set @retval = 0
	exec sp_executesql @MissingRows, @ParmDefinition, @retvalOUT=@retval OUTPUT
	select @error=@@ERROR, @error_message=error_message()

	if @error!=0  or  @retval > 0
	begin 
		if @error!=0
			print @error_message

		set @MissingRows = REPLACE(@MissingRows,'@retvalOUT=count(*)','*')
		print @MissingRows +  ' --' + cast(@retval as nvarchar(max))
		set @IssuesFound=1
	end

end; close c1; deallocate c1;
print ''
if @IssuesFound=0
	print 'No Issues found in database   ' + db_name()
else
	print 'Issues exist in database   ' + db_name() + '. Queries listed above can be investigated.'
'@
$SQL_DWEtlConfiguration='select * from etl.Configuration'
$SQL_DWEtlWarehouseEntityGroomingHistory='select * from etl.WarehouseEntityGroomingHistory'
$SQL_DWEtlWarehouseEntityGroomingInfo=@'
SELECT WarehouseEntityName, wet.WarehouseEntityTypeName, we.WarehouseEntityId, wegi.RetentionPeriodInMinutes,wegi.RetentionPeriodInMinutes/60/24 as InDays,wegi.RetentionPeriodInMinutes/60/24/365 as InYears,CreatedDate,UpdatedDate
FROM etl.WarehouseEntity (nolock) we
JOIN etl.WarehouseEntityType (nolock) wet on we.WarehouseEntityTypeId = wet.WarehouseEntityTypeId 
JOIN etl.WarehouseEntityGroomingInfo (nolock) wegi on wegi.WarehouseEntityId = we.WarehouseEntityId
order by 1
'@
    #endregion

    Collect_SQL_DWRepository
    Collect_SQL_DWDataMart
    Collect_SQL_CMDWDataMart
    Collect_SQL_OMDWDataMart

    Collect_FromSMSide

    Collect_FromSSAS
    Collect_FromSSRS
}
 