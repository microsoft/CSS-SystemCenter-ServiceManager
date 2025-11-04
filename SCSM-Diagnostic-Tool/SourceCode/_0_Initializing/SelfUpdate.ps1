function SelfUpdate() {
    try {        
        if ( $Script:MyInvocation.UnboundArguments.Contains("-noSelfUpdate") ) { return $false }

        $amIRunningAsSigned = AmIRunningAsSigned
        if (!$amIRunningAsSigned) { return $false }
        
        $uriApi = "https://api.github.com/repos/microsoft/css-systemcenter-servicemanager/releases/latest"
        $newVersionStr = ( (InvokeWebRequest_WithProxy -uri $uriApi -timeoutSec 3) | ConvertFrom-Json).tag_name.Replace("v","")
        $newVersion = New-Object version -ArgumentList $newVersionStr

        $currentVersion = New-Object version -ArgumentList (GetToolVersion)
        if ($newVersion -le $currentVersion) { return $false }

        $uriRelease = 'https://github.com/microsoft/CSS-SystemCenter-ServiceManager/releases/latest/download/SCSM-Diagnostic-Tool.ps1'
        InvokeWebRequest_WithProxy -uri $uriRelease -timeoutSec 5 -OutFile $scriptFilePath
        return $true  # here a $true is returned because we could download the latest smdt version from GitHub

    } catch { 
        # if we land here, then we had problems contacting GitHub, let's check winTemp as an additional option

        #region get smdt.ps1 from windows Temp folder, if exists and newer
        try {
            $windirTempFolder = [IO.Path]::Combine($env:windir, "Temp", "SCSM.Support.Tools")
            $smdtPs1TargetFileName = "SCSM-Diagnostic-Tool.ps1"
            $smdtPs1TargetFullPath = [IO.Path]::Combine($windirTempFolder, $smdtPs1TargetFileName)
            $smdtVersionInTarget = New-Object Version
            if ( -not (Test-Path -Path $smdtPs1TargetFullPath) ) { return $false}

            $smdtBody = [System.IO.File]::ReadAllText($smdtPs1TargetFullPath, [System.Text.Encoding]::UTF8) 
            $smdtVersionInTarget = GetSmdtVersionFromString -smdtBody $smdtBody

            $currentlyRunningVersion = New-Object version -ArgumentList (GetToolVersion)
            if ($currentlyRunningVersion -lt $smdtVersionInTarget) {
                Copy-Item -Path $smdtPs1TargetFullPath -Destination $scriptFilePath -Force
                return $true  # here a $true is returned because we could get a higher smdt version from winTemp
            }
        } catch { return $false }
        #endregion
        
        return $false 
    }

    return $false
}