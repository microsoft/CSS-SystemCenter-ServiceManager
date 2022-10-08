function Collect_SQL_MS_Shared() {
    foreach( $SqlSharedText in $SQL_SCSM_Shared.Keys ) {        
        SaveSQLResultSetsToFiles $SQLInstance_SCSM $SQLDatabase_SCSM ( $SQL_SCSM_Shared[$SqlSharedText] ) "$SqlSharedText.csv"    
    }
}
