function Collect_EnvironmentVariables() {
    AppendOutputToFileInTargetFolder (dir env:* | ConvertTo-Csv -NoTypeInformation) "EnvVars.csv"
}
