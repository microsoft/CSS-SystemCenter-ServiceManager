function Collect_SsasCubes() {
    AppendOutputToFileInTargetFolder ($SsasDB.Cubes | ft -Property CreatedTimestamp,LastSchemaUpdate,State,LastProcessed,Name, Dimensions -Wrap) "SsasCubes.txt"
}