Set-PSDebug -Strict # from now on, all variables must be explicitly declared before they are used  
$Error.Clear();
Set-Location $PSScriptRoot

. .\1.Generate_ContentOf_ShowTheFindings.ps1
. .\2.Build_ToLocalDebug.ps1

