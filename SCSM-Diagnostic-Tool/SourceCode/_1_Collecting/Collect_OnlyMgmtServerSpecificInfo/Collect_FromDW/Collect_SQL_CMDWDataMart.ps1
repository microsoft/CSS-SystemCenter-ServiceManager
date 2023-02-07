function Collect_SQL_CMDWDataMart() {
    if ($SQLInstance_SCSMDW_CMDM -ne $null  -and  $SQLDatabase_SCSMDW_CMDM -ne $null) {
        $SQL_SCSM_DWCMDM =@{}
        $SQL_SCSM_DWCMDM['SQL_TableSizeInfo_CMDWDataMart']=$SQL_SCSM_Shared['SQL_TableSizeInfo']
        $SQL_SCSM_DWCMDM['SQL_DWFactConstraintsIssue_CMDWDatamart']=$SQL_DWFactConstraintsIssue
#        $SQL_SCSM_DWCMDM['SQL_DWFactConstraintsIssue_CMDWDatamart_ForDebugging']=$SQL_DWFactConstraintsIssue_ForDebugging
        $SQL_SCSM_DWCMDM['SQL_FKIssuesInDW_CMDWDatamart']=$SQL_DWFKIssues
        $SQL_SCSM_DWCMDM['SQL_DWFactEntityUpgradeIssue_CMDWDataMart']=$SQL_DWFactEntityUpgradeIssue
        $SQL_SCSM_DWCMDM['SQL_DWEtlConfiguration_CMDWDataMart']=$SQL_DWEtlConfiguration
        $SQL_SCSM_DWCMDM['SQL_DWEtlWarehouseEntityGroomingHistory_CMDWDataMart']=$SQL_DWEtlWarehouseEntityGroomingHistory
        $SQL_SCSM_DWCMDM['SQL_DWEtlWarehouseEntityGroomingInfo_CMDWDataMart']=$SQL_DWEtlWarehouseEntityGroomingInfo
        $SQL_SCSM_DWCMDM['SQL_information_schema_columns_CMDWDataMart']=$SQL_SCSM_Shared['SQL_information_schema_columns']
        $SQL_SCSM_DWCMDM['SQL_indexes_CMDWDataMart']=$SQL_SCSM_Shared['SQL_indexes']

        foreach($SQL_SCSM_DWCMDM_Text in $SQL_SCSM_DWCMDM.Keys) {        
            SaveSQLResultSetsToFiles $SQLInstance_SCSMDW_CMDM $SQLDatabase_SCSMDW_CMDM ($SQL_SCSM_DWCMDM[$SQL_SCSM_DWCMDM_Text]) "$SQL_SCSM_DWCMDM_Text.csv"    
        }
    }
}