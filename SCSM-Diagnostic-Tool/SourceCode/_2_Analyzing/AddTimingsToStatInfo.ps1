function AddTimingsToStatInfo() {

    $timings = (GetStatInfo).CreateNode([System.Xml.XmlNodeType]::Element, "Timings", $null)
    $smdtTotalSecs = ( ( [datetime]::ParseExact( (GetStatInfoRoot).GetAttribute("SmdtRunFinish") , "yyyy-MM-dd__HH.mm.ss.fff", $null) ) `
                     - ( [datetime]::ParseExact( (GetStatInfoRoot).GetAttribute("SmdtRunStart")  , "yyyy-MM-dd__HH.mm.ss.fff", $null) )).TotalSeconds
    $timings.SetAttribute("SmdtTotalSecs", [Math]::Truncate($smdtTotalSecs) )

    $rawData =  GetFileContentInSourceFolder Collector-MeasuredScriptBlocks.csv | ConvertFrom-Csv
    $rawData += GetFileContentInTargetFolder Analyzer-MeasuredScriptBlocks.csv  | ConvertFrom-Csv
    $rawDataSorted = $rawData | Sort-Object -Property Duration -Descending

    foreach($line in $rawDataSorted) {        
        $msecs = [timespan]::Parse($line.Duration).TotalMilliseconds
        $info = $line.ScriptBlockText
       
        $timing = CreateElementForStatInfo -elemTagName Timing
        $timing.SetAttribute("Info", $info )
        $timing.SetAttribute("Msecs", $msecs )
        $timings.AppendChild( $timing )
    }
    AddToStatInfoRoot $timings
}
