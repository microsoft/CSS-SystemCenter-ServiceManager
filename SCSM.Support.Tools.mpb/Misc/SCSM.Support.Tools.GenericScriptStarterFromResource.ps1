#do NOT delete these variable declarations! They will be used in this script. As their values will be set via file content (in args[0]) during Rule definition, their declarations MUST be done here, otherwise their values won't persist after calling { . $args[0] }
#you can set and use the below vars for local debugging. Their values will be overwritten when Rule starts to run
$scriptMPName =      'SCSM.Support.Tools.HealthStatus.Monitoring'
$scriptResource_ID = 'SCSM.Support.Tools.HealthStatus.Monitoring.Starter.ScriptResource'
$scriptFileName =    'SCSM.Support.Tools.HealthStatus.Monitoring.Starter.ps1'
$scriptArguments =   ''
$transcriptFileName ='SCSM.Support.Tools.HealthStatus.Monitoring.GenericScriptStarterFromResource.Transcript.txt'
#------------------------------------------------------------------------------------------------------------------------------------------------------
#the below line will be effective when the Rule runs because it will provide the above variable declarations as args[0]
if ($args.Count -gt 0) { . $args[0] }

function Invoke-AlternativeSqlCmd_WithoutTimeout($SQLInstance, $SQLDatabase, $SQLQuery){
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
function WriteLog($text) {
	Write-Host "$([datetime]::Now.ToString("yyyy\-MM\-dd\_\_HH\:mm\.ss\.fff")): $text"
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

$folder = [IO.Path]::Combine($env:windir, "Temp")
$transcriptFileFullPath = [IO.Path]::Combine($folder, $transcriptFileName) 
Start-Transcript -Path $transcriptFileFullPath -Force | Out-Null
if (-not ((IsThisScsmWfMgmtServer) -or (IsThisScsmDwMgmtServer)) ) { 
    WriteLog "This machine is neither WF nor DW mgmt server. Exiting..."
    ExitScript 
}
$SQLInstance_SCSM = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\System Center\2010\Common\Database' -ErrorAction SilentlyContinue).DatabaseServerName
$SQLDatabase_SCSM = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\System Center\2010\Common\Database' -ErrorAction SilentlyContinue).DatabaseName

#region checking SMST eula
WriteLog "checking SMST eula via sql: $SQLInstance_SCSM db: $SQLDatabase_SCSM"
$SmstEulaAccepted = $false

$SmstEulaSql = 'select EulaApprovedAt_406E933A_3D8E_4A08_999E_20274F211D69 from MT_SCSM#Support#Tools#Main#Data'
if ((IsThisScsmDwMgmtServer)) {
    $SmstEulaSql = 'select [SCSM.Support.Tools.Main.Data!EulaApprovedAt] from inbound.MTV_SCSM#Support#Tools#Main#Data'
}
#note: the below char replacements between # and $ are necessary, otherwise token usage (with surrounding dollar signs) will error in Rule Contents like $Data/...
$SmstEulaSql = $SmstEulaSql.Replace("#","$") 

$ds = Invoke-AlternativeSqlCmd_WithoutTimeout -SQLInstance $SQLInstance_SCSM -SQLDatabase $SQLDatabase_SCSM -SQLQuery $SmstEulaSql
if ($ds.Tables.Count -gt 0) {
	$EulaApprovedAt = $ds.Tables[0].Rows[0].EulaApprovedAt_406E933A_3D8E_4A08_999E_20274F211D69
	if ($EulaApprovedAt -ne [DBNull]::Value) {
        $SmstEulaAccepted = $true
    }
}
if ($SmstEulaAccepted) {
    WriteLog "SMST eula is accepted. Continuing with script..."
}
else {
    WriteLog "SMST eula not accepted yet. Exiting..."
    ExitScript
}

#endregion

#region getting script from resource
WriteLog "getting script from MP: $scriptMPName ResourceID: $scriptResource_ID via sql: $SQLInstance_SCSM db: $SQLDatabase_SCSM"
$scriptBody = GetResourceValueFromSQL -SQLInstance $SQLInstance_SCSM -SQLDatabase $SQLDatabase_SCSM -MPName $scriptMPName -ResourceName $scriptResource_ID
if ($scriptBody) {
	$fileFullPath = [IO.Path]::Combine($folder, $scriptFileName)
	WriteLog "writing script to $fileFullPath and starting it with arguments: $scriptArguments"
	[System.IO.File]::WriteAllText($fileFullPath, $scriptBody)
	Start-Process -FilePath "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -ArgumentList "-noninteractive -noprofile -executionpolicy bypass -File $fileFullPath $scriptArguments"
}
else {
    WriteLog "Could NOT get script resource!"
}
#endregion

ExitScript
