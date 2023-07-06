<a style="color: black;background-color: yellow;" target="_blank" href="https://forms.office.com/r/QpC8qkSLVA" title="Just a single question!">Feedback 😊 😐</a>
# SCSM Diagnostic Tool

Download the latest release:  [SCSM-Diagnostic-Tool.ps1]({{ site.latestDownloadLink }}/SCSM-Diagnostic-Tool.ps1)

## Description

The *SCSM Diagnostic Tool* allows you to collect diagnostic logs from your Service Manager environment to help you and Microsoft technical support engineers to resolve Service Manager technical incidents faster. It is a light, script-based, open-source tool.

SCSM Diagnostic Tool discovers the SCSM components installed locally on the system (like Primary/Secondary Management Server, Data Warehouse Management Server, Portal, Console) and collects information accordingly.  

Afterwards, it runs predefined "rules" against the collected info and generates a `Findings` report. Customers can review it and can implement the suggested actions prior to open a ticket with Microsoft Customer Support Services (CSS).

# How to run

1. **Log on** to the Primary SCSM mgmt. server and Data Warehouse mgmt. server with an admin account, preferably with the service account of the "System Center Data Access Service".
2. **Save** the script into a folder.
3. Execute the script with right/click + **"Run with PowerShell"**.
   > ##### Note: 
   > If PowerShell starts and quits immediately, then you need to run the following command in a RunAsAdmin PowerShell window:
   ````
   Set-ExecutionPolicy RemoteSigned
   ````
4. Follow the instructions.
5. **Upload** the resulting zip file to Microsoft CSS.

If you want to review the `Findings`, extract all files and folders in the resulting zip file, then run `ShowTheFindings.ps1`.
 
## Minimum requirements

- Windows Server 2016 or later
- Service Manager 2019 or later
- Windows PowerShell version 5.1

## Notes:

- The script won't make any change in the SCSM environment.
- The script can be also used as a Health Checker. 

## Do you want to contribute to this tool?

[Here]({{ site.GitHubRepoLink }}/SCSM-Diagnostic-Tool) is the GitHub repo.
