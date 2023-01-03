function Collect_Test_LocalOMSDK_Response() {   
     AppendOutputToFileInTargetFolder ( InvokeCommand_AlwaysReturnOutput_ButOnlyWriteErrorToConsole { Get-SCSMManagementPack | measure } )  Test_LocalOMSDK_Response.txt
}