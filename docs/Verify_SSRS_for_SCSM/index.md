# Verify SSRS for SCSM
Download the latest release: [Verify_SSRS_for_SCSM.ps1](https://github.com/microsoft/CSS-SystemCenter-ServiceManager/releases/latest/download/Verify_SSRS_for_SCSM.ps1)   

## Description
In some situations, the SCSM Data Warehouse Setup completes successfully, but might not configure the specified SQL Server Reporting Services (SSRS) instance properly. This can happen if:
- SSRS is running *locally* together with the Data Warehouse Management Server
-  ***and*** SSRS version is *2017* or later.

## Purpose
To verify if the *LOCAL* SSRS installation has been configured correctly. 

## How to run
1. Save the script where SSRS is locally running.
1. Execute the script with right/click + "Run with PowerShell".
1. Follow the instructions.    

## Notes:
- The script can be executed before or after a SCSM Data Warehouse installation.
- The script can be executed several times. 
- The script won't make any change.

## Do you want to contribute to this script?
[Here](https://github.com/khusmeno-MS/CSS-SystemCenter-ServiceManager/tree/main/Verify_SSRS_for_SCSM) is the GitHub repo.
