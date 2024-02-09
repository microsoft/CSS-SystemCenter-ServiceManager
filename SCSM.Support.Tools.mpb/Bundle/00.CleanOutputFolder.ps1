$folderName_Bundle =     "Bundle"  
$folderName_MPSource =   "MPSource"  
$folderName_MPResource = "MPResource"  
$folderName_Output   =   "Output"    
$folderName_Misc     =   "Misc"      

if ( (Split-Path -Path (Get-Location) -Leaf) -eq $folderName_Bundle ) {
    cd ".."  # Set folder to root
}

$filesToKeep = @()
$filesToKeep = "Central.AssemblyInfo.cs"

foreach($file in (Get-ChildItem -Path $folderName_Output)) {
    if ( $filesToKeep.Contains($file.Name) ) {
        continue
    }
    $file | Remove-Item -Force
} 