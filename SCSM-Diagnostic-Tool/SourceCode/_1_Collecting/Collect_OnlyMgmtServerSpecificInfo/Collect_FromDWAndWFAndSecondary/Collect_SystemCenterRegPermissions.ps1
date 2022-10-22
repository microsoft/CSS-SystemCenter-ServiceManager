function Collect_SystemCenterRegPermissions() {
    AppendOutputToFileInTargetFolder (Get-ChildItem "HKLM:\SOFTWARE\Microsoft\System Center" -Recurse | % {$_.Name; (Get-Acl -Path $_.PSPath).Access} ) "SystemCenter.regPermissions.txt"
}