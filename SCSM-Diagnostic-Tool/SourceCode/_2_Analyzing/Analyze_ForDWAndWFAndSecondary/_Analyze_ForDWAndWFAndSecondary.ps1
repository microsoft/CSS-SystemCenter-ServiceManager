function Analyze_ForDWAndWFAndSecondary() {
#region DO NOT REMOVE THIS! Exit immediately if script does NOT run on a DW or WF or Secondary mgmt server.
if (-not (IsSourceAnyScsmMgmtServer)) {
    return
}
#endregion

 #Rules for All SCSM mgmt servers => WF + Secondary + DW

#region Not a rule: Get DB info to be used in subsequent rules. This applies to ServiceManager and DWStagingAndConfig as well.
    $linesIn_regValues = GetFileContentInSourceFolder SystemCenter.regValues.txt

    $MainSQL_InstanceName = GetFirstLineThatStartsWith $linesIn_regValues '"DatabaseServerName"="'    
    $MainSQL_InstanceName = $MainSQL_InstanceName.Split("=")[1].Replace('"','')
    $MainSQL_DbName = GetFirstLineThatStartsWith $linesIn_regValues '"DatabaseName"="'
    $MainSQL_DbName = $MainSQL_DbName.Split("=")[1].Replace('"','')
#endregion

    Check_CollectorsSqlPermission
    Check_MgmtServerHW
    Check_SQLServerHW
    Check_SqlBroker
    Check_SqlCLR
    Check_SPNs
    Check_OMSDK_Service
    Check_ConnectedSDKUsers
    Check_TimeDiffBetweenMSAndSQL
} 
