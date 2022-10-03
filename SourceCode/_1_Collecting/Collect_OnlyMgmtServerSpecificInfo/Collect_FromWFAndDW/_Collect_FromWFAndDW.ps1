function Collect_FromWFAndDW() {
#region DO NOT REMOVE THIS! Exit immediately if script is NOT running on a WF or DW server
if (-not ( (IsThisScsmWfMgmtServer) -or (IsThisScsmDwMgmtServer) )) {
    return
}
#endregion

# Collects info that is specific to only WF and DW servers

#...nothing to collect for now that is specific to only WF or DW servers
}