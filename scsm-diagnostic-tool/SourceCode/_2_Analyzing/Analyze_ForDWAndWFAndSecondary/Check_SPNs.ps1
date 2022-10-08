function Check_SPNs() {
$spn1 = GetFirstLineThatIsEqualTo (GetFileContentInSourceFolder spnSDK.txt) ("msomsdksvc/$Scsm_ComputerName")
$spn2 = GetFirstLineThatIsEqualTo (GetFileContentInSourceFolder spnSDK.txt) ("msomsdksvc/$Scsm_ComputerFqdnName")
    
    $dataRow = GetEmptyResultRow
    $dataRow.RuleName="SPNs"
    $dataRow.RuleDesc="MsOmSdkSvc SPNs for both Computer and FQDN names must be set. $(CollectorLink spnSDK.txt SPNs)"
    $dataRow.RuleResult="Both SPNs are set"
    if (IsSourceScsmWfMgmtServer) { $dataRow.SAPCategories = "wf" }
    if (IsSourceScsmDwMgmtServer) { $dataRow.SAPCategories = "dw"} 
    if (IsSourceScsmSecondaryMgmtServer) { $dataRow.SAPCategories = "sm*" } 
    $dataRow.ProblemSeverity=[ProblemSeverity]::Critical

    if ($spn1.Length -gt 0 -and $spn2.Length -gt 0) { $Result_OKs += $dataRow }
    else {        
        $dataRow.RuleResult = @"
         At least one of the required SPNs are missing in $(CollectorLink spnSDK.txt). $(GetAnchorForExternal 'https://blog.scsmsolutions.com/2012/11/configure-the-kerberos-for-scsm-2012-spn-and-delegation/' 'More SPN info')
<br/>To add the missing SPNs, run the below commands on the mgmt server (as a Domain Admin user):
<pre>
    setspn -A MSOMSdkSvc/%COMPUTERNAME% %COMPUTERNAME%
    setspn -A MSOMSdkSvc/%COMPUTERNAME%.%USERDNSDOMAIN% %COMPUTERNAME%</pre>
"@
        $Result_Problems += $dataRow
    }
}