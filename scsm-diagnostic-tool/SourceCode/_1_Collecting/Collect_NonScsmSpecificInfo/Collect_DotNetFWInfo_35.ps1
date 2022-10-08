function Collect_DotNetFWInfo_35() {
    Reg export "HKLM\SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.5" (GetFileNameInTargetFolder "DotNetFwV3.5.txt")| Out-Null
}