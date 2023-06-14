function Collect_SCSMFilesInfoFromSeveralPlaces() {

    $subFolders = 'AppData\Local\Microsoft\System Center Service Manager 2010'

    Collect_FilesInfoFromDirectory -pStartingPath ( [System.IO.Path]::Combine( $env:USERPROFILE, $subFolders) ) -outputFileName "SCSM_Files_InProfile_CurrentUser.csv"
    Collect_FilesInfoFromDirectory -pStartingPath ( [System.IO.Path]::Combine( $env:windir, 'System32\Config\SystemProfile', $subFolders) ) -outputFileName "SCSM_Files_InProfile_LocalSystem.csv"
    Collect_FilesInfoFromDirectory -pStartingPath ( [System.IO.Path]::Combine( $env:windir, 'ServiceProfiles\LocalService',  $subFolders) ) -outputFileName "SCSM_Files_InProfile_LocalService.csv"
    Collect_FilesInfoFromDirectory -pStartingPath ( [System.IO.Path]::Combine( $env:windir, 'ServiceProfiles\NetworkService',$subFolders) ) -outputFileName "SCSM_Files_InProfile_NetworkService.csv"

    $serviceDomainUserName = (gwmi win32_service -Filter " Name = 'OMSDK' " | Select-Object -Property StartName).StartName
    $omsdkDomainUserName = $serviceDomainUserName
    if ($serviceDomainUserName -and $serviceDomainUserName -ne 'LocalSystem' -and $serviceDomainUserName -ne 'NT AUTHORITY\LocalService' -and $serviceDomainUserName -ne 'NT AUTHORITY\NetworkService') {  
        
        if ( $serviceDomainUserName -eq ( (GetCurrentUser).Name ) ) {
            CopyFileWithNewNameInTargetFolder -sourceFileName "SCSM_Files_InProfile_CurrentUser.csv" -targetFileName "SCSM_Files_InProfile_OMSDKServiceAccount.csv"
        }
        else 
        {
            $parts = $serviceDomainUserName.Split('\')
            if ($parts.Count -ne 2) {

                $parts = $serviceDomainUserName.Split('@')
                if ($parts.Count -ne 2) {
                    return $null
                }

                [string]$convertedDomainUserName = ConvertUpnToDomainUsername -upn $serviceDomainUserName
                $parts = $convertedDomainUserName.Split('\')
            }
            if ($parts.Count -ne 2) {
                return $null
            }
            $serviceDomainName = $parts[0].Trim()
            $serviceUserName = $parts[1].Trim()
            $ServiceSID = (gwmi win32_useraccount -Filter " Domain='$serviceDomainName' and Name='$serviceUserName'").SID
            $serviceLocalPath = (gwmi Win32_UserProfile -Filter " SID = '$ServiceSID' ").LocalPath

            Collect_FilesInfoFromDirectory -pStartingPath ( [System.IO.Path]::Combine( $serviceLocalPath, $subFolders) ) -outputFileName "SCSM_Files_InProfile_OMSDKServiceAccount.csv"
        }
    }
    
    $serviceDomainUserName = (gwmi win32_service -Filter " Name = 'OMCFG' " | Select-Object -Property StartName).StartName
    if ($serviceDomainUserName -and $serviceDomainUserName -ne 'LocalSystem' -and $serviceDomainUserName -ne 'NT AUTHORITY\LocalService' -and $serviceDomainUserName -ne 'NT AUTHORITY\NetworkService') {  

        if ( $serviceDomainUserName -eq ( (GetCurrentUser).Name ) ) {
            CopyFileWithNewNameInTargetFolder -sourceFileName "SCSM_Files_InProfile_CurrentUser.csv" -targetFileName "SCSM_Files_InProfile_OMSDKServiceAccount.csv"
        }
        elseif ( $serviceDomainUserName -eq $omsdkDomainUserName) {
            CopyFileWithNewNameInTargetFolder -sourceFileName "SCSM_Files_InProfile_OMSDKServiceAccount.csv" -targetFileName "SCSM_Files_InProfile_OMCFGServiceAccount.csv"
        }
        else
        {
            $parts = $serviceDomainUserName.Split('\')
            if ($parts.Count -ne 2) {

                $parts = $serviceDomainUserName.Split('@')
                if ($parts.Count -ne 2) {
                    return $null
                }

                [string]$convertedDomainUserName = ConvertUpnToDomainUsername -upn $serviceDomainUserName
                $parts = $convertedDomainUserName.Split('\')
            }
            if ($parts.Count -ne 2) {
                return $null
            }
            $serviceDomainName = $parts[0].Trim()
            $serviceUserName = $parts[1].Trim()
            $ServiceSID = (gwmi win32_useraccount -Filter " Domain='$serviceDomainName' and Name='$serviceUserName'").SID
            $serviceLocalPath = (gwmi Win32_UserProfile -Filter " SID = '$ServiceSID' ").LocalPath

            Collect_FilesInfoFromDirectory -pStartingPath ( [System.IO.Path]::Combine( $serviceLocalPath, $subFolders) ) -outputFileName "SCSM_Files_InProfile_OMCFGServiceAccount.csv"
        }
    }
}

function Collect_FilesInfoFromDirectory($pStartingPath, $outputFileName) {
  AppendOutputToFileInTargetFolder ( GetFilesInfoFromDirectory $pStartingPath ) $outputFileName
}
