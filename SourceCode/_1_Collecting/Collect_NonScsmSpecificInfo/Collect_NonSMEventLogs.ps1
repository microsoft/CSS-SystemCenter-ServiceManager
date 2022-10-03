function Collect_NonSMEventLogs() {

    (get-wmiobject win32_nteventlogfile -filter "logfilename = 'Application'").BackupEventlog((GetFileNameInTargetFolder "Application.evtx"))| Out-Null
    wevtutil archive-log (GetFileNameInTargetFolder "Application.evtx") /l:en-US

    (get-wmiobject win32_nteventlogfile -filter "logfilename = 'System'").BackupEventlog((GetFileNameInTargetFolder "System.evtx"))| Out-Null
    wevtutil archive-log (GetFileNameInTargetFolder "System.evtx") /l:en-US
}