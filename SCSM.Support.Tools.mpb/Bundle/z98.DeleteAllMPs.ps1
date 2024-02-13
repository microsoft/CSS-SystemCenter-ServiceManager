if (-not (Get-Module -name System.Center.Service.Manager)) { Import-Module ((Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\System Center\2010\Service Manager\Setup').InstallDirectory +'PowerShell\' +'System.Center.Service.Manager.psd1') -Force }

Write-Host "Deleting MPs ..."

Get-SCSMManagementPack -Name SCSM.Support.Tools.* | Remove-SCSMManagementPack
