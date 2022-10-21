function Collect_SystemCenterRegValues() {
    Reg export "HKLM\SOFTWARE\Microsoft\System Center" (GetFileNameInTargetFolder "SystemCenter.regValues.txt")| Out-Null
}