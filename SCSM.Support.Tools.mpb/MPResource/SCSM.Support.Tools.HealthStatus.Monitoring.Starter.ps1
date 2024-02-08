
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
$transcriptFileFullPath = [IO.Path]::Combine($folder, "SCSM.Support.Tools.HealthStatus.Monitoring.Starter.Transcript.txt") 
Start-Transcript -Path $transcriptFileFullPath -Force | Out-Null

if (-not ((IsThisScsmWfMgmtServer) -or (IsThisScsmDwMgmtServer)) ) { 
    WriteLog "This machine is neither WF nor DW mgmt server."
    ExitScript 
}

if (-not (Get-Module -name System.Center.Service.Manager)) {
    Import-Module ((Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\System Center\2010\Service Manager\Setup').InstallDirectory +'PowerShell\' +'System.Center.Service.Manager.psd1') -Force 
}

#region SMDT Updater and Starter
WriteLog "Starting SMDT Updater and Starter part"
$localVersion = New-Object Version
$fileFullPath = [IO.Path]::Combine($folder, "SCSM-Diagnostic-Tool.ps1")

if ( (Test-Path -Path $fileFullPath) ) {
    $smdtBody = [System.IO.File]::ReadAllText($fileFullPath, [System.Text.Encoding]::UTF8) 
    $smdtVersionInString = GetSmdtVersionFromString -smdtBody $smdtBody    
    WriteLog "initially found local version $($smdtVersionInString.ToString())"
    if ($smdtVersionInString -gt $localVersion) {
       $localVersion = $smdtVersionInString
    }   
}

$SQLInstance_SCSM = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\System Center\2010\Common\Database' -ErrorAction SilentlyContinue).DatabaseServerName
$SQLDatabase_SCSM = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\System Center\2010\Common\Database' -ErrorAction SilentlyContinue).DatabaseName
$SMDT_ScriptResource_MPName = 'SCSM.Support.Tools.HealthStatus.Monitoring'
$SMDT_ScriptResource_ID =     'SCSM.Support.Tools.HealthStatus.Monitoring.SMDT.ScriptResource'

if ((IsThisScsmDwMgmtServer)) {
    WriteLog "This machine is DW mgmt server."
    $smdtBody = GetResourceValueFromSQL -SQLInstance $SQLInstance_SCSM -SQLDatabase $SQLDatabase_SCSM -MPName $SMDT_ScriptResource_MPName -ResourceName $SMDT_ScriptResource_ID
    if ($smdtBody) {
        $smdtVersionInString = GetSmdtVersionFromString -smdtBody $smdtBody
        WriteLog "Got $($smdtVersionInString.ToString()) from DW/SQL Resource table"
        if ($smdtVersionInString -gt $localVersion) {
            [System.IO.File]::WriteAllText($fileFullPath, $smdtBody)
            $localVersion = $smdtVersionInString
            WriteLog "Wrote from DW/SQL Resource table to localFile"
        } 
    }

    $SQL_SMDBInfo=@'
    select DataSourceName_AC09B683_AE61_BDCA_6383_2007DB60859D as DataSourceName_SMDB,DatabaseServer_CD2D9C2A_39C2_CE05_D84C_AC42E429D191 as SQLInstance_SMDB,Database_D59DC40A_E438_1A05_C231_E3BD50E5DD44 as SQLDatabase_SMDB,SdkServer_0E227991_743F_4854_FF8B_273C1688DFEB  as SDKServer_SMDB from MTV_Microsoft$SystemCenter$DataWarehouse$CMDBSource where BaseManagedEntityId in (select BaseManagedEntityId from BaseManagedEntity where BaseManagedTypeId='0222340F-D0CD-6B06-70A6-AA0A1504F428' and name not like 'DW\_%' escape'\')
'@

    $SMDBInfo = (Invoke-AlternativeSqlCmd_WithoutTimeout -SQLInstance $SQLInstance_SCSM -SQLDatabase $SQLDatabase_SCSM -SQLQuery $SQL_SMDBInfo).Tables[0]
	if ($SMDBInfo) {
		$SQLInstance_SCSM = $SMDBInfo.SQLInstance_SMDB
		$SQLDatabase_SCSM = $SMDBInfo.SQLDatabase_SMDB
	}
}

$smdtBody = GetResourceValueFromSQL -SQLInstance $SQLInstance_SCSM -SQLDatabase $SQLDatabase_SCSM -MPName $SMDT_ScriptResource_MPName -ResourceName $SMDT_ScriptResource_ID
if ($smdtBody) {
    $smdtVersionInString = GetSmdtVersionFromString -smdtBody $smdtBody
    WriteLog "Got $($smdtVersionInString.ToString()) from WF/SQL Resource table"
    if ($smdtVersionInString -gt $localVersion) {
        [System.IO.File]::WriteAllText($fileFullPath, $smdtBody)
        $localVersion = $smdtVersionInString
        WriteLog "Wrote from WF/SQL Resource table to localFile"
    } 
}

if (-not (Test-Path -Path $fileFullPath) ) {
    WriteLog "Can't start because SMDT.ps1 not found at $fileFullPath"
    #todo: try getting resource from SDK services (WF and DW)
    ExitScript
}

$SMDTzipFilesToKeep = Get-ChildItem -Force -Filter "SCSM_DIAG_*.zip" -File -Path $folder -ErrorAction SilentlyContinue | Sort CreationTime -Descending | Select-Object -First 6 -Property FullName
$AllSMDTzipFiles    = Get-ChildItem -Force -Filter "SCSM_DIAG_*.zip" -File -Path $folder -ErrorAction SilentlyContinue | Select-Object -Property FullName
foreach ($smdtZipFile in $AllSMDTzipFiles) {
	if ( $SMDTzipFilesToKeep.FullName -contains $smdtZipFile.FullName ) {
		#  WriteLog "keep recent file: $smdtZipFile.FullName"
	}
	else {
		WriteLog "deleting old $smdtZipFile.FullName"
		Remove-Item -Path $smdtZipFile.FullName -ErrorAction SilentlyContinue
	}
}	

WriteLog "starting $fileFullPath -acceptEula -noSelfUpdate -startedByRule"
Start-Process -FilePath "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -ArgumentList "-noninteractive -noprofile -executionpolicy bypass -File $fileFullPath -acceptEula -noSelfUpdate -startedByRule"
#endregion								

ExitScript
