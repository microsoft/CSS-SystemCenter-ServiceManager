if (-not (Get-Module -name System.Center.Service.Manager)) { Import-Module ((Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\System Center\2010\Service Manager\Setup').InstallDirectory +'PowerShell\' +'System.Center.Service.Manager.psd1') -Force }

$HS_MP = Get-SCSMManagementPack -Name SCSM.Support.Tools.HealthStatus.Core

if ($HS_MP) {

    #region mandatory part before doing any update on instance of HealthStatus.WF or HealthStatus.DW
    $enumSeverity_Critical = $HS_MP.EntityTypes.GetEnumerations("SCSM.Support.Tools.HealthStatus.Enum.Severity.Critical")[0].Id
    $enumSeverity_Error = $HS_MP.EntityTypes.GetEnumerations("SCSM.Support.Tools.HealthStatus.Enum.Severity.Error")[0].Id
    $enumSeverity_Warning = $HS_MP.EntityTypes.GetEnumerations("SCSM.Support.Tools.HealthStatus.Enum.Severity.Warning")[0].Id
    $enumSeverity_Unknown = $HS_MP.EntityTypes.GetEnumerations("SCSM.Support.Tools.HealthStatus.Enum.Severity.Unknown")[0].Id
    $enumSeverity_Good = $HS_MP.EntityTypes.GetEnumerations("SCSM.Support.Tools.HealthStatus.Enum.Severity.Good")[0].Id
    
    $enumTriggerMethod_Manual = $HS_MP.EntityTypes.GetEnumerations("SCSM.Support.Tools.HealthStatus.Enum.TriggerMethod.Manual")[0].Id
    $enumTriggerMethod_Schedule = $HS_MP.EntityTypes.GetEnumerations("SCSM.Support.Tools.HealthStatus.Enum.TriggerMethod.Schedule")[0].Id

    $enumComponent_WF = $HS_MP.EntityTypes.GetEnumerations("SCSM.Support.Tools.HealthStatus.Enum.Component.WF")[0].Id
    $enumComponent_DW = $HS_MP.EntityTypes.GetEnumerations("SCSM.Support.Tools.HealthStatus.Enum.Component.DW")[0].Id   

    $HS_WF = Get-SCSMClassInstance -Class (Get-SCSMClass -Name SCSM.Support.Tools.HealthStatus.WF)
    $HS_DW = Get-SCSMClassInstance -Class (Get-SCSMClass -Name SCSM.Support.Tools.HealthStatus.DW)
    $HS_Overall = Get-SCSMClassInstance -Class (Get-SCSMClass -Name SCSM.Support.Tools.HealthStatus.Overall)

    #always ADD below relationships. It does not harm even if they already exist
    $rsClassWF = Get-SCSMRelationshipClass -Name SCSM.Support.Tools.HealthStatus.OverallToWF
    New-SCRelationshipInstance -RelationshipClass $rsClassWF -Source $HS_Overall -Target $HS_WF
    $rsClassDW = Get-SCSMRelationshipClass -Name SCSM.Support.Tools.HealthStatus.OverallToDW
    New-SCRelationshipInstance -RelationshipClass $rsClassDW -Source $HS_Overall -Target $HS_DW

    $HS_Overall.LastChanged = [datetime]::Now
    $HS_Overall | Update-SCSMClassInstance
    #endregion

    #region can be null
    $HS_WF.MaxSeverity = $enumSeverity_Error
    $HS_WF.ServerName = "SmSc2019"
    $HS_WF.ResultingZipFileAtFullPath = '\\scosc2019\c$\Users\khusmeno\Downloads\SCSM_DIAG_WF_2023-12-28__16.20.53.486.zip'
    $HS_WF.LastRun = [datetime]::now.Subtract( [timespan]::new(0,-3,-30,0) )
    $HS_WF.TriggerMethod = $enumTriggerMethod_Manual
    #endregion 
    $HS_WF | Update-SCSMClassInstance

    #region can be null
    $HS_DW.MaxSeverity = $enumSeverity_Critical
    $HS_DW.ServerName = "ScoSmSc2019"
    $HS_DW.ResultingZipFileAtFullPath = 'c:\Users\khusmeno\Downloads\SCSM_DIAG_DW_2022-12-12__12.12.12.111.zip'
    $HS_DW.LastRun = [datetime]::now.Subtract( [timespan]::new(0,-1,0,0) )
    $HS_DW.TriggerMethod = $enumTriggerMethod_Schedule
    #endregion 
    $HS_DW | Update-SCSMClassInstance

    <# 
    Get-SCSMRelationshipInstance -SourceInstance $HS_Overall -TargetInstance $HS_WF | ? { $_.IsDeleted -eq $false } | Select-Object -Property * | ft
    Get-SCSMRelationshipInstance -SourceInstance $HS_Overall -TargetInstance $HS_DW | ? { $_.IsDeleted -eq $false } | Select-Object -Property * | ft
    Get-SCSMRelationshipInstance -SourceInstance $HS_Overall | Remove-SCSMRelationshipInstance

    Get-SCSMRelationshipInstance -SourceInstance $HS_Overall | ? { $_.IsDeleted -eq $false } | Select-Object -Property * | ft
    #>

}