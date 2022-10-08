function Collect_Test_SsrsWebService() {
    AppendOutputToFileInTargetFolder (Invoke-WebRequest -Uri $SsrsUrl -UseDefaultCredentials -UseBasicParsing) "Ssrs-TestUrl.txt"
}