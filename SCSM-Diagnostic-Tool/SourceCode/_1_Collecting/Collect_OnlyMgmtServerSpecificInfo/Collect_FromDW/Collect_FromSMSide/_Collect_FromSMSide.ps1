function Collect_FromSMSide() {

#Collects for MpSync & Extract and other info from SM Side (DB and SDK)

    #region DO NOT MOVE THIS! To be used in subsequent functions
    $SQL_SMDBInfo=@'
    select DataSourceName_AC09B683_AE61_BDCA_6383_2007DB60859D as DataSourceName_SMDB,DatabaseServer_CD2D9C2A_39C2_CE05_D84C_AC42E429D191 as SQLInstance_SMDB,Database_D59DC40A_E438_1A05_C231_E3BD50E5DD44 as SQLDatabase_SMDB,SdkServer_0E227991_743F_4854_FF8B_273C1688DFEB  as SDKServer_SMDB from MTV_Microsoft$SystemCenter$DataWarehouse$CMDBSource where BaseManagedEntityId in (select BaseManagedEntityId from BaseManagedEntity where BaseManagedTypeId='0222340F-D0CD-6B06-70A6-AA0A1504F428' and name not like 'DW\_%' escape'\')
'@
    $SMDBInfo = (Try-Invoke-SqlCmd -SQLInstance $SQLInstance_SCSMDW -SQLDatabase $SQLDatabase_SCSMDW -Query $SQL_SMDBInfo).Tables[0]
    #endregion    
    
    Collect_SMDBInfo
    Collect_ForMPSyncJob    
    Collect_ForExtractJob
    Collect_SQL_SMDB
}