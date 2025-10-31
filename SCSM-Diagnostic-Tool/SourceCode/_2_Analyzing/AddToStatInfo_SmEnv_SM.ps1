function AddToStatInfo_SmEnv_SM() {

    if (IsSourceScsmMgmtServer) {  # if running on a WF or Secondary mgmt server.

        #region Notification Channel
        # Caution: Authentication types are hardcoded to be only Anonymous,OAUTHAuthentication,WindowsIntegrated
        $Channel = CreateElementForStatInfo -elemTagName Channel
        $ChannelData =  GetFileContentInSourceFolder Get-SCSMChannel.csv | ConvertFrom-Csv
        $Channel.SetAttribute("IsEnabled", $ChannelData.IsEnabled)

        $ConfigurationSources = CreateElementForStatInfo -elemTagName ConfigurationSources
        $ConfigurationSourcesData =  GetFileContentInSourceFolder Get-SCSMChannel_WithAuthentication.csv | ConvertFrom-Csv 
        $authCounts = @{
            "Anonymous" = 0
            "OAUTHAuthentication" = 0
            "WindowsIntegrated" = 0
        }
        $count_Total = 0
        $ConfigurationSources.SetAttribute("PrimaryAuth", "None")
        foreach($line in $ConfigurationSourcesData) {
            if ($line.SequenceNumber -eq "0") {
                $ConfigurationSources.SetAttribute("PrimaryAuth", $line.Authentication)
            }
            $ConfigurationSource = CreateElementForStatInfo -elemTagName ConfigurationSource
            $ConfigurationSource.SetAttribute("SequenceNumber", $line.SequenceNumber)
            $ConfigurationSource.SetAttribute("Authentication", $line.Authentication)

            $ConfigurationSources.AppendChild( $ConfigurationSource ) | Out-Null

            $authCounts[$line.Authentication]++
            $count_Total++
        }
        $ConfigurationSources.SetAttribute("Count_Total", $count_Total.ToString() )
        $ConfigurationSources.SetAttribute("Count_Anonymous", $authCounts["Anonymous"].ToString() )
        $ConfigurationSources.SetAttribute("Count_OAUTHAuthentication", $authCounts["OAUTHAuthentication"].ToString() )
        $ConfigurationSources.SetAttribute("Count_WindowsIntegrated", $authCounts["WindowsIntegrated"].ToString() )

        $Channel.AppendChild($ConfigurationSources)
        $smEnv_SM.AppendChild($Channel)      
        #endregion   
    
        #region Connectors
        $Connectors = CreateElementForStatInfo -elemTagName Connectors
        $Connectors.SetAttribute("Count_Total", 0)
        $Connectors.SetAttribute("Count_Enabled", 0)
        $smEnv_SM.AppendChild($Connectors)

        $ConnectorsData = ConvertFrom-Csv (GetSanitizedCsv ( GetFileContentInSourceFolder SQL_Connectors.csv) ) 
        $Connectors.SetAttribute("Count_Total", $ConnectorsData.Count)
        $Connectors.SetAttribute("Count_Enabled", ($ConnectorsData | ? {$_.Enabled -eq $true}).Count)
        #endregion

        #region Exchange Connectors
        $ExchangeConnectors = CreateElementForStatInfo -elemTagName Exchange
        $ExchangeConnectors.SetAttribute("Version", "None")
        $ExchangeConnectors.SetAttribute("Count_Total", 0)
        $ExchangeConnectors.SetAttribute("Count_Enabled", 0)
        $ExchangeConnectors.SetAttribute("Count_Enabled_ExchOnline", 0)
        $ExchangeConnectors.SetAttribute("Count_Enabled_ExchOnPremise", 0)
        $Connectors.AppendChild($ExchangeConnectors)

        # check EC dll Version, only continue if there.
        $ExchangeConnectorDllInfo = ConvertFrom-Csv (GetFileContentInSourceFolder SCSM_Files.csv) | ? { $_.FullName.EndsWith('\Microsoft.SystemCenter.ExchangeConnector.dll') }
        if ($ExchangeConnectorDllInfo) {
            $ExchangeConnectors.SetAttribute("Version",  $ExchangeConnectorDllInfo.Version)

            $lfxMPstring = GetFileContentInSourceFolder -fileName "ServiceManager.LinkingFramework.Configuration___50daaf82-06ce-cacb-8cf5-3950aebae0b0.xml" -subFolderName MPXml
            $lfxMPxml = New-Object xml
            $lfxMPxml.LoadXml($lfxMPstring)

            $ExchangeConnectorsData = $lfxMPxml.SelectNodes("/ManagementPack/Monitoring/Rules/Rule[WriteActions/WriteAction/Subscription/WindowsWorkflowConfiguration/WorkflowTypeName='Microsoft.SystemCenter.ExchangeConnector.ProcessEmailsWorkflow']")
            $ExchangeConnectors.SetAttribute("Count_Total", $ExchangeConnectorsData.Count)
            $ExchangeConnectorsEnabledCount = ($ExchangeConnectorsData | ? {$_.Enabled -eq $true} | Measure).Count
            $ExchangeConnectors.SetAttribute("Count_Enabled", $ExchangeConnectorsEnabledCount)

            $PotentialExchangeOnlineConnectorsData = $lfxMPxml.SelectNodes("/ManagementPack/Monitoring/Rules/Rule[
              @Enabled='true' and
              WriteActions/WriteAction/Subscription/WindowsWorkflowConfiguration/WorkflowTypeName=
                'Microsoft.SystemCenter.ExchangeConnector.ProcessEmailsWorkflow' and
              WriteActions/WriteAction/Subscription/WindowsWorkflowConfiguration/WorkflowParameters[
                  WorkflowParameter[@Name='ClientID' and @Type='string'] and
                  WorkflowParameter[@Name='TenantID' and @Type='string']
              ]
            ]")
            $guid = '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
            $ExchangeOnlineConnectorsData = foreach ($r in $PotentialExchangeOnlineConnectorsData) {
              $groups = $r.SelectNodes("WriteActions/WriteAction/Subscription/WindowsWorkflowConfiguration/WorkflowParameters")
              foreach ($g in $groups) {
                $client = $g.SelectSingleNode("WorkflowParameter[@Name='ClientID'  and @Type='string']")
                $tenant = $g.SelectSingleNode("WorkflowParameter[@Name='TenantID'  and @Type='string']")
                if ($client -and $tenant -and
                    $client.InnerText -match $guid -and
                    $tenant.InnerText -match $guid) { $r; break }
              }
            }
            $ExchangeOnlineConnectorsData_Count = ($ExchangeOnlineConnectorsData | measure).Count

            $ExchangeConnectors.SetAttribute("Count_Enabled_ExchOnline", $ExchangeOnlineConnectorsData_Count)
            $ExchangeConnectors.SetAttribute("Count_Enabled_ExchOnPremise", $ExchangeConnectorsEnabledCount-$ExchangeOnlineConnectorsData_Count)
        }
        #endregion
    }
}
