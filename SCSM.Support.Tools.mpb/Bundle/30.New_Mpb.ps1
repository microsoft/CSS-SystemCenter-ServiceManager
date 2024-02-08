$folderName_Bundle =     "Bundle"  
$folderName_MPSource =   "MPSource"  
$folderName_MPResource = "MPResource"  
$folderName_Output   =   "Output"    
$folderName_Misc     =   "Misc"      
if ( (Split-Path -Path (Get-Location) -Leaf) -eq $folderName_Bundle ) {
    cd ".."  # Set folder to root
}

if (-not (Get-Module -name System.Center.Service.Manager)) { Import-Module ((Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\System Center\2010\Service Manager\Setup').InstallDirectory +'PowerShell\' +'System.Center.Service.Manager.psd1') -Force }

#MPB generation needs to run in the Output folder, therefore all MPs and MPResources needs to be present in current = output folder
Set-Location "$folderName_Output"

[string[]]$MPs = @()
[string[]]$Resources = @()

#region Misc
$Resources += "SCSM.Support.Tools.Library.dll"
#endregion 
#region Main
$MPs += "SCSM.Support.Tools.Main.Core.mp"
$MPs += "SCSM.Support.Tools.Main.Presentation.mp"
$MPs += "SCSM.Support.Tools.Main.Monitoring.mp"

$Resources += "SCSM.Support.Tools.Main.Presentation.dll"
$Resources += "i362_ClassID_MOMServerRole_32.png"
$Resources += "SCSM.Support.Tools.Main.Monitoring.MpbUpdater.ps1"
#endregion
#region HealthStatus
$MPs += "SCSM.Support.Tools.HealthStatus.Core.mp"
$MPs += "SCSM.Support.Tools.HealthStatus.Monitoring.mp"
$MPs += "SCSM.Support.Tools.HealthStatus.Notification.mp"
$MPs += "SCSM.Support.Tools.HealthStatus.Presentation.mp"

$Resources += "SCSM.Support.Tools.HealthStatus.Presentation.dll"
$Resources += "SCSM.Support.Tools.HealthStatus.Monitoring.Starter.ps1"
$Resources += "SCSM-Diagnostic-Tool.ps1"
$Resources += "SCSM.Support.Tools.HealthStatus.Notification.Subscription.xml"
$Resources += "SCSM213_Administration_16.png"
#endregion

#--------------------------------------------------------------------
Write-Host "Generating MPB..."
New-SCSMManagementPackBundle -Name SCSM.Support.Tools.mpb -ManagementPack $MPs -Force  -Resource $Resources
