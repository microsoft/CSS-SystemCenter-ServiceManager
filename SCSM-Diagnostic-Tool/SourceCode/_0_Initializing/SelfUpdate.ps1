function SelfUpdate() {
    try {
        if (IsRunningAsElevated) { return; }

        $sgn = Get-AuthenticodeSignature $scriptFilePath
        if ($sgn.Status -ne [System.Management.Automation.SignatureStatus]::Valid) { return; }
        if ($sgn.SignerCertificate.Subject -notlike 'CN=Microsoft Corporation, *') { return; }
        
        $uriApi = "https://api.github.com/repos/microsoft/css-systemcenter-servicemanager/releases/latest"
        $newVersionStr = (Invoke-WebRequest -Uri $uriApi -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop | ConvertFrom-Json).tag_name.Replace("v","")
        $newVersion = New-Object version -ArgumentList $newVersionStr

        $currentVersion = New-Object version -ArgumentList (GetToolVersion)
        if ($newVersion -le $currentVersion) { return }

        $uriRelease = 'https://github.com/microsoft/CSS-SystemCenter-ServiceManager/releases/latest/download/SCSM-Diagnostic-Tool.ps1'
        Invoke-WebRequest -Uri $uriRelease -UseBasicParsing -TimeoutSec 5 -OutFile $scriptFilePath -ErrorAction Stop        
    } catch {}    
}