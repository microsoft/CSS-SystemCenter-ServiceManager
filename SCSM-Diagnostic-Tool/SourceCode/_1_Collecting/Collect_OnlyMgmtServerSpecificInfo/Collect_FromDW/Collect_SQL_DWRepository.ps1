function Collect_SQL_DWRepository() {
    $SQL_SCSM_DWRep =@{}
    $SQL_SCSM_DWRep['SQL_TableSizeInfo_DWRepository']=$SQL_SCSM_Shared['SQL_TableSizeInfo']
    $SQL_SCSM_DWRep['SQL_DWFactConstraintsIssue_DWRep']=$SQL_DWFactConstraintsIssue
#    $SQL_SCSM_DWRep['SQL_DWFactConstraintsIssue_DWRep_ForDebugging']=$SQL_DWFactConstraintsIssue_ForDebugging
    $SQL_SCSM_DWRep['SQL_DWFactEntityUpgradeIssue_DWRep']=$SQL_DWFactEntityUpgradeIssue
    $SQL_SCSM_DWRep['SQL_DWEtlConfiguration_DWRep']=$SQL_DWEtlConfiguration
    $SQL_SCSM_DWRep['SQL_DWEtlWarehouseEntityGroomingHistory_DWRep']=$SQL_DWEtlWarehouseEntityGroomingHistory
    $SQL_SCSM_DWRep['SQL_DWEtlWarehouseEntityGroomingInfo_DWRep']=$SQL_DWEtlWarehouseEntityGroomingInfo
    $SQL_SCSM_DWRep['SQL_information_schema_columns_DWRep']=$SQL_SCSM_Shared['SQL_information_schema_columns']
    $SQL_SCSM_DWRep['SQL_indexes_DWRep']=$SQL_SCSM_Shared['SQL_indexes']
    $SQL_SCSM_DWRep['SQL_DbUsersInfo_DWRep']=$SQL_SCSM_Shared['SQL_DbUsersInfo']

    foreach($SQL_SCSM_DWRep_Text in $SQL_SCSM_DWRep.Keys) { 
        SaveSQLResultSetsToFiles $SQLInstance_SCSMDW_Rep $SQLDatabase_SCSMDW_Rep ($SQL_SCSM_DWRep[$SQL_SCSM_DWRep_Text]) "$SQL_SCSM_DWRep_Text.csv"    
    }
}