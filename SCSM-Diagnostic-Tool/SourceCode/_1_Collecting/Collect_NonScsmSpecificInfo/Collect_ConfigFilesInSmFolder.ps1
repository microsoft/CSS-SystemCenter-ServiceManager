function Collect_ConfigFilesInSmFolder() {
# TODO: this should be excluded for PortalOnly
    $targetFolder = "SMFolder"
    CreateNewFolderInTargetFolder $targetFolder
    Get-ChildItem -Path (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\System Center\2010\Service Manager\Setup').InstallDirectory -Filter *.config | Copy-Item -Destination (GetFileNameInTargetFolder $targetFolder) -ErrorAction SilentlyContinue
    
}