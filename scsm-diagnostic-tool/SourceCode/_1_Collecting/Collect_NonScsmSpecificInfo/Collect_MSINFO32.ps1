function Collect_MSINFO32() {
#Starting MSINFO32 in the background
 
    Start-Job -ScriptBlock {
        Start-Process msinfo32.exe -Wait -ArgumentList $input 
    } -InputObject  "/report ""$((GetFileNameInTargetFolder "msinfo32.txt"))""" | Out-Null
}