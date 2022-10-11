# Verify SSRS for SCSM

In the Service Manager Data Warehouse (DW) installation, the following issue is observed:

If SQL Server Reporting Services (SSRS) is running *locally* on the Data Warehouse Management Server **and** SSRS version is *2017* or later, then the Data Warehouse Setup completes successfully, but might not configure the specified local SSRS instance properly.

[Download](https://github.com/microsoft/CSS-SystemCenter-ServiceManager/releases/latest/download/Verify_SSRS_for_SCSM.ps1) & run the script to verify
- if the LOCAL SSRS installation is configured correctly
- and if SSRS can be used with the Service Manager Data Warehouse.

## Instructions to run this script:

1. Execute the script with right/click + "Run with PowerShell".
1. Follow the instructions.    

## Notes:
The script can be executed before or after a SCSM Data Warehouse installation.
The script can be executed several times. 
The script won't make any change.
