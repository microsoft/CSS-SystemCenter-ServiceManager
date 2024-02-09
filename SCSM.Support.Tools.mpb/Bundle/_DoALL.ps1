$folderName_Bundle =     "Bundle"  
$folderName_MPSource =   "MPSource"  
$folderName_MPResource = "MPResource"  
$folderName_Output   =   "Output"    
$folderName_Misc     =   "Misc"      
if ( (Split-Path -Path (Get-Location) -Leaf) -eq $folderName_Bundle ) {
    cd ".."  # Set folder to root
}

$transcriptFileName = "$folderName_Output\Bundle_Transcript.txt"
Start-Transcript -Path $transcriptFileName | Out-Null
$rootFolder = Get-Location

Get-Process -Name Microsoft.EnterpriseManagement.ServiceManager.UI.Console -ErrorAction SilentlyContinue | Stop-Process -ErrorAction SilentlyContinue

#Set-Location $rootFolder; & "$folderName_Bundle\05.Copy_SMDT.zip.ps1"
Set-Location $rootFolder; & "$folderName_Bundle\10.Seal_MP.ps1"
Set-Location $rootFolder; & "$folderName_Bundle\20.MSBuild_MPResource.ps1"
Set-Location $rootFolder; & "$folderName_Bundle\30.New_Mpb.ps1"
Set-Location $rootFolder; & "$folderName_Bundle\90.ImportUpgrade_Mpb.ps1"

. "C:\Program Files\Microsoft System Center\Service Manager\Microsoft.EnterpriseManagement.ServiceManager.UI.Console.exe"

Stop-Transcript | out-null

# read-host " "