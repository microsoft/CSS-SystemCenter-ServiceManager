function Collect_SCSMSetupLogFiles() {
    Get-ChildItem -Path "$env:SystemDrive\users\*\appdata\local\temp" -Include SCSM*.log -Recurse -Force -ErrorAction SilentlyContinue | % {
            $UpDir1 = $_.Directory;$UpDir2 = $UpDir1.Parent;$UpDir3 = $UpDir2.Parent;$UpDir4 = $UpDir3.Parent;
            if ($UpDir1.Name -eq "Temp" -and $UpDir2.Name -eq "local" -and $UpDir3.Name -eq "appdata") {
                $userFolderName=$UpDir3.Parent;
                CopyFileToTargetFolder $_.FullName "SCSM_SetupLogFiles\$userFolderName"
            }    
    } -ErrorAction SilentlyContinue
}