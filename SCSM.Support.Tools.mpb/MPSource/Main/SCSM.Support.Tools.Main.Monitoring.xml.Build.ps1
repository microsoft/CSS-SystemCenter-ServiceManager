$folderName_Bundle =     "Bundle"  
$folderName_MPSource =   "MPSource"  
$folderName_MPResource = "MPResource"  
$folderName_Output   =   "Output"    
$folderName_Misc     =   "Misc"      
if ( (Split-Path -Path (Get-Location) -Leaf) -eq $folderName_Bundle ) {
    cd ".."  # Set folder to root
}

$mpSource_Monitoring = "Main\SCSM.Support.Tools.Main.Monitoring.xml"
$ruleID_Monitoring =        "SCSM.Support.Tools.Main.Monitoring.Rule.Starter"

$mpFullPath =  Resolve-Path ( "$folderName_Output\" + (Split-Path -Path "$mpSource_Monitoring" -Leaf) )
$doc = [xml]::new()
$doc.Load($mpFullPath)
$doc.CreateXmlDeclaration("1.0", "utf-8", $null) | Out-Null
$fileNodes = $doc.DocumentElement.SelectNodes("/ManagementPack/Monitoring/Rules/Rule[@ID='$ruleID_Monitoring']/WriteActions/WriteAction/Files/File");
foreach($fileNode in $fileNodes) {
    if ($fileNode.Name -eq "SCSM.Support.Tools.RunScriptFromResource.ps1") {
        $currentNode = $fileNode
        break
    }
}

$newInnerTextContentFileFullPath = ((Resolve-Path -Path "$folderName_Misc\SCSM.Support.Tools.GenericScriptStarterFromResource.ps1").Path)
$newInnerText = [IO.File]::ReadAllText($newInnerTextContentFileFullPath , [System.Text.Encoding]::UTF8)
$currentNode.Contents = $newInnerText
$doc.Save($mpFullPath)   


