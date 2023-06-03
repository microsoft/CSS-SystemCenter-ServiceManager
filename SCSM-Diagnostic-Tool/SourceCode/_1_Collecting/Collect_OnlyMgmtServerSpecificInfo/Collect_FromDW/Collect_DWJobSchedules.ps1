function Collect_DWJobSchedules() {
    $Get_SCDWJobSchedule = Get-SCDWJobSchedule
    AppendOutputToFileInTargetFolder ( $Get_SCDWJobSchedule ) "Get-SCDWJobSchedule.txt"
    AppendOutputToFileInTargetFolder ( $Get_SCDWJobSchedule | ConvertTo-Csv -NoTypeInformation )  "Get-SCDWJobSchedule.csv" 
}
function Collect_DWJobSchedules_Async() {
    
    $initializationScript = GetFunctionDeclaration Ram
    $initializationScript += GetFunctionDeclaration RamSB
    $initializationScript += GetFunctionDeclaration AppendOutputToFileInTargetFolder

    $initializationScript += GetFunctionDeclaration Collect_DWJobSchedules

    $initializationScript += "if (-not (Get-Module -name Microsoft.EnterpriseManagement.Warehouse.Cmdlets)) { Import-Module ((Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\System Center\2010\Service Manager\Setup').InstallDirectory  +'Microsoft.EnterpriseManagement.Warehouse.Cmdlets.psd1') -Force } "

    $code = {

        if ($input.MoveNext()) { $inputs = $input.Current } else { return }  
        $resultFolder = $inputs 
     
        Ram Collect_DWJobSchedules 
    }
    $inputObject = @($resultFolder)

    Start_Async -code $code -initializationScript $initializationScript -inputObject $inputObject
}