function Collect_Test_SsrsWebService() {
    AppendOutputToFileInTargetFolder ( InvokeWebRequest_WithProxy -Uri $SsrsUrl) "Ssrs-TestUrl.txt"
}