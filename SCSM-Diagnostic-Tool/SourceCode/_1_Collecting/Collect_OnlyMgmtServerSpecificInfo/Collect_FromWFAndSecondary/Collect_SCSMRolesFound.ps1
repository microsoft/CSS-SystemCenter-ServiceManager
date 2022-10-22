function Collect_SCSMRolesFound() {

    $role = "It is unknown what type of SCSM components are installed on this machine."
    $script:RoleFoundAbbr = "UNK"

    if (IsThisScsmWfMgmtServer) {
        $role="This is the Primary/Workflow mgmt server."
        $script:RoleFoundAbbr = "WF"
    }
    elseif (IsThisScsmSecondaryMgmtServer) {
        $role = "This is a Secondary mgmt server"
        $script:RoleFoundAbbr = "2MS"
    }
    AppendOutputToFileInTargetFolder $role "ScsmRolesFound.txt" 
}