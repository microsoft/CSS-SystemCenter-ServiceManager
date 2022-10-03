function Collect_LocalSecurityPolicy() {
    (secedit.exe /export /cfg (GetFileNameInTargetFolder 'LocalSecurityPolicy_UserRightsAssignment.txt') /areas USER_RIGHTS ) | Out-Null
}