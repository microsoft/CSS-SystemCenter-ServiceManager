function Collect_RegisteredDWEnvironmentInfo() {
#this function writes into more than 1 file!

    #get the registered DW mgmt server name. 
    $registeredDwMS = (Try-Invoke-SqlCmd -SQLInstance $SQLInstance_SCSM -SQLDatabase $SQLDatabase_SCSM 'select dw.Server_48B308F9_CF0E_0F74_83E1_0AEB1B58E2FA as "DW mgmt server name" from MT_Microsoft$SystemCenter$ResourceAccessLayer$DwSdkResourceStore dw inner join BaseManagedEntity bme on dw.BaseManagedEntityId=bme.BaseManagedEntityId').Tables[0].'DW mgmt server name'
    
    #if not registered then immediately return, no need for further collection.
    if ($registeredDwMS -eq $null) {
        return
    }
    
    AppendOutputToFileInTargetFolder ( InvokeCommand_AlwaysReturnOutput_ButOnlyWriteErrorToConsole { Get-SCSMManagementPack -ComputerName $registeredDwMS | measure } )  Test_RegisteredDW_SDK.txt

    $GetSCDWInfraLocationResultCsv = Get-SCDWInfraLocation -ComputerName $registeredDwMS | ConvertTo-Csv -NoTypeInformation
    AppendOutputToFileInTargetFolder $GetSCDWInfraLocationResultCsv "Get-SCDWInfraLocation_FromRegisteredDW.csv"

    $GetSCDWInfraLocationResult = ConvertFrom-Csv -InputObject $GetSCDWInfraLocationResultCsv
    $DwStagingAndConfigDbInfo = $GetSCDWInfraLocationResult | ? { $_.InfraType -eq 'StagingAndConfigDatabase' } 
    SaveSQLResultSetsToFiles $DwStagingAndConfigDbInfo.Server $DwStagingAndConfigDbInfo.Value "exec sp_configure 'show advanced options',1 ; RECONFIGURE; exec sp_configure" SQL_sp_configure_FromRegisteredDwSQL.csv 
}