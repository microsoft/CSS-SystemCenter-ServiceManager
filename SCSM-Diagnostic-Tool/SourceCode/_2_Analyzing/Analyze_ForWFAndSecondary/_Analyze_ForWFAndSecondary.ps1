function Analyze_ForWFAndSecondary() {
#region DO NOT REMOVE THIS! Exit immediately if script does NOT run on a WF or Secondary mgmt server.
if (-not (IsSourceScsmMgmtServer) ) {
    return
}
#endregion


 #Rules for WF + Secondary
 #Note: Despite that a secondary MS does not run the WFs, as WF related info was collected (from db) we are analyzing them here (as much as we can), too.

    Check_ECLRowCount
    Check_CustomRelationshipTypes
    Check_WorkflowsMinutesBehind
    Check_ConnectorStatus
    Check_GroomingAndPurging
    if ( $SCSM_Version -eq '10.19.1035.101' ) { Check_DelayedWorkflows_2019UR2Only }
    Check_RegisteredDW_Availability
    Check_SqlCLRonRegisteredDWSql  # This rule depends on the outcome of Check_RegisteredDW_Availability, therefore must be called after.
    Check_ObjectTemplates_WithNoLocalizations
}
