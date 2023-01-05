function main() {

#region Setting the Script Scope vars
    [string]$scriptFilePath = ""
    [bool]$debugmode = $false

    if ( (dir function:).Name -contains "GetToolVersion" ) { 
        $scriptFilePath = $MyInvocation.PSCommandPath 
    }
    else {
        # this means, we are starting debug in main.ps1 (typically in elevated ISE) instead of a single big ps1 and therefore ALL functions are NOT loaded yet.

        #We want to Debug/Develop in a location other than the Source Code. That's not to clutter within the development folder.
        $localDebugFolder = (Join-Path (Split-Path $PSScriptRoot -Parent) -ChildPath LocalDebug) 
        if (!(Test-Path $localDebugFolder -PathType Container)) {
            New-Item -ItemType Directory -Force -Path $localDebugFolder | Out-Null
        }
        $scriptFilePath = Join-Path $localDebugFolder (Split-Path $PSCommandPath -Leaf)
        Copy-Item -Path $PSCommandPath -Destination $scriptFilePath -Force

        # We need to "load" all other function definitions in order be called        
        Get-ChildItem -Path $PSScriptRoot -Filter *.ps1 -Recurse -Exclude main.ps1 | % { . $_.FullName }
    }
#endregion

#region resetting the PS environment
    Remove-Variable * -ErrorAction SilentlyContinue -Exclude PSDefaultParameterValues, debugmode, scriptFilePath, toolVersion
    Remove-Module *; 
    $Error.Clear(); 
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

main;