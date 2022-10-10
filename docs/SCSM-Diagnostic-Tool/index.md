# How to run the the SCSM Diagnostic Tool?

- **Download** the latest version of SCSM Diagnostic Tool from [here](https://aka.ms/download-SCSM-Diagnostic-Tool)
- **Log on** to the Primary SCSM mgmt. server and Data Warehouse mgmt. server with an admin account, preferably with the service account of "System Center Data Access Service"
- Create a new folder, **save** the downloaded file SCSM-Diagnostic-Tool.ps1
- Right click the .PS1 file and select "**Run with PowerShell**"
- Wait till finished and then **upload** the resulting zip file to Microsoft CSS

If you want, you can open *Findings.html* included in the resulting zip file.
 
###### Note: If PowerShell starts and quits immediately, then you need to run the following command in a RunAsAdmin PowerShell window:

```
Set-ExecutionPolicy RemoteSigned
```

## Minimum requirements

- Windows Server 2016 or later
- Service Manager 2019 or later
- Windows Powershell version 4.0 or 5.1
