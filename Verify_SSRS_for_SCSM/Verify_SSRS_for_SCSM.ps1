#region function definitions

function SelfElevate() {
    #got from http://www.expta.com/2017/03/how-to-self-elevate-powershell-script.html   and changed a bit
    if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
     if ([int](Get-WmiObject -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
      $CommandLine = "-File `"" + $Script:MyInvocation.MyCommand.Path + "`" " + $Script:MyInvocation.UnboundArguments
      Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
      Exit
     }
    }
}
function EndScriptExecution() {
    Write-Host ""
    Read-Host "Press ENTER to stop execution" 
    Exit
}
#endregion
#region Init
SelfElevate
#endregion 

#region Select SSRS service
$ssrsServicesAvailable = gwmi win32_service | ?{ $_.DisplayName -like 'SQL Server Reporting Services*' }
if ($ssrsServicesAvailable -eq $null) {
    Write-Host "No SSRS service(s) detected on this machine. " -NoNewline
    Write-Host "Aborting ..." -ForegroundColor Yellow
    EndScriptExecution
}

if ( ($ssrsServicesAvailable | Measure-Object).Count -eq 1) {
    $ssrsServiceToVerify = ($ssrsServicesAvailable | Select-Object -Property DisplayName, State, PathName) | Select-Object -First 1
}
else {
    $ssrsServiceToVerify = $ssrsServicesAvailable | Select-Object -Property DisplayName, State, PathName | Out-GridView  -Title 'Select the SSRS service to verify and then click OK...' -OutputMode Single
    if ($ssrsServiceToVerify -eq $null) {
        Write-Host "No SSRS service selected to verify. " -NoNewline
        Write-Host "Aborting ..." -ForegroundColor Yellow
        EndScriptExecution
    }
}
#endregion

#region Preparation
Write-Host "--------------------------------------------------------------------"
Write-Host "Verifiying selected SSRS service : " -NoNewline
Write-Host "'$($ssrsServiceToVerify.DisplayName)'"  -ForegroundColor Cyan
Write-Host "--------------------------------------------------------------------"
Write-Host ""

$ssrsExePath = $ssrsServiceToVerify.PathName.Replace('"','')
$ssrsExeFileVersion = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($ssrsExePath)
$ssrsMajorVersion = $ssrsExeFileVersion.ProductMajorPart
$ssrsVersionDisplayName = switch ($ssrsMajorVersion)
{
    11 {"2012"}
    12 {"2014"}
    13 {"2016"}
    14 {"2017"}
    15 {"2019"}
    default {""}
}
if ($ssrsVersionDisplayName -eq "") {
    Write-Host "Unknown SSRS Version detected. " -NoNewline
    Write-Host "Aborting ..." -ForegroundColor Yellow
    EndScriptExecution
}

[System.IO.DirectoryInfo]$ssrsReportServerFolder = (Get-Item -Path $ssrsExePath).Directory.Parent
if ($ssrsMajorVersion -ge 14) {
    $ssrsReportServerFolder =    Join-Path $ssrsReportServerFolder.FullName "ReportServer"
}
[string]$ssrsReportServerFolder = $ssrsReportServerFolder.FullName 
[string]$ssrsReportServerBinFolder = Join-Path $ssrsReportServerFolder "bin"
#endregion

#region Checking DLL
$scsmDllFileExists = $false
$scsmDllFileName = "Microsoft.EnterpriseManagement.Reporting.Code.dll"
$scsmDllFilePath = Join-Path $ssrsReportServerBinFolder $scsmDllFileName
$scsmDllFileExists = (Test-Path -Path $scsmDllFilePath)
if (-not $scsmDllFileExists) {
    Write-Host "ERROR: "  -ForegroundColor Yellow -NoNewline
    Write-Host "The file '$scsmDllFileName' does *NOT* exist in '$ssrsReportServerBinFolder'"
}
else {
    Write-Host " Pass: The file '$scsmDllFileName' does exist in '$ssrsReportServerBinFolder'" 
}
Write-Host ""
#endregion

#region Checking rssrvpolicy.config
$rssrvpolicy_configIsCorrect = $false
$rssrvpolicy_configFileName = "rssrvpolicy.config"
$rssrvpolicy_configFilePath = Join-Path $ssrsReportServerFolder $rssrvpolicy_configFileName
$rssrvpolicy_configFileExists = (Test-Path -Path $rssrvpolicy_configFilePath)
if (-not $rssrvpolicy_configFileExists) {
    Write-Host "$rssrvpolicy_configFileName does *NOT* exist in $ssrsReportServerFolder" -ForegroundColor Yellow
}
if ($rssrvpolicy_configFileExists) {    
    
    [xml]$xml = Get-Content $rssrvpolicy_configFilePath
    
    $tagNameToFind = "CodeGroup"
    $attributeNameToFind = "Name"
    $attributeValueToFind = "Microsoft System Center Service Manager Reporting Code Assembly"
    $nodeToFind = Select-Xml -XPath "//$tagNameToFind[@$attributeNameToFind='$attributeValueToFind']" -Xml $xml

    if ($nodeToFind -eq $null) {
        Write-Host "ERROR: "  -ForegroundColor Yellow -NoNewline
        Write-Host "The file '$rssrvpolicy_configFileName' in '$ssrsReportServerFolder' does *NOT* contain the correct <$tagNameToFind> node." 
    }
    else {

        $CodeGroup_NodeToVerify = [System.Xml.XmlNode]$nodeToFind.Node
        $IMembershipCondition_NodeToVerify = [System.Xml.XmlNode]$CodeGroup_NodeToVerify.IMembershipCondition

        $rssrvpolicy_configIsCorrect =  ( $CodeGroup_NodeToVerify.class -eq "UnionCodeGroup" `
            -and $CodeGroup_NodeToVerify.version -eq "1" `
            -and $CodeGroup_NodeToVerify.PermissionSetName -eq "FullTrust" `
            -and $IMembershipCondition_NodeToVerify.class -eq "StrongNameMembershipCondition" `
            -and $IMembershipCondition_NodeToVerify.version -eq "1" `
            -and $IMembershipCondition_NodeToVerify.PublicKeyBlob -eq "0024000004800000940000000602000000240000525341310004000001000100B5FC90E7027F67871E773A8FDE8938C81DD402BA65B9201D60593E96C492651E889CC13F1415EBB53FAC1131AE0BD333C5EE6021672D9718EA31A8AEBD0DA0072F25D87DBA6FC90FFD598ED4DA35E44C398C454307E8E33B8426143DAEC9F596836F97C8F74750E5975C64E2189F45DEF46B2A2B1247ADC3652BF5C308055DA9"
        ) 

        if (-not $rssrvpolicy_configIsCorrect) {
            Write-Host "ERROR: "  -ForegroundColor Yellow -NoNewline
            Write-Host "The <$tagNameToFind> node in '$rssrvpolicy_configFileName' in '$ssrsReportServerFolder' does exists but its content is *NOT* correct."
        }
        else {
            Write-Host " Pass: The content of '$rssrvpolicy_configFileName'    in '$ssrsReportServerFolder' is correct."             
        }
    }

}
Write-Host ""
#endregion

