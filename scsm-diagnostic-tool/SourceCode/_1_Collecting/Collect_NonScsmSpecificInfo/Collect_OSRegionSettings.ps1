function Collect_OSRegionSettings() {
    #to be used later by Analyzer
    AppendOutputToFileInTargetFolder ( [System.Threading.Thread]::CurrentThread.CurrentCulture.NumberFormat | ConvertTo-Csv ) CurrentCulture.NumberFormat.csv
    AppendOutputToFileInTargetFolder ( [System.Threading.Thread]::CurrentThread.CurrentCulture.DateTimeFormat | ConvertTo-Csv ) CurrentCulture.DateTimeFormat.csv
}