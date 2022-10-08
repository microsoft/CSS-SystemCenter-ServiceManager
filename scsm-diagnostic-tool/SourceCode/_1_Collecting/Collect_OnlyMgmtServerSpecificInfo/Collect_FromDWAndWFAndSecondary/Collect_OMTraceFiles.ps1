function Collect_OMTraceFiles() {
    Copy-Item -Path "$env:windir\Logs\OpsMgrTrace" -Destination (GetFileNameInTargetFolder "OpsMgrTrace") -Recurse  -ErrorAction SilentlyContinue
}