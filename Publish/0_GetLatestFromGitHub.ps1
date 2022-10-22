# ???
# git pull  

#sample
$File = "SCSM-Diagnostic-Tool/SourceCode/main.ps1"
[DateTime]::Parse((git log -n 1 --format="%ad" --date=rfc $File)).ToUniversalTime().ToString("yy.MM.dd.HHmm")
