
function Invoke-AlternativeSqlCmd_WithoutTimeout($SQLInstance, $SQLDatabase, $SQLQuery) {
    $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
    $SqlConnection.ConnectionString = "Server=$SQLInstance; Database=$SQLDatabase; Trusted_Connection=True"
    $SqlConnection.Open() 

    $SqlAdp = New-Object System.Data.SqlClient.SqlDataAdapter
    $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
    $SqlCmd.CommandText = $SQLQuery
    $SqlCmd.Connection = $SqlConnection
    $SqlCmd.CommandTimeout = 0 # do NOT change this!
    $SqlAdp.SelectCommand = $SqlCmd
    $DS = New-Object System.Data.DataSet
    $SqlAdp.Fill($DS) | out-null  # keep the out-null otherwise $DS will return as Object[]
    return $DS;
}
function IsThisScsmDwMgmtServer() {
    $regSetupExists = Test-Path -Path 'HKLM:\SOFTWARE\Microsoft\System Center\2010\Service Manager\Setup' -ErrorAction SilentlyContinue
    $regMGExists = Test-Path -Path 'HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Server Management Groups' -ErrorAction SilentlyContinue
    $regSDKType = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\System Center\2010\Common\SDK Service' -ErrorAction SilentlyContinue)."SDK Service Type"

    return ($regSetupExists -and $regMGExists -and ($regSDKType -eq 2))
}
function IsThisScsmWfMgmtServer() {
    $qry = @'
    select bme.Name, bme.DisplayName
    FROM dbo.[ScopedInstanceTargetClass] sitc
        inner join ManagedType mt on mt.ManagedTypeId = sitc.ManagedTypeId
        inner join BaseManagedEntity bme on bme.BaseManagedEntityId = sitc.ScopedInstanceId and bme.IsDeleted=0
    where mt.ManagedTypeId = dbo.fn_ManagedTypeId_MicrosoftSystemCenterWorkflowTarget()
'@
    $SQLInstance_SCSM = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\System Center\2010\Common\Database').DatabaseServerName
    $SQLDatabase_SCSM = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\System Center\2010\Common\Database').DatabaseName
    $ds = Invoke-AlternativeSqlCmd_WithoutTimeout -SQLInstance $SQLInstance_SCSM -SQLDatabase $SQLDatabase_SCSM -SQLQuery $qry
    if ($ds.Tables.Count -eq 0) {
        return $false
    }
    $WfDisplayName = $ds.Tables[0].DisplayName
    return ( ($env:COMPUTERNAME -eq $WfDisplayName) -or ([System.Net.Dns]::GetHostEntry([string]$env:computername).HostName -eq $WfDisplayName) )
}
function GetSmdtVersionFromString([string]$smdtBody) {
   $versionResult = New-Object Version
   $sr = [System.IO.StringReader]::new($smdtBody)
    while (-not $sr.EndOfStream){
        $line = $sr.ReadLine().Trim()
        if ( $line.StartsWith("function GetToolVersion()") ) {
            $versionString = $line.Replace("function GetToolVersion()","").Replace("{'","").Replace("'}","").Trim()
            return New-Object Version -ArgumentList $versionString
        }
    }
    return $versionResult
}
function GetResourceValueFromSQL($SQLInstance, $SQLDatabase, $MPName ,$ResourceName) {
    $resourceValue = $null
    $ds = Invoke-AlternativeSqlCmd_WithoutTimeout -SQLInstance $SQLInstance -SQLDatabase $SQLDatabase -SQLQuery "select ResourceValue from Resource r inner join ManagementPack mp on r.ManagementPackId = mp.ManagementPackId where ResourceName='$ResourceName' and mp.MPName = '$MPName'"
    if ($ds.Tables.Count -gt 0) {
        $bytes = $ds.Tables[0].Rows[0].ResourceValue
	    $resourceValue = [System.Text.Encoding]::UTF8.GetString($bytes)
    }
	return $resourceValue
}
function ExitScript() {
    Stop-Transcript| Out-Null
    Exit
}
function WriteLog($text) {
    Write-Host "$([datetime]::Now.ToString("yyyy\-MM\-dd\_\_HH\:mm\.ss\.fff")): $text"
}
function GetProxy($uri) { #https://learn.microsoft.com/en-us/dotnet/api/system.net.iwebproxy.getproxy?view=netframework-4.8.1#examples
    $wpi = [System.Net.WebRequest]::GetSystemWebProxy()
    $wpi.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
    
    $webProxyServer = $null

    if ( !$wpi.IsBypassed($uri) ) {
        $webProxyServer = $wpi.GetProxy($uri);

        if ( (!$webProxyServer -or $webProxyServer -ne $null ) -and $webProxyServer -eq $uri) {
            $webProxyServer = $null
        }       
    }
    [bool]$proxyUseDefaultCredentials = ($webProxyServer -ne $null)

    @($webProxyServer,$proxyUseDefaultCredentials)
}
function InvokeWebRequest_WithProxy($uri, $timeoutSec=0, [switch]$useBasicParsing=$true, [switch]$useDefaultCredentials=$true, [string]$outFile=$null) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 
    $webProxyServer,$proxyUseDefaultCredentials = GetProxy($uri)    
    Invoke-WebRequest -Uri $uri -UseBasicParsing:$useBasicParsing -TimeoutSec $timeoutSec -UseDefaultCredentials:$useDefaultCredentials -Proxy $webProxyServer -ProxyUseDefaultCredentials:$proxyUseDefaultCredentials -OutFile $outFile
}

