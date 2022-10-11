declare @fixFactDiscrepancies bit = 1	-- set this to 1 for real corrections, but Please take a database backup before !!!
										-- set this to 0 to only show the discrepancies and generate a change script to be applied manually.
--------------------------------------------------------------------
--v7.3
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
--check if etl.TablePartition.EntityId = etl.WarehouseEntity.WarehouseEntityId
--we assume the EntityId in WarehouseEntity is correct
declare @countOfWrongEntityIDsInTP int --7.3
select @countOfWrongEntityIDsInTP = count(*)
    from etl.WarehouseEntity we 
    inner join etl.TablePartition tp  
    on we.WarehouseEntityName = tp.WarehouseEntityName 
    where we.WarehouseEntityTypeId = 1 --Fact
    and we.WarehouseEntityId != tp.EntityId

if @countOfWrongEntityIDsInTP > 0
begin    
	set @overallIssuesFound = 1
	print '--Wrong EntityIDs found In etl.TablePartition. Count => ' + cast(@countOfWrongEntityIDsInTP as nvarchar(max))

	declare @fixWrongEntityIDsInTP_Script nvarchar(max)
	set @fixWrongEntityIDsInTP_Script='update tp
set tp.EntityId = sub.WarehouseEntityId
from etl.TablePartition tp
inner join (
	select tp.PartitionId, we.WarehouseEntityId
	from etl.TablePartition tp 
	left join etl.WarehouseEntity we on tp.WarehouseEntityName = we.WarehouseEntityName
	where tp.EntityId != we.WarehouseEntityId
	and we.WarehouseEntityTypeId = 1
) as sub on tp.PartitionId = sub.PartitionId'

	if @fixFactDiscrepancies = 0
	begin
		print ''
		print '-- ************* ! ATTENTION ! ****************************************************'
		print '-- In order to continue this script, the command below has to be executed. However, as this script is currently running in Read-only mode, this script will now ABORT.'
		print '-- Please copy the command below & execute it manually and then re-run this script.'
		print ''
		print 'use '+ DB_NAME()
		print @fixWrongEntityIDsInTP_Script

		return
	end
	else
	begin
		print @fixWrongEntityIDsInTP_Script
		print ''
		begin try			
			exec sp_executesql @fixWrongEntityIDsInTP_Script												
		end try
		begin catch
			set @allIssuesFixed = 0
			print 'Error happened with: ' + @fixWrongEntityIDsInTP_Script
			print ERROR_MESSAGE()
			goto ErrorHappened
		end catch		
	end
end

