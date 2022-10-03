function Collect_SsasDimensions() {
    AppendOutputToFileInTargetFolder ($SsasDB.Dimensions | ft -Property CreatedTimestamp,LastSchemaUpdate,State,LastProcessed,Name -Wrap) "SsasDimensions.txt"
}