#region Checking rsreportserver.config
$rsreportserver_configIsCorrect = $false
$rsreportserver_configFileName = "rsreportserver.config"
$rsreportserver_configFilePath = Join-Path $ssrsReportServerFolder $rsreportserver_configFileName
$rsreportserver_configFileExists = (Test-Path -Path $rsreportserver_configFilePath)
if (-not $rsreportserver_configFileExists) {
    Write-Host "$rsreportserver_configFileName does *NOT* exist in $ssrsReportServerFolder" -ForegroundColor Yellow
}
if ($rsreportserver_configFileExists) {
     
    [xml]$xml = Get-Content $rsreportserver_configFilePath
    
    $tagNameToFind = "Extension"
    $attributeNameToFind = "Name"
    $attributeValueToFind = "SCDWMultiMartDataProcessor"
    $nodeToFind = Select-Xml -XPath "//$tagNameToFind[@$attributeNameToFind='$attributeValueToFind']" -Xml $xml

    if ($nodeToFind -eq $null) {
        Write-Host "ERROR: "  -ForegroundColor Yellow -NoNewline
        Write-Host "The file '$rsreportserver_configFileName' in '$ssrsReportServerFolder' does *NOT* contain the correct <$tagNameToFind> node."
    }
    else {

        $Extension_NodeToVerify = [System.Xml.XmlNode]$nodeToFind.Node
        $rsreportserver_configIsCorrect =  ( $Extension_NodeToVerify.Type.Replace(" ","") -eq "Microsoft.EnterpriseManagement.Reporting.MultiMartConnection, Microsoft.EnterpriseManagement.Reporting.Code".Replace(" ","") ) 

        if (-not $rsreportserver_configIsCorrect) {
            Write-Host "ERROR: "  -ForegroundColor Yellow -NoNewline
            Write-Host "The <$tagNameToFind> node in '$rsreportserver_configFileName' in '$ssrsReportServerFolder' does exists but its content is *NOT* correct." 
        }
        else {
            Write-Host " Pass: The content of '$rsreportserver_configFileName' in '$ssrsReportServerFolder' is correct."             
        }
    }

}
Write-Host ""
#endregion

#region Conclusion
""
Write-Host "Conclusion:" -ForegroundColor Cyan
Write-Host "==========="
if ($scsmDllFileExists -and $rsreportserver_configIsCorrect -and $rssrvpolicy_configIsCorrect) {
    Write-Host "The selected SSRS instance is configured correctly."
}
else {
    Write-Host "The selected SSRS instance is " -NoNewline
    Write-Host "*NOT* configured correctly." -ForegroundColor Yellow
    Write-Host "Please follow the steps at  " -NoNewline
    Write-Host "https://docs.microsoft.com/en-us/system-center/scsm/config-remote-ssrs" -ForegroundColor Yellow
}
EndScriptExecution
#endregion
