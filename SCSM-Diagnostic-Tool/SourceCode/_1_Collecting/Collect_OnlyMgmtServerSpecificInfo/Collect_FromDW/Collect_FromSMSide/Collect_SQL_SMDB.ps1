function Collect_SQL_SMDB() {
    $SQL_FromSMDB =@{}
    $SQL_FromSMDB['SQL_FromSMDB_MOMManagementGroupInfo']=@'
select * from [dbo].[__MOMManagementGroupInfo__] 
'@
    $SQL_FromSMDB['SQL_FromSMDB_PatchInfo']=@'
select * from [dbo].[__PatchInfo__]  -- if table doesn't exist then it's RTM, check also DBVersion in   __MOMManagementGroupInfo__
'@
    $SQL_FromSMDB['SQL_FromSMDB_WorkItemsCount']=@'
select count(*) 'IR count in SMDB', min(CreatedDate_6258638D_B885_AB3C_E316_D00782B8F688) as "Oldest",max(CreatedDate_6258638D_B885_AB3C_E316_D00782B8F688) as "Newest" from [dbo].[MT_System$WorkItem$Incident]
select count(*) 'SR count in SMDB', min(CreatedDate_6258638D_B885_AB3C_E316_D00782B8F688) as "Oldest",max(CreatedDate_6258638D_B885_AB3C_E316_D00782B8F688) as "Newest" from [dbo].[MT_System$WorkItem$ServiceRequest] 
select count(*) 'CR count in SMDB', min(CreatedDate_6258638D_B885_AB3C_E316_D00782B8F688) as "Oldest",max(CreatedDate_6258638D_B885_AB3C_E316_D00782B8F688) as "Newest" from [dbo].[MT_System$WorkItem$ChangeRequest]
'@
    $SQL_FromSMDB['SQL_FromSMDB_WorkItemsCount_ByMonth']=@'
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
    $SQL_FromSMDB['SQL_FromSMDB_DataRetention']=@'
SELECT gc.RetentionPeriodInMinutes/60/24 as Days, mt.TypeName
FROM [dbo].[MT_GroomingConfiguration] gc
	inner join ManagedType mt on gc.TargetId=mt.ManagedTypeId
where StoredProcedure='p_GroomManagedEntity'
order by 1
'@
    foreach($SQL_FromSMDB_Text in $SQL_FromSMDB.Keys) {        
        SaveSQLResultSetsToFiles $($SMDBInfo.SQLInstance_SMDB) $($SMDBInfo.SQLDatabase_SMDB) ( $SQL_FromSMDB[$SQL_FromSMDB_Text] ) "$SQL_FromSMDB_Text.csv"    
    }

}