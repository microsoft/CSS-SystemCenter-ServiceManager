function Collect_SPNs() {
    AppendOutputToFileInTargetFolder (Invoke-Expression "setspn.exe -q MSOMSdkSvc/$((Get-Item -path Env:COMPUTERNAME).Value)*") spnSDK.txt
    AppendOutputToFileInTargetFolder (Invoke-Expression "setspn.exe -q MSOMHSvc/$((Get-Item -path Env:COMPUTERNAME).Value)*") spnHS.txt

#    StartProcessAsync -processFileName "setspn.exe" -argsToProcess "-X" -outputFileName "spnX.txt" #starting async bcz this can take long

    Start_Async -code { setspn.exe -X } -outputFileName "spnX.txt"    
}