function Collect_SPNs() {
    AppendOutputToFileInTargetFolder (Invoke-Expression "setspn.exe -q MSOMSdkSvc/$((Get-Item -path Env:COMPUTERNAME).Value)*") spnSDK.txt
    AppendOutputToFileInTargetFolder (Invoke-Expression "setspn.exe -q MSOMHSvc/$((Get-Item -path Env:COMPUTERNAME).Value)*") spnHS.txt
    AppendOutputToFileInTargetFolder (Invoke-Expression "setspn.exe -X") spnX.txt
}