function Collect_ConnectedSDKUsersCount() {
    AppendOutputToFileInTargetFolder (Get-Counter -Counter "\OpsMgr SDK Service(system center data access service)\Client Connections" )  "ConnectedSDKUsers.txt"
}