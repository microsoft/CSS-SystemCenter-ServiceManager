# Correct Fact Problems

## Data Warehouse jobs may fail with errors 33502, 33503, 33522

This issue is applicable for Service Manager versions 2010, 2010 SP1, 2012, 2012 SP1, 2012 R2, 2016 (up to UR4), 1801, Forefront Identity Manager (FIM) which uses SCSM DW versions mentioned here.

# Symptom

DW Jobs fail and the Operations Manager event log contains entries like below in bold. (Please note that some parts in error messages like Job name, Table, or View names can have different values.)

 
Log Name: Operations Manager
Source: Data Warehouse
Event ID: 33502
Description:
ETL Module Execution failed:
ETL process type: Transform
Batch ID: …
Module name: TransformSLAInstanceInformationFact
Message: UNION ALL view 'DWRepository.dbo.SLAInstanceInformationFactvw' is not updatable because a partitioning column was not found.
 

Log Name: Operations Manager
Source: Data Warehouse
Event ID: 33503
Description:
An error countered while attempting to execute ETL Module:
ETL process type: Load
Batch ID: …
Module name: LoadEntityManagedTypeFact
Message: UNION ALL view 'DWDatamart.dbo.EntityManagedTypeFactvw' is not updatable because a partitioning column was not found.

Log Name: Operations Manager
Source: Data Warehouse
Event ID: 33522
Level: Error
Description:
Unhandled exception in data warehouse maintenance:
Work item: …
Maintenance action: PerformWarehouseGrooming Exception details:
Exception message: ErrorNumber="50000" Message="ErrorNumber="50000" Message="ErrorNumber="547" Message="The ALTER TABLE statement conflicted with the CHECK constraint "ChangeRequestStatusDurationFact_2020_Dec_Chk". The conflict occurred in database "DWRepository", table "dbo.ChangeRequestStatusDurationFact_2020_Dec", column 'DateKey'." Severity="16" State="0" ProcedureName="(null)" LineNumber="1" Task="Executing CHKScriptTemplate"" Severity="18" State="0" ProcedureName="DropCheckConstraintForTable" LineNumber="145" Task="Opening MIN Check constraint for the next Partition"" Severity="18" State="0" ProcedureName="DropPartition" LineNumber="108" Task="Executing groomingStoredProcedure: EXEC etl.DropPartition @WarehouseEntityId=@WarehouseEntityId, @WarehouseEntityType=@WarehouseEntityType, @EntityGuid=@EntityGuid, @PartitionId=@PartitionId, @GroomActiveRelationship=1"

## Cause

Internal background modules maintain monthly partitions on DW Fact tables. These modules were interrupted because values in DateDim table end on Dec 30th, 2020 (only in SM versions mentioned above).

This caused discrepancies between check constraints on Fact tables and some other internal tables. In the end, DW jobs like DWMaintenance, Transform, and Load jobs are failing.

## Resolution

The solution is to fix the corrupted partitions. The script [CorrectFactProblemsV7.3.sql](https://github.com/microsoft/CSS-SystemCenter-ServiceManager/releases/latest/download/Verify_SSRS_for_SCSM.ps1) is written for this purpose. Run it against the DWRepository + 3 DataMart databases and then Resume the Failed jobs. 

You may run the same script the 2nd time for verification. This time it should end with "-- No issues found."

If jobs still fail with the errors mentioned above, then please contact Microsoft Support.

## More information
	
It's OK to run the script many times, just for verification. If no issues exist, the script won't make any changes in the DW databases.
	SCSM 2019 installations already have the correct values in DateDim table. Therefore, SCSM DW installations with version 2019 do not face this issue.
	To prevent this issue to happen, the values in DateDim tables were proactively extended with SCSM 2016 Update Rollup 5. Therefore, SCSM DW 2016 installations on which UR5 was applied before Dec 1st, 2020, do not face this issue.
	Applying 2016 UR5 now, will not help.

## Do you want to contribute to this tool?

[Here](https://github.com/khusmeno-MS/CSS-SystemCenter-ServiceManager/tree/main/CorrectFactProblems) is the GitHub repo.
