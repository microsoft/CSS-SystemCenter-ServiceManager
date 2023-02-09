function Collect_SMDBInfo() {
    AppendOutputToFileInTargetFolder ($SMDBInfo | ConvertTo-Csv -NoTypeInformation) SQL_SMDB_Info.csv
}