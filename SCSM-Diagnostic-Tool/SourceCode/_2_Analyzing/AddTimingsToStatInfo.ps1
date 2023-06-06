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
    $timings.InnerText = $minData  

    AddToStatInfoRoot $timings
}
