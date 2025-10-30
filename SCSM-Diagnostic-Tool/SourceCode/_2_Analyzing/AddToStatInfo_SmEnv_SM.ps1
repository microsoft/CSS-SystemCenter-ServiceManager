function AddToStatInfo_SmEnv_SM() {
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
    
}
