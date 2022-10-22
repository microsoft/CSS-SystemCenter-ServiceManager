function Collect_TLS() {
    CreateNewFolderInTargetFolder "TLS"

    Reg export "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders" (GetFileNameInTargetFolder "TLS\SecurityProviders.txt")| Out-Null
    Reg export "HKLM\SOFTWARE\Microsoft\.NETFramework" (GetFileNameInTargetFolder "TLS\NETFramework.txt")| Out-Null
    Reg export "HKLM\SOFTWARE\WOW6432Node\Microsoft\.NETFramework" (GetFileNameInTargetFolder "TLS\WOW6432Node_NETFramework.txt")| Out-Null 
}