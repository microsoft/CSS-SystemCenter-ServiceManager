param(
    [string]$Configuration = "Debug" # or Release
)

$folderName_Bundle =     "Bundle"  
$folderName_MPSource =   "MPSource"  
$folderName_MPResource = "MPResource"  
$folderName_Output   =   "Output"    
$folderName_Misc     =   "Misc"      
if ( (Split-Path -Path (Get-Location) -Leaf) -eq $folderName_Bundle ) {
    cd ".."  # Set folder to root
}

$VSProjects = @()
$VSProjects += "SCSM.Support.Tools.Library\SCSM.Support.Tools.Library.csproj"
$VSProjects += "SCSM.Support.Tools.Main.Presentation\SCSM.Support.Tools.Main.Presentation.csproj"
$VSProjects += "SCSM.Support.Tools.HealthStatus.Presentation\SCSM.Support.Tools.HealthStatus.Presentation.csproj"

foreach($VSProject in $VSProjects) {
    ."C:\Windows\Microsoft.NET\Framework64\v4.0.30319\MSBuild.exe" "$folderName_MPResource\$VSProject" -t:rebuild /p:Configuration=$Configuration    
}
 
# read-host " "