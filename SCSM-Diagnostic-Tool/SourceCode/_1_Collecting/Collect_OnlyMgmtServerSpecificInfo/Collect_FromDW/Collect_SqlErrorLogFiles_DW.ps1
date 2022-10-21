function Collect_SqlErrorLogFiles_DW() {
    GetSqlErrorLogFiles (GetMachineNameFromSqlInstance $SQLInstance_SCSMDW) $SQLDatabase_SCSMDW
}