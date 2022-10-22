function Collect_SMTraceFiles() {
    Copy-Item -Path "$env:windir\Temp\SMTrace" -Destination (GetFileNameInTargetFolder "SMTrace") -Recurse  -ErrorAction SilentlyContinue
}