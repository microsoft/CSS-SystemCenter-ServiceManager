function Collect_SQL_DWDataMart() {
    $SQL_SCSM_DWDM =@{}
    $SQL_SCSM_DWDM['SQL_TableSizeInfo_DWDataMart']=$SQL_SCSM_Shared['SQL_TableSizeInfo']
    $SQL_SCSM_DWDM['SQL_DwDMDataRetention'] = @'
    select etl.GetConfigurationInfo('dwmaintenance.grooming', 'RetentionPeriodInMinutes.Default')/60/24 as "DWDatamart data retention in days",etl.GetConfigurationInfo('dwmaintenance.grooming', 'RetentionPeriodInMinutes.Default')/60/24/365 as "DWDatamart data retention in years"
'@
    $SQL_SCSM_DWDM['SQL_DWFactConstraintsIssue_DWDatamart']=$SQL_DWFactConstraintsIssue
#    $SQL_SCSM_DWDM['SQL_DWFactConstraintsIssue_DWDatamart_ForDebugging']=$SQL_DWFactConstraintsIssue_ForDebugging
    $SQL_SCSM_DWDM['SQL_FKIssuesInDW_DWDatamart']=$SQL_DWFKIssues
    $SQL_SCSM_DWDM['SQL_DWFactEntityUpgradeIssue_DWDataMart']=$SQL_DWFactEntityUpgradeIssue
    $SQL_SCSM_DWDM['SQL_DWEtlConfiguration_DWDataMart']=$SQL_DWEtlConfiguration
    $SQL_SCSM_DWDM['SQL_DWEtlWarehouseEntityGroomingHistory_DWDataMart']=$SQL_DWEtlWarehouseEntityGroomingHistory
    $SQL_SCSM_DWDM['SQL_DWEtlWarehouseEntityGroomingInfo_DWDataMart']=$SQL_DWEtlWarehouseEntityGroomingInfo
    $SQL_SCSM_DWDM['SQL_information_schema_columns_DWDataMart']=$SQL_SCSM_Shared['SQL_information_schema_columns']
    $SQL_SCSM_DWDM['SQL_indexes_DWDataMart']=$SQL_SCSM_Shared['SQL_indexes']

    foreach($SQL_SCSM_DWDM_Text in $SQL_SCSM_DWDM.Keys) {

        RamSB -outputString "$SQL_SCSM_DWDM_Text.csv" -pscriptBlock `        {
            SaveSQLResultSetsToFiles $SQLInstance_SCSMDW_DM $SQLDatabase_SCSMDW_DM ($SQL_SCSM_DWDM[$SQL_SCSM_DWDM_Text]) "$SQL_SCSM_DWDM_Text.csv"    
        }
    }
}