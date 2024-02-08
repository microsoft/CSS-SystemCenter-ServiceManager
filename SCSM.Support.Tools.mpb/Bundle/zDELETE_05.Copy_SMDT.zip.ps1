$folderName_Bundle =     "Bundle"  
$folderName_MPSource =   "MPSource"  
$folderName_MPResource = "MPResource"  
$folderName_Output   =   "Output"    
$folderName_Misc     =   "Misc" 
if ( (Split-Path -Path (Get-Location) -Leaf) -eq $folderName_Bundle ) {
    cd ".."  # Set folder to root
}

Write-Host "Copying smdt.zip..."

$smdtFullPath = "..\SCSM-Diagnostic-Tool\LocalDebug\SCSM-Diagnostic-Tool.ps1"
copy $smdtFullPath $folderName_Output