$folder = [IO.Path]::Combine($env:windir, "Temp")
$transcriptFileFullPath = [IO.Path]::Combine($folder, "SCSM.Support.Tools.Main.Monitoring.MpbUpdater.Transcript.txt") 
Start-Transcript -Path $transcriptFileFullPath -Force | Out-Null

if (-not ((IsThisScsmWfMgmtServer) -or (IsThisScsmDwMgmtServer)) ) { 
    WriteLog "This machine is neither WF nor DW mgmt server."
    ExitScript 
}

if (-not (Get-Module -name System.Center.Service.Manager)) {
    Import-Module ((Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\System Center\2010\Service Manager\Setup').InstallDirectory +'PowerShell\' +'System.Center.Service.Manager.psd1') -Force 
}

$localVersion_MPB = New-Object Version
$fileFullPath_MPB = [IO.Path]::Combine($folder, "SCSM.Support.Tools.mpb")

if ( (Test-Path -Path $fileFullPath_MPB) ) { 
    # $smstVersion = (Get-SCSMManagementPack -BundleFile $fileFullPath_MPB | ? { $_.Name -eq 'SCSM.Support.Tools.Main.Core'} | Select-Object -Property Version).Version

    $jobParams = @($fileFullPath_MPB)
    Start-Job -ScriptBlock {
        #region Getting input params
            #because of:  https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_automatic_variables?view=powershell-5.1#input
            #and https://docs.microsoft.com/en-us/dotnet/api/system.collections.ienumerator?view=netframework-4.8#remarks
            if ($input.MoveNext()) { $inputs = $input.Current } else { return }  
            #endregion

        $fileFullPath_MPB = $inputs 
        if (-not (Get-Module -name System.Center.Service.Manager)) {
            Import-Module ((Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\System Center\2010\Service Manager\Setup').InstallDirectory +'PowerShell\' +'System.Center.Service.Manager.psd1') -Force 
        }
        (Get-SCSMManagementPack -BundleFile $fileFullPath_MPB | ? { $_.Name -eq 'SCSM.Support.Tools.Main.Core'} | Select-Object -Property Version).Version           

    } -InputObject $jobParams -Name GetMpbVersion | Out-Null

    Wait-Job -Name GetMpbVersion -Timeout 60 | Out-Null
    $smstVersion = Receive-Job -Name GetMpbVersion 

    WriteLog "initially found local MPB version $($smstVersion.ToString())"
    if ($smstVersion -gt $localVersion_MPB) {
       $localVersion_MPB = $smstVersion
       WriteLog "set `$localVersion_MPB to $($smstVersion.ToString())"
    }   
}

$WFsdkName = "localhost"
WriteLog "set `$WFsdkName initially to localhost"
if ((IsThisScsmDwMgmtServer)) {
    WriteLog "This is DW. Importing DW cmdlets"
    if (-not (Get-Module -name Microsoft.EnterpriseManagement.Warehouse.Cmdlets)) {
        Import-Module ((Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\System Center\2010\Service Manager\Setup').InstallDirectory  +'Microsoft.EnterpriseManagement.Warehouse.Cmdlets.psd1') -Force
    }
    WriteLog "Starting Get-SCDWInfraLocation to get the WF SDK name" 
    $WFsdkName = (Get-SCDWInfraLocation | ? { $_.InfraType -eq 'ManagementGroup' -and $_.Value -notlike 'DW_*' } | Select-Object -Property Server).Server
    WriteLog "Value of `$WFsdkName is now $WFsdkName"
}
WriteLog "getting smst version from WF"
$smstVersionInWF = (Get-SCSMManagementPack -ComputerName $WFsdkName | ? { $_.Name -eq 'SCSM.Support.Tools.Main.Core'} | Select-Object -Property Version).Version
WriteLog "Found smst version from WF: $($smstVersionInWF.ToString())"
if ($smstVersionInWF -gt $localVersion_MPB) {
    $localVersion_MPB = $smstVersionInWF
    WriteLog "set `$localVersion_MPB to $($smstVersionInWF.ToString())"
}
WriteLog "checking smst version at GitHub"
$gitHubUriApi = "https://api.github.com/repos/microsoft/css-systemcenter-servicemanager/releases/latest"
$gitHubRelease = ( (InvokeWebRequest_WithProxy -uri $gitHubUriApi -timeoutSec 10) | ConvertFrom-Json )
$gitHubVersionStr = $gitHubRelease.tag_name.Replace("v","")
$gitHubVersion = New-Object version -ArgumentList $gitHubVersionStr
WriteLog "Latest release at GitHub is $gitHubVersionStr"
if ( $gitHubRelease.assets | ? { $_.Name -eq 'SCSM.Support.Tools.mpb' } ) {
    WriteLog "SMST.MPB found in latest GitHub release"
    if ($gitHubVersion -gt $localVersion_MPB) {
        WriteLog "SMST.MPB at GitHub is newer than local mpb version, downloading ..."
        $uriRelease = 'https://github.com/microsoft/CSS-SystemCenter-ServiceManager/releases/latest/download/SCSM.Support.Tools.mpb'
        InvokeWebRequest_WithProxy -uri $uriRelease -timeoutSec 10 -OutFile $fileFullPath_MPB
        $localVersion_MPB = $gitHubVersion
        WriteLog "downloaded from github and set `$localVersion_MPB to $gitHubVersionStr"
    }
}
WriteLog "checking if importing local mpb is necessary"
if ($localVersion_MPB -gt $smstVersionInWF) {
    Import-SCSMManagementPack -Fullname $fileFullPath_MPB -ComputerName $WFsdkName
    WriteLog "MPB with version $($localVersion_MPB.ToString()) has been imported."
}
else {
    WriteLog "no newer MPB found, importing not done."
}

ExitScript
