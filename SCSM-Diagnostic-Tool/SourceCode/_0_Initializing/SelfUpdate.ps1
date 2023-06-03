function SelfUpdate() {
    try {        
        if ( $Script:MyInvocation.UnboundArguments.Contains("-noSelfUpdate") ) { return $false }

        $sgn = Get-AuthenticodeSignature $scriptFilePath
        if ($sgn.Status -ne [System.Management.Automation.SignatureStatus]::Valid) { return $false }
        if ($sgn.SignerCertificate.Subject -notlike 'CN=Microsoft Corporation, *') { return $false }
        
        $uriApi = "https://api.github.com/repos/microsoft/css-systemcenter-servicemanager/releases/latest"
        $newVersionStr = ( (InvokeWebRequest_WithProxy -uri $uriApi -timeoutSec 3) | ConvertFrom-Json).tag_name.Replace("v","")
        $newVersion = New-Object version -ArgumentList $newVersionStr

        $currentVersion = New-Object version -ArgumentList (GetToolVersion)
        if ($newVersion -le $currentVersion) { return $false }

        $uriRelease = 'https://github.com/microsoft/CSS-SystemCenter-ServiceManager/releases/latest/download/SCSM-Diagnostic-Tool.ps1'
        InvokeWebRequest_WithProxy -uri $uriRelease -timeoutSec 5 -OutFile $scriptFilePath
        return $true  # only here a $true is returned

    } catch { return $false }

    return $false
}