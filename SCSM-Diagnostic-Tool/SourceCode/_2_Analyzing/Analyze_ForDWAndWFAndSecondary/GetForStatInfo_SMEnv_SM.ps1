function GetForStatInfo_SMEnv_SM() {
    $MGinfo = GetSanitizedCsv ( GetFileContentInSourceFolder SQL_MOMManagementGroupInfo.csv ) | ConvertFrom-Csv
    (GetSmEnvInStatInfo).SM.SetAttribute("MGId", $MGinfo.ManagementGroupId)

    try {
        $HSinfo = GetSanitizedCsv ( GetFileContentInSourceFolder SQL_MgmtServer_Availability.csv ) | ConvertFrom-Csv
        $hostNameFqdn = (GetFileContentInSourceFolder Hostname_fqdn.txt).Trim()
        $HSId = ($HSinfo | ? { $_.MS_DisplayName -eq $hostNameFqdn} | Select-Object -Property MS_BmeId).MS_BmeId
        (GetSmEnvInStatInfo).SM.SetAttribute("HSId",$HSId)
    } catch {} # ignore if not running on WF or 2ndMS, e.g. DW
}