function Collect_SetDWRoleFound() {
    AppendOutputToFileInTargetFolder "This is the DW mgmt server." ScsmRolesFound.txt
    $script:RoleFoundAbbr = "DW"
}