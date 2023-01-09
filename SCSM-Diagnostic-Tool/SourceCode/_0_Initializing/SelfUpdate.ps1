function SelfUpdate() {

    try {
        $sgn = Get-AuthenticodeSignature $scriptFilePath

        if ($sgn.Status -ne [System.Management.Automation.SignatureStatus]::Valid) { return; }
        if ($sgn.SignerCertificate.Subject -notlike 'CN=Microsoft Corporation, *') { return; }

        $tmpContentFile = $scriptFilePath + ".tmp"
        $rsp = $null
        try {
            $source = 'https://github.com/microsoft/CSS-SystemCenter-ServiceManager/releases/latest/download/SCSM-Diagnostic-Tool.ps1'       
            $rsp = Invoke-WebRequest -Uri $source -UseBasicParsing -TimeoutSec 5 -OutFile $tmpContentFile -PassThru -ErrorAction Stop
        }
        catch {
            try { 
                if (Test-Path -Path $tmpContentFile) { Remove-Item -Path $tmpContentFile -Force } 
            } catch {}
            return
        }

        if ($rsp.StatusCode -ne 200) { return }

        $reader = [System.IO.File]::OpenText($tmpContentFile)
        $newVersionStr =  while($null -ne ($line = $reader.ReadLine())) { 
            if ( $line.Trim() -like 'function GetToolVersion()*' ) {
                $line 
                break
            }   
        }
        $reader.Close()
        
        $newVersionStr = $newVersionStr.Trim().Replace("function GetToolVersion() {'","").Replace("'}","").Trim()

        $newVersion = New-Object version -ArgumentList $newVersionStr
        $currentVersion = New-Object version -ArgumentList (GetToolVersion)
        if ($newVersion -le $currentVersion) { return }

        Copy-Item -Path $tmpContentFile -Destination $scriptFilePath -Force | Out-Null

        if (Test-Path -Path $tmpContentFile) { Remove-Item -Path $tmpContentFile -Force } 
    } catch {}
}