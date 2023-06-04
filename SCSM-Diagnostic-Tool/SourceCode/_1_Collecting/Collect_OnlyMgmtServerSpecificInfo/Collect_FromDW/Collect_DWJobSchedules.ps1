function Collect_DWJobSchedules_Async() {
    
    $vars = @{
        "resultFolder" = $resultFolder
    }

    $code = {
        RamSB -outputString Collect_DWJobSchedules -pscriptBlock `
        {
            ImportSmDwModule
            Collect_DWJobSchedules 
        }         
    }
    RunAsync -code $code -vars $vars 
}

function Collect_DWJobSchedules() {
    $Get_SCDWJobSchedule = Get-SCDWJobSchedule
    AppendOutputToFileInTargetFolder ( $Get_SCDWJobSchedule ) "Get-SCDWJobSchedule.txt"
    AppendOutputToFileInTargetFolder ( $Get_SCDWJobSchedule | ConvertTo-Csv -NoTypeInformation )  "Get-SCDWJobSchedule.csv" 
}