-------------------------------------------------------------------------------------------
print '-- **************************************************************************'
print '-- **  Running the script can take long. Please wait until completed.   *****'
print '-- **************************************************************************'
print ''

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

		-----------------------------------------------------------------------------------------------------
		-- Fix missing/nullable PK on Fact tables
		declare @PKColumnsList NVARCHAR(MAX),@PartitionToCopyPropertiesFrom NVARCHAR(512),@WarehouseEntityId INT, @PartitionName nvarchar(max), @ColName nvarchar(max)
		declare @NullablePKCols TABLE (sql1 nvarchar(max), PartitionName nvarchar(max), ColName nvarchar(max))

		select @WarehouseEntityId = tp.EntityId
		from etl.TablePartition tp
		where PartitionName = @factTableName

		SELECT  @PartitionToCopyPropertiesFrom = MAX(PartitionName)
		FROM etl.TablePartition tblPar
		inner join sys.key_constraints sysPK on
				OBJECT_ID(tblPar.PartitionName) = sysPK.parent_object_id
		WHERE EntityId = @WarehouseEntityId
			and sysPK.type = 'PK'

		set @PartitionName = @factTableName

		delete @NullablePKCols
		insert into @NullablePKCols    
		SELECT  ' alter table '+ @PartitionName +' alter column '+ PKCols.name+' '+ t.name +' not null' as sql1, @PartitionName, PKCols.name
		FROM       sys.key_constraints PK
		INNER JOIN sys.indexes PKIdx ON PKIdx.name = PK.name
		INNER JOIN sys.index_columns PKIdxCols ON PKIdx.object_id = PKIdxCols.object_id AND PKIdx.index_id = PKIdxCols.index_id
		INNER JOIN sys.columns PKCols on PKIdxCols.object_id = PKCols.object_id AND PKIdxCols.column_id = PKCols.column_id
		INNER JOIN sys.columns TpCols on TpCols.object_id = object_id(@PartitionName) and TpCols.name = PKCols.name and TpCols.is_nullable=1
		inner join sys.types t on PKCols.user_type_id = t.user_type_id
		WHERE       PK.parent_object_id = OBJECT_ID(@PartitionToCopyPropertiesFrom)
			AND     PK.type = 'PK'            
		ORDER by    PKIdxCols.index_column_id DESC
 
		if (select count(*) from @NullablePKCols) > 0
		begin
			set @overallIssuesFound = 1; set @issuesFoundForFact = 1;

			--remove index if it has any column that participates in potential PK columns
			declare @sql1 nvarchar(max)
			declare c1 cursor local FORWARD_ONLY READ_ONLY for
				select sql1, PartitionName, ColName from @NullablePKCols
			open c1; while 1=1 begin; fetch c1 into @sql1, @PartitionName, @ColName; if @@FETCH_STATUS<>0 break;
 
				declare @idxName sysname, @tblName sysname
				declare @sql2 nvarchar(max)
				declare c2 cursor local FORWARD_ONLY READ_ONLY for
					select i.name idxName, t.name tblName
					from sys.index_columns ix
						inner join sys.tables t on ix.object_id=t.object_id
						inner join sys.indexes i on ix.object_id=i.object_id and ix.index_id=i.index_id
						inner join sys.columns c on ix.object_id=c.object_id and ix.column_id=c.column_id
					where t.name=@PartitionName
						and c.name=@ColName
				open c2; while 1=1 begin; fetch c2 into @idxName, @tblName; if @@FETCH_STATUS<>0 break;
					set @sql2='if (select count(*) from sys.indexes where name = ''' + @idxName +''') = 1  drop index '+@idxName+' on '+@tblName
					print @sql2

					if @fixFactDiscrepancies = 1
					begin	
						begin try
							exec sp_executesql @sql2														
						end try
						begin catch
							set @allIssuesFixed = 0
							print 'Error happened with: ' + @sql2
							print ERROR_MESSAGE()
							goto ErrorHappened
						end catch
					end
				end; close c2; deallocate c2;
 
				print @sql1
				if @fixFactDiscrepancies = 1
				begin	
					begin try
						exec sp_executesql @sql1														
					end try
					begin catch
						set @allIssuesFixed = 0
						print 'Error happened with: ' + @sql1
						print ERROR_MESSAGE()
						goto ErrorHappened
					end catch
				end
 
			end; close c1; deallocate c1;

			declare @CreatePrimaryKeyForPartition_Script nvarchar(max)
			set @CreatePrimaryKeyForPartition_Script = ' exec [etl].[CreatePrimaryKeyForPartition] ' +  cast(@WarehouseEntityId as nvarchar(max)) + ', ''' + cast(@PartitionName as nvarchar(max)) + ''''
			print @CreatePrimaryKeyForPartition_Script
			if @fixFactDiscrepancies = 1
			begin	
				begin try
					exec sp_executesql @CreatePrimaryKeyForPartition_Script														
				end try
				begin catch
					set @allIssuesFixed = 0
					print 'Error happened with: ' + @CreatePrimaryKeyForPartition_Script
					print ERROR_MESSAGE()
					goto ErrorHappened
				end catch
			end

		end
		-----------------------------------------------------------------------------------------------------

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
	if @tmpFact_Created=1
	begin
		-----------------------------------------------------------------------------------------------------------------------------------------------------------
		--deleting rows from Tmp_...Fact which already exists in fact tables. v7.3		
		declare @existingRowsInTmpFact_Script nvarchar(max), @PkColumnComparisons nvarchar(max)
		set @PkColumnComparisons = '1=1'

		SELECT  @PkColumnComparisons = @PkColumnComparisons + ' and vw.' + PKCols.name + ' = tmp.' + PKCols.name
		FROM        sys.key_constraints PK
		INNER JOIN  sys.indexes PKIdx ON PKIdx.name = PK.name
		INNER JOIN  sys.index_columns PKIdxCols ON PKIdx.object_id = PKIdxCols.object_id AND PKIdx.index_id = PKIdxCols.index_id
		INNER JOIN  sys.columns PKCols on PKIdxCols.object_id = PKCols.object_id AND PKIdxCols.column_id = PKCols.column_id
		WHERE       PK.parent_object_id = OBJECT_ID(@PartitionToCopyPropertiesFrom)
			AND     PK.type = 'PK'            
		ORDER by    PKIdxCols.index_column_id DESC

		set @existingRowsInTmpFact_Script = ' delete tmp from Tmp_'+@factName +' tmp where exists(select * from '+@factName+'vw vw where ' +@PkColumnComparisons + ');'
		print @existingRowsInTmpFact_Script

		if @fixFactDiscrepancies = 1
		begin	
			begin try
				exec sp_executesql @existingRowsInTmpFact_Script										
			end try
			begin catch
				set @allIssuesFixed = 0
				print 'Error happened with: ' + @existingRowsInTmpFact_Script
				print ERROR_MESSAGE()
				goto ErrorHappened
			end catch
		end
		-----------------------------------------------------------------------------------------------------------------------------------------------------------
			   
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
		print '-- Issues have been fixed by running the commands listed above. You can re-run this script for verification.'
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
