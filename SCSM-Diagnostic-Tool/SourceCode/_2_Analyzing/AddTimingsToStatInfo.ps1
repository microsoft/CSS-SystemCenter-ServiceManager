function AddTimingsToStatInfo() {

    $rawData =  GetFileContentInSourceFolder Collector-MeasuredScriptBlocks.csv | ConvertFrom-Csv
    $rawData += GetFileContentInTargetFolder Analyzer-MeasuredScriptBlocks.csv  | ConvertFrom-Csv
    $rawDataSorted = $rawData | Sort-Object -Property Duration -Descending

    [string]$minData = "msec,info`n"
    foreach($line in $rawDataSorted) {        
        $msec = [timespan]::Parse($line.Duration).TotalMilliseconds
        $info = $line.ScriptBlockText
        $minData += "$msec,$info`n"
    }

    $timings = (GetStatInfo).CreateNode([System.Xml.XmlNodeType]::Element, "Timings", $null)
    $smdtTotalSecs = ( ( [datetime]::ParseExact( (GetStatInfoRoot).GetAttribute("SmdtRunFinish") , "yyyy-MM-dd__HH.mm.ss.fff", $null) ) `
                     - ( [datetime]::ParseExact( (GetStatInfoRoot).GetAttribute("SmdtRunStart")  , "yyyy-MM-dd__HH.mm.ss.fff", $null) )).TotalSeconds
    $timings.SetAttribute("SmdtTotalSecs", [Math]::Truncate($smdtTotalSecs) )
    $timings.InnerText = $minData  

    AddToStatInfoRoot $timings
}
