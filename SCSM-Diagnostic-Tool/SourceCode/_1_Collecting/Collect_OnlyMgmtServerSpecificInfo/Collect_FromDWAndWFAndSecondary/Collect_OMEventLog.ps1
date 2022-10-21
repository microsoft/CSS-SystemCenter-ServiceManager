function Collect_OMEventLog() {
    (get-wmiobject win32_nteventlogfile -filter "logfilename = 'Operations Manager'").BackupEventlog((GetFileNameInTargetFolder "OperationsManager.evtx")) | Out-Null
    wevtutil archive-log (GetFileNameInTargetFolder "OperationsManager.evtx") /l:en-US
}