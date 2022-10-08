function Finish($resultingZipFile_FullPath) {

    cls    

    Write-Host @"
*************************** --- IMPORTANT NOTICE --- **************************
The script is designed to collect information that will help Microsoft Customer Support Services (CSS) troubleshoot an issue you may be experiencing.
The collected zip file may contain Personally Identifiable Information (PII) and/or sensitive data, such as (but not limited to) paths to files, paths to registry keys, process names, host names, user names and IP addresses.
You can send the zip file to Microsoft CSS using a secure file transfer tool. Info about Secure File Exchange: https://docs.microsoft.com/en-US/troubleshoot/azure/general/secure-file-exchange-transfer-files.
Please discuss this with your support professional and also any concerns you may have.
By sending the zip file to Microsoft Support you accept that you are aware of the content of the zip file.
*******************************************************************************
"@
    Write-Host -NoNewline "Please send file "; Write-Host -NoNewline -ForegroundColor Yellow $resultingZipFile_FullPath; Write-Host " to Microsoft Support."
    Write-Host ""
    Write-Host "Press ENTER to navigate to the resulting zip file..." -ForegroundColor Cyan
    Read-Host " "  
      
    start (join-path $env:Windir explorer.exe) -ArgumentList "/select, ""$resultingZipFile_FullPath"""
}


