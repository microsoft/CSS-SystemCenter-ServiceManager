function Collect_WindowsErrorReporting() {
    AppendOutputToFileInTargetFolder ( Get-ChildItem -Path "$env:SystemDrive\users\*\appdata\local\CrashDumps" -Include *.* -Recurse -Force -ErrorAction SilentlyContinue ) WER_Files.txt    
    AppendOutputToFileInTargetFolder ( Reg query "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps" 2>&1 ) WER.regValues.txt
}