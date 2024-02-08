param(
    [string]$BuildVersion
)

function GetBuildVersion() {

    "$((Get-Date).ToUniversalTime().ToString(`"yyyy.MM.dd.HHmm`"))"

    <# VS style like 1.0.*
    $Jan2000 = [datetime]::new(2000,1,1)
    [int]$buildNo = ([datetime]::Today.Subtract($Jan2000)).Totaldays
    $todayMidnight = [datetime]::Today
    [int]$revisionNo = ([datetime]::Now.Subtract($todayMidnight)).TotalSeconds / 2
    "1.0.$buildNo.$revisionNo"
    #>
}
function SetMPversion($mpFullPath) {
    $doc = [xml]::new()
    $doc.Load($mpFullPath)
    $doc.CreateXmlDeclaration("1.0", "utf-8", $null) | Out-Null
    $currentVersionNode = $doc.DocumentElement.SelectSingleNode("/ManagementPack/Manifest/Identity/Version");
    $currentVersionNode.InnerText = $BuildVersion
    $doc.Save($mpFullPath)   
}
<#
function SetVSProjectversion($vsProjectFullPath) {
    $assemblyInfoFullPath = [IO.Path]::Combine( [IO.Path]::GetDirectoryName($vsProjectFullPath), "Properties\AssemblyInfo.cs")
    $assemblyInfoContent = [IO.File]::ReadAllText($assemblyInfoFullPath, [System.Text.Encoding]::UTF8)    
    $newVersion = $BuildVersion
    $newVersionLine = "[assembly: AssemblyVersion(`"$BuildVersion`")]"
    $assemblyInfoContent = $assemblyInfoContent.Replace('[assembly: AssemblyVersion("1.0.*")]', $newVersionLine)
    [IO.File]::WriteAllText($assemblyInfoFullPath, $assemblyInfoContent, [System.Text.Encoding]::UTF8)   
}
#>
function SetCentralVSProjectversion() {
    $assemblyInfoFullPath = [IO.Path]::Combine( ((Resolve-Path -Path "$folderName_Output").Path), "Central.AssemblyInfo.cs" )
    $assemblyInfoContent = "[assembly: System.Reflection.AssemblyVersion(`"$BuildVersion`")]"
    [IO.File]::WriteAllText($assemblyInfoFullPath, $assemblyInfoContent, [System.Text.Encoding]::UTF8)   
}

$folderName_Bundle =     "Bundle"  
$folderName_MPSource =   "MPSource"  
$folderName_MPResource = "MPResource"  
$folderName_Output   =   "Output"    
$folderName_Misc     =   "Misc"      
if ( (Split-Path -Path (Get-Location) -Leaf) -eq $folderName_Bundle ) {
    cd ".."  # Set folder to root
}
 
if (-not $BuildVersion) {
    $BuildVersion = (GetBuildVersion)
}

$MpXmlsToSeal = @()
$MpXmlBuilds = @() #PreSeal
$MpXmlsNotToSeal = @()
$Resources = @()

#region Main
$MpXmlsToSeal += "Main\SCSM.Support.Tools.Main.Core.xml"
$MpXmlsToSeal += "Main\SCSM.Support.Tools.Main.Presentation.xml"
$MpXmlsToSeal += "Main\SCSM.Support.Tools.Main.Monitoring.xml"

$MpXmlBuilds +=  "Main\SCSM.Support.Tools.Main.Monitoring.xml.Build.ps1"

$Resources += "$folderName_MPResource\i362_ClassID_MOMServerRole_32.png"
$Resources += "$folderName_MPResource\SCSM.Support.Tools.Main.Monitoring.MpbUpdater.ps1"
#endregion
#region HealthStatus
$MpXmlsToSeal += "HealthStatus\SCSM.Support.Tools.HealthStatus.Core.xml"
$MpXmlsToSeal += "HealthStatus\SCSM.Support.Tools.HealthStatus.Monitoring.xml"
$MpXmlsToSeal += "HealthStatus\SCSM.Support.Tools.HealthStatus.Notification.xml"
$MpXmlsToSeal += "HealthStatus\SCSM.Support.Tools.HealthStatus.Presentation.xml"

$MpXmlBuilds +=  "HealthStatus\SCSM.Support.Tools.HealthStatus.Monitoring.xml.Build.ps1"

$MpXmlsNotToSeal += "HealthStatus\SCSM.Support.Tools.HealthStatus.Notification.Subscription.xml"

$Resources += "$folderName_MPResource\SCSM.Support.Tools.HealthStatus.Monitoring.Starter.ps1"
#$Resources += "$folderName_MPResource\SCSM-Diagnostic-Tool.ps1"
$Resources += "..\SCSM-Diagnostic-Tool\LocalDebug\SCSM-Diagnostic-Tool.ps1"
$Resources += "$folderName_MPSource\HealthStatus\SCSM.Support.Tools.HealthStatus.Notification.Subscription.xml"
$Resources += "$folderName_MPResource\SCSM213_Administration_16.png"
#endregion 

#region copy to Output folder

#region copy MP XMLs
foreach($MpXml in ($MpXmlsToSeal + $MpXmlsNotToSeal) ) {
    Copy-Item -Path "$folderName_MPSource\$MpXml" -Destination $folderName_Output
}
#endregion
#region copy Resources to Output folder
foreach($Resource in $Resources) {
    copy $Resource $folderName_Output
}
#endregion 

#endregion

#region Build - PreSeal
foreach($MpXmlBuild in $MpXmlBuilds) {
    & "$folderName_MPSource\$MpXmlBuild"
}
#endregion

#region Set MP Version
foreach($MpXml in ($MpXmlsToSeal + $MpXmlsNotToSeal) ) {
    $mpXmlInOutputFolder = "$folderName_Output\"+(Split-Path -Path $MpXml -Leaf)
    SetMPversion -mpFullPath ((Resolve-Path -Path $mpXmlInOutputFolder).Path)
}
#endregion 

SetCentralVSProjectversion

#region Seal MPxmls
foreach($MpXml in $MpXmlsToSeal) {
    $mpXmlInOutputFolder = "$folderName_Output\"+(Split-Path -Path $MpXml -Leaf)
    ."$folderName_Misc\FastSeal.exe" $mpXmlInOutputFolder /Keyfile "$folderName_Misc\MSPublicKey35.snk" /Company "Microsoft Support" /OutDir "$folderName_Output" /DelaySign 
}
del MPResources.resources
#endregion 


