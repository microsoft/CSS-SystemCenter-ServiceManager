Set-PSDebug -Strict # from now on, all variables must be explicitly declared before they are used  
$Error.Clear();
Set-Location $PSScriptRoot 

. ..\Build\Start_Build_ToLocalDebug.ps1
