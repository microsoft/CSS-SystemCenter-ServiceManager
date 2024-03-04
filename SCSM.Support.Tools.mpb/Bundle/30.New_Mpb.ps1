$folderName_Bundle =     "Bundle"  
$folderName_MPSource =   "MPSource"  
$folderName_MPResource = "MPResource"  
$folderName_Output   =   "Output"    
$folderName_Misc     =   "Misc"      
$folderName_ScsmDLLs =   "ScsmDLLs"     
if ( (Split-Path -Path (Get-Location) -Leaf) -eq $folderName_Bundle ) {
    cd ".."  # Set folder to root
}

#if (-not (Get-Module -name System.Center.Service.Manager)) { Import-Module ((Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\System Center\2010\Service Manager\Setup').InstallDirectory +'PowerShell\' +'System.Center.Service.Manager.psd1') -Force }

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
# New-SCSMManagementPackBundle -Name SCSM.Support.Tools.mpb -ManagementPack $MPs -Force -Resource $Resources  #not using sm cmdlets in order to run in ADO

$VerbosePreference = "continue" 
$SMDLL    = "Microsoft.EnterpriseManagement.Core" 
$SMPKG    = "Microsoft.EnterpriseManagement.Packaging" 

$copyFromFolder = [System.IO.Path]::Combine("..",$folderName_Misc,$folderName_ScsmDLLs)
Copy-Item -Path ([System.IO.Path]::Combine($copyFromFolder,"$SMDLL.dll")) -Destination "."
Copy-Item -Path ([System.IO.Path]::Combine($copyFromFolder,"$SMPKG.dll")) -Destination "."

$MPTYPE   = "Microsoft.EnterpriseManagement.Configuration.ManagementPack" 
$MRESTYPE = "Microsoft.EnterpriseManagement.Configuration.ManagementPackResource" 
$SIGTYPE  = "Microsoft.EnterpriseManagement.Packaging.ManagementPackBundleStreamSignature" 
$FACTYPE  = "Microsoft.EnterpriseManagement.Packaging.ManagementPackBundleFactory" 
$EMGTYPE  = "Microsoft.EnterpriseManagement.EnterpriseManagementGroup" 
$OPEN     = [System.IO.FileMode]"Open" 
$READ     = [System.IO.FileAccess]"Read" 

$SMCORE      = [reflection.assembly]::LoadFile([System.IO.Path]::Combine($pwd,"$SMDLL.dll"))
$SMPACKAGING = [reflection.assembly]::LoadFile([System.IO.Path]::Combine($pwd,"$SMPKG.dll"))

$EMPTY       = $SMCORE.GetType($SIGTYPE)::Empty 
$TYPEOFMP    = $SMCORE.GetType($MPTYPE) 
$TYPEOFMPR   = $SMCORE.GetType($MRESTYPE) 
$BFACTORY    = $SMPACKAGING.GetType($FACTYPE) 

# https://www.leeholmes.com/invoking-generic-methods-on-non-generic-classes-in-powershell/
function Invoke-GenericMethod 
{ 
    param ( 
        [type]$mytype,  
        [string]$mymethod,  
        $TypeArguments,  
        $object,  
        [object[]]$parameters = $null  
        ) 
    $Method = $mytype.GetMethod($mymethod) 
    $genericMethod = $Method.MakeGenericMethod($TypeArguments) 
    $genericMethod.Invoke($object,$parameters) 
} 

# https://techcommunity.microsoft.com/t5/system-center-blog/introducing-management-pack-bundles/ba-p/340857
function Get-Resources 
{ 
    param ( $mpObject ) 
    invoke-GenericMethod $TYPEOFMP "GetResources" $TYPEOFMPR $mpObject | %{  
        # check to see if we could find the file 
        $fullname = (resolve-path $_.FileName -ea SilentlyContinue).path 
        if ( ! $fullname )  
        {  
            write-host -for red "
 
    WARNING: 
    ('Cannot find resource: ' + $_.FileName) 
    Skipping this resource, your MPB will probably not import 
    Make sure that the resources are in the same directory as the MP" 
        } 
        else 
        { 
            $stream = new-object io.filestream $fullname,$OPEN,$READ 
            @{ Stream = $stream; Name = $_.Name } 
        } 
    } 
} 

$BUNDLE = $BFACTORY::CreateBundle() 
foreach($MP in $MPs) {

    $theMP = new-object $MPTYPE (resolve-path $MP)    
    Write-Verbose ("Adding MP: " + $theMP.Name) 
    $BUNDLE.AddManagementPack($theMP)

    foreach($Resource in (Get-Resources $theMP ) ) {
        Write-Verbose (" Adding Resource: " + $Resource.Name) 
        $BUNDLE.AddResourceStream($theMP,$Resource.Name,$Resource.Stream,$EMPTY)
    }
}
$bundleWriter = $BFACTORY::CreateBundleWriter(${PWD}) 
$bundleWriter.Write($BUNDLE,"SCSM.Support.Tools") 
