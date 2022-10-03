function Collect_SsrsVersion() {
    AppendOutputToFileInTargetFolder (Invoke-WebRequest -Uri ($SsrsUrl.Replace("ReportService2005.asmx","")) -UseDefaultCredentials -UseBasicParsing).Content "Ssrs-Version.txt"
}