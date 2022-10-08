function Collect_HealthServiceStateFolder() {
    Copy-Item -Path (Join-Path -Path ((Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\System Center\2010\Service Manager\Setup').InstallDirectory) -ChildPath  "Health Service State") -Destination (GetFileNameInTargetFolder "Health Service State") -Recurse  -ErrorAction SilentlyContinue
}