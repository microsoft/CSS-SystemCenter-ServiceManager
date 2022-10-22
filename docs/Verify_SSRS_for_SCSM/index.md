# Verify SSRS for SCSM
Download the latest release: [Verify_SSRS_for_SCSM.ps1]({{ site.latestDownloadLink }}/Verify_SSRS_for_SCSM.ps1)   

## Description
The SCSM Data Warehouse Setup normally configures the specified SQL Server Reporting Services (SSRS) instance, but only if SSRS is running locally.  
In some situations, the SCSM Data Warehouse Setup completes successfully, but might not configure the specified SSRS instance properly, even SSRS is running locally. This can happen if SSRS version is *2017* or later.

## Purpose
To verify if the *LOCAL* SSRS installation has been configured correctly by the SCSM Data Warehouse Setup. 

## How to run
1. Save the script on the DW management server where SSRS is locally running.
1. Execute the script with right/click + "Run with PowerShell".
1. Follow the instructions.    

## Notes:
- The script can be executed before or after a SCSM Data Warehouse installation.
- The script can be executed several times. 
- The script won't make any change.
- The script verifies only SSRS instances which are running locally.
- The script is NOT applicable if SSRS instance is running remotely. In this case, the steps in this article needs to be done manually: https://learn.microsoft.com/en-us/system-center/scsm/config-remote-ssrs

## Do you want to contribute to this script?
[Here]({{ site.GitHubRepoLink }}/Verify_SSRS_for_SCSM) is the GitHub repo.
