function AddTimingsToStatInfo() {

    $timings = (GetStatInfo).CreateNode([System.Xml.XmlNodeType]::Element, "Timings", $null)

    $SmdtRunStart  = ConvertDateTimeStringToDateTime (GetStatInfoRoot).GetAttribute("SmdtRunStart")
    $SmdtRunFinish = ConvertDateTimeStringToDateTime (GetStatInfoRoot).GetAttribute("SmdtRunFinish")
    $smdtTotalSecs = ( $SmdtRunFinish - $SmdtRunStart ).TotalSeconds
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
        $timings.AppendChild( $timing ) | Out-Null
    }
    AddToStatInfoRoot $timings
}
