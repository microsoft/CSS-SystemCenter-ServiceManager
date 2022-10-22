function Collect_DW_MPs() {
    $allMPs=(Try-Invoke-SqlCmd -SQLInstance $SQLInstance_SCSMDW -SQLDatabase $SQLDatabase_SCSMDW -Query "select ManagementPackId, MPName from ManagementPack")
    foreach ($currMP in $allMPs.Tables[0]) {
        $MPId = $currMP.ManagementPackId
        $MPName = $currMP.MPName
        AppendOutputToFileInTargetFolder ((Try-Invoke-SqlCmd -SQLInstance $SQLInstance_SCSMDW -SQLDatabase $SQLDatabase_SCSMDW -Query "select convert(xml,MPXML) as MPXML from ManagementPack where ManagementPackId='$MPId'").Tables[0].MPXML) "$($MPName)___$MPId.xml"
        MoveFileInTargetFolder "$($MPName)___$MPId.xml" "MPXml"
    }
}