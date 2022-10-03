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

`Set-ExecutionPolicy RemoteSigned`

## Minimum requirements

- Windows Server 2016 or later
- Service Manager 2019 or later
- Windows Powershell version 4.0 or 5.1

# Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## How to contribute?

- Small changes: Directly edit a file. Changes will be submitted as a pull request.
- Making changes locally & debugging: Clone this repo, open "DebuggingAndDevelopment/Start-In-Elevated-ISE-Here.ps1" in an elevated PowerShell ISE, make your changes and F5. If you want, run "BuildDeploy/BuildSingleScriptFile.ps1" to create the resulting "LastBuild\SCSM-Diagnostic-Tool.ps1" for testing locally. Then push your changes and create a pull request.

# Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft 
trademarks or logos is subject to and must follow 
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.
