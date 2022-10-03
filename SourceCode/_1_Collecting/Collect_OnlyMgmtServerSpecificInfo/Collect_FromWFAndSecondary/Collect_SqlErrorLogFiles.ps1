function Collect_SqlErrorLogFiles() {
    GetSqlErrorLogFiles (GetMachineNameFromSqlInstance $SQLInstance_SCSM) $SQLDatabase_SCSM
}