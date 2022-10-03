function main() {
#region Setting the Script Scope vars (if not set already by debugger starting script)
if ($MyInvocation.PSCommandPath -eq $PSCommandPath) { #script was NOT started by debugger starting script
    [string]$scriptFilePath = $MyInvocation.PSCommandPath 
    [bool]$debugmode = $false
    [string]$toolVersion = GetToolVersion
}
#endregion

#region resetting the PS environment
    Remove-Variable * -ErrorAction SilentlyContinue -Exclude PSDefaultParameterValues, debugmode, scriptFilePath, toolVersion
    Remove-Module *; 
    $error.Clear(); 
    Get-job | Remove-Job -Force
    $host.privatedata.ErrorForegroundColor ="DarkGray"  # For accessibility
    $global:ProgressPreference = 'SilentlyContinue'
#endregion 

    Set-PSDebug -Strict # from now on, all variables must be explicitly declared before they are used   

    Set-Location (Split-Path $scriptFilePath)  # setting current directory here once. Should not be changed anywhere else. 

    if (Initialize) {

        #region Collect
        $collectorResultingZipFile_FullPath = Collect
        #endregion

        #region Analyze
        $analyzerResultingZipFile_FullPath = Analyze $collectorResultingZipFile_FullPath
        #endregion

        Finish $analyzerResultingZipFile_FullPath
    }
    else {    
        Read-Host " "
    }
}
