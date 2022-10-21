function Collect_ForExtractJob() {
    $SqlTestToSMDB = (Try-Invoke-SqlCmd -SQLInstance ($SMDBInfo.SQLInstance_SMDB) -SQLDatabase ($SMDBInfo.SQLDatabase_SMDB) -Query "select 'OK' as 'SqlPingResultFromDWToSMDB' ").Tables[0].SqlPingResultFromDWToSMDB    
    if ($SqlTestToSMDB -eq "OK") {    
        AppendOutputToFileInTargetFolder "OK with user: $env:UserDomain\$env:USERNAME" "ForExtractJob_SqlPing_FromDW_ToSMDB.txt"
    }
    else {
        AppendOutputToFileInTargetFolder "ERROR with user: $env:UserDomain\$env:USERNAME to SQLInstance:($SMDBInfo.SQLInstance_SMDB)  DB:($SMDBInfo.SQLDatabase_SMDB)" "ForExtractJob_SqlPing_FromDW_ToSMDB.txt"
    }

    $sqlUserforExtract = Get-SCSMRunAsAccount -DisplayName "$($SMDBInfo.DataSourceName_SMDB) SecureReference"
    if ($sqlUserforExtract.Domain -ne $env:UserDomain  -or  $sqlUserforExtract.UserName -ne $env:USERNAME) {
        AppendOutputToFileInTargetFolder "`nAttention! Extract Job is actually using account: $($sqlUserforExtract.Domain)\$($sqlUserforExtract.UserName). This is different than the current user:$env:UserDomain\$env:USERNAME" "ForExtractJob_SqlPing_FromDW_ToSMDB.txt"
        AppendOutputToFileInTargetFolder "Please check result of   Get-SCSMRunAsAccount. The result of this test may not be the same as the actual Extract job." "ForExtractJob_SqlPing_FromDW_ToSMDB.txt"
    }

    SaveSQLResultSetsToFiles ($SMDBInfo.SQLInstance_SMDB) ($SMDBInfo.SQLDatabase_SMDB) "dbcc useroptions" "ForExtractJob_dbcc_useroptions_FromDW_ToSMDB.txt" 
    if ($sqlUserforExtract.Domain -ne $env:UserDomain  -or  $sqlUserforExtract.UserName -ne $env:USERNAME) {
        AppendOutputToFileInTargetFolder "`nAttention! Extract Job is actually using account: $($sqlUserforExtract.Domain)\$($sqlUserforExtract.UserName). This is different than the current user:$env:UserDomain\$env:USERNAME" "ForExtractJob_dbcc_useroptions_FromDW_ToSMDB.txt"
        AppendOutputToFileInTargetFolder "Please check result of   Get-SCSMRunAsAccount. The result of this test may not be the same as the actual Extract job." "ForExtractJob_dbcc_useroptions_FromDW_ToSMDB.txt"
    }
}