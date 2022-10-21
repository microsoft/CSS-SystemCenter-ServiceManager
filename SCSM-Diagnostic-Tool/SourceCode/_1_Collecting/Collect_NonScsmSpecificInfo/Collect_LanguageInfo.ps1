function Collect_LanguageInfo() {
    AppendOutputToFileInTargetFolder (Invoke-Expression -Command "dism.exe /online /Get-intl") "LanguageInfo.txt"
}
