Set-PSDebug -Strict # from now on, all variables must be explicitly declared before they are used  
$Error.Clear();
Set-Location $PSScriptRoot 

#region Commit next Version
$parentPath = Split-Path -Path (Get-Location) -Parent
$versionFileName = "version.txt"
$versionFilePath = Join-Path -Path $parentPath -ChildPath $versionFileName
$currentVersionStr = (Get-Content -Path $versionFilePath | Out-String).Trim()


    [System.Version]$currentVersion = [System.Version]::Parse($currentVersionStr)   
    $nextVersion = [System.Version]::new($currentVersion.Major, $currentVersion.Minor, $currentVersion.Build + 1, 0)
    $nextVersionStr = $nextVersion.ToString()

    Set-Content -Path $versionFilePath -Value $nextVersionStr
#endregion

#todo: commit version.txt?
