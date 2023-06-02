function Collect_SsrsVersion() {
    AppendOutputToFileInTargetFolder ( InvokeWebRequest_WithProxy -Uri ($SsrsUrl.Replace("ReportService2005.asmx","")) ).Content "Ssrs-Version.txt"
}