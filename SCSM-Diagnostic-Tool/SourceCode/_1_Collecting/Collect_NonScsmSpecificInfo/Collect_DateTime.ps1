function Collect_DateTime() {
    AppendOutputToFileInTargetFolder (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd__HH:mm.ss.fff") "Get-UtcDate.txt"
    AppendOutputToFileInTargetFolder (Get-Date).ToString("yyyy-MM-dd__HH:mm.ss.fff zzz") "Get-Date.txt"
}