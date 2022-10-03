function Analyze_ForDWAndWF() {
#region DO NOT REMOVE THIS! Exit immediately if script does NOT run on a DW or WF mgmt server.
if (-not ( (IsSourceScsmDwMgmtServer) -or (IsSourceScsmWfMgmtServer) )) {
    return
}
#endregion

 #Rules for SCSM mgmt servers excluding Secondary => only DW + WF, where SM Workflows are running

    Check_OMCFG_Service
    Check_HealthService
    Check_ScomAgent
}
