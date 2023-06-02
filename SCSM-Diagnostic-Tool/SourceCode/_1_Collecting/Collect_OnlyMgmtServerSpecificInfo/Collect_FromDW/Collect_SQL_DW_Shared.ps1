function Collect_SQL_DW_Shared() {
    foreach($SqlSharedText in $SQL_SCSM_Shared.Keys) { 
           
        RamSB -outputString "$SqlSharedText.csv" -pscriptBlock `        {
            SaveSQLResultSetsToFiles $SQLInstance_SCSMDW $SQLDatabase_SCSMDW ($SQL_SCSM_Shared[$SqlSharedText]) "$SqlSharedText.csv"
        }   
         
    }
}