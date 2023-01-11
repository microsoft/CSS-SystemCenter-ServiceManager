function Collect_ProgramsInfo() {
    Start_Async -code { $input=$null; Get-WmiObject -Class Win32_Product | Select-Object Version, Name, InstallDate | ft } -outputFileName "ProgramVersions.txt" 

<#
NOTE: 
Do not remove
    $input=$null;

it was added, because otherwise, below error was set to -ErrorVariable later at Receive-Job.  

    The input object cannot be bound to any parameters for the command either because the command does not take pipeline input or the input and its properties do not match any of the 
parameters 
that take pipeline input.
    + CategoryInfo          : InvalidArgument: (:PSObject) [Get-WmiObject], ParameterBindingException
    + FullyQualifiedErrorId : InputObjectNotBound,Microsoft.PowerShell.Commands.GetWmiObjectCommand
    + PSComputerName        : localhost
#>
}
