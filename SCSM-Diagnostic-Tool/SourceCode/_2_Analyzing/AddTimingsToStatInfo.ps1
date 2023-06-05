function AddTimingsToStatInfo() {

    [string]$minData = "msec,info`n"

    #Collector
    $rawData = GetFileContentInSourceFolder Collector-MeasuredScriptBlocks.csv | ConvertFrom-Csv
    foreach($line in $rawData) {        
        $msec = [timespan]::Parse($line.Duration).TotalMilliseconds
        $info = $line.ScriptBlockText
        $minData += "$msec,$info`n"
    }

    #Analyzer
    $rawData = GetFileContentInTargetFolder Analyzer-MeasuredScriptBlocks.csv | ConvertFrom-Csv
    foreach($line in $rawData) {        
        $msec = [timespan]::Parse($line.Duration).TotalMilliseconds
        $info = $line.ScriptBlockText
        $minData += "$msec,$info`n"
    }

    $timings = $script:statInfo.CreateNode([System.Xml.XmlNodeType]::Element, "Timings", $null)
    $timings.InnerText = $minData  
    AddToStatInfo $timings

}
