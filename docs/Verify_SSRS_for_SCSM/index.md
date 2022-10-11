# Verify SSRS for SCSM

In the Service Manager Data Warehouse (DW) installation, the following issue is observed:

If SQL Server Reporting Services (SSRS) is running *locally* on the Data Warehouse Management Server **and** SSRS version is *2017* or later, then the Data Warehouse Setup completes successfully, but might not configure the specified local SSRS instance properly.

[Download](https://raw.githubusercontent.com/khusmeno-MS/CSS-SystemCenter-ServiceManager/main/Verify_SSRS_for_SCSM/Verify_SSRS_for_SCSM.ps1) & run the script to verify
- if the LOCAL SSRS installation is configured correctly
- and if SSRS can be used with the Service Manager Data Warehouse.

 Note

This PowerShell script can be executed after a Service Manager Data Warehouse installation. The script won't make any changes to the configuration but verifies it. You can run the script as many times as required.
