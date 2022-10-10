# Introduction

*SCSM Diagnostic Tool* allows you to collect diagnostic logs from your Service Manager environment to help you and Microsoft technical support engineers to resolve Service Manager technical incidents faster. It is a light, script-based, open-source tool. SCSM Diagnostic Tool discovers the SCSM components installed locally on the system (like Primary/Secondary Management Server, Data Warehouse Management Server, Portal, Console) and collects information accordingly.

In addition, it runs predefined "rules" against the collected info and generates a file named *Findings.html*. Customers can open this file and can implement the suggested actions prior to open a ticket with Microsoft Customer Support Services (CSS).

SCSM Diagnostic Tool is developed and maintained by members of the Microsoft System Center technical support team in CSS.

# How to run the tool?

- **Download** the latest version of SCSM Diagnostic Tool at [https://aka.ms/get-SCSM-Diagnostic-Tool](https://aka.ms/get-SCSM-Diagnostic-Tool)
- **Log on** to the Primary SCSM mgmt. server and Data Warehouse mgmt. server with an admin account, preferably with the service account of "System Center Data Access Service"
- Create a new folder, **save** the downloaded file SCSM-Diagnostic-Tool.ps1
- Right click the .PS1 file and select "**Run with PowerShell**"
- Wait till finished and then **upload** the resulting zip file to Microsoft CSS

If you want, you can open *Findings.html* included in the resulting zip file.
 
Note: If PowerShell starts and quits immediately, then you need to run the following command in a RunAsAdmin PowerShell window:

```
Set-ExecutionPolicy RemoteSigned
```

## Minimum requirements

- Windows Server 2016 or later
- Service Manager 2019 or later
- Windows Powershell version 4.0 or 5.1

## How to contribute?

- Small changes: Directly edit a file. Changes will be submitted as a pull request.
- Making changes locally & debugging: Clone this repo, open "DebuggingAndDevelopment/Start-In-Elevated-ISE-Here.ps1" in an elevated PowerShell ISE, make your changes and F5. If you want, run "BuildDeploy/BuildSingleScriptFile.ps1" to create the resulting "LastBuild\SCSM-Diagnostic-Tool.ps1" for testing locally. Then push your changes and create a pull request.

