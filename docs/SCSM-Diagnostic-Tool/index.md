# SCSM Diagnostic Tool

The *SCSM Diagnostic Tool* allows you to collect diagnostic logs from your Service Manager environment to help you and Microsoft technical support engineers to resolve Service Manager technical incidents faster. It is a light, script-based, open-source tool. SCSM Diagnostic Tool discovers the SCSM components installed locally on the system (like Primary/Secondary Management Server, Data Warehouse Management Server, Portal, Console) and collects information accordingly.

In addition, it runs predefined "rules" against the collected info and generates a file named *Findings.html*. Customers can open this file and can implement the suggested actions prior to open a ticket with Microsoft Customer Support Services (CSS).

SCSM Diagnostic Tool is developed and maintained by members of the Microsoft System Center technical support team in CSS.

# How to run the SCSM Diagnostic Tool?

- **Download** the latest version of SCSM Diagnostic Tool from [here](https://aka.ms/download-SCSM-Diagnostic-Tool)
- **Log on** to the Primary SCSM mgmt. server and Data Warehouse mgmt. server with an admin account, preferably with the service account of the "System Center Data Access Service"
- **Save** the downloaded file into a folder
- Right click SCSM-Diagnostic-Tool.ps1 and select "**Run with PowerShell**"
- Wait until finished and then **upload** the resulting zip file to Microsoft CSS

If you want, you can open *Findings.html* included in the resulting zip file.
 
###### Note: If PowerShell starts and quits immediately, then you need to run the following command in a RunAsAdmin PowerShell window:

```
Set-ExecutionPolicy RemoteSigned
```

## Minimum requirements

- Windows Server 2016 or later
- Service Manager 2019 or later
- Windows Powershell version 4.0 or later

## Do you want to contribute to this tool?

[Here](https://github.com/khusmeno-MS/CSS-SystemCenter-ServiceManager/tree/main/scsm-diagnostic-tool) is the GitHub repo.
