function Collect_DotNetFWInfo_4() {
    Reg export "HKLM\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4"   (GetFileNameInTargetFolder "DotNetFwV4.txt")| Out-Null
}