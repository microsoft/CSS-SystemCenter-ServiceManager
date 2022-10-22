function Collect_MGRegistryValues() {
    Reg export "HKLM\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Server Management Groups" (GetFileNameInTargetFolder "ServerManagementGroups.regValues.txt")| Out-Null
}