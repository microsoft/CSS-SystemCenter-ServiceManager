param(
    [string]$Configuration = "Debug" # or Release
)

Set-Location $PSScriptRoot 

$folderName_Bundle =     "Bundle"  
$folderName_MPSource =   "MPSource"  
$folderName_MPResource = "MPResource"  
$folderName_Output   =   "Output"    
$folderName_Misc     =   "Misc"      
if ( (Split-Path -Path (Get-Location) -Leaf) -eq $folderName_Bundle ) {
    cd ".."  # Set folder to root
}

$slnName = "SCSM.Support.Tools.sln"
#region check for NOT having System.Net.Http v4.2.0.0 in any csproj as the compiled dll may crash the console at customers where this version does not exists but v4.0.0. exists
    $slnContent = [System.IO.File]::ReadAllLines( (Resolve-Path "$folderName_MPResource\$slnName") )

    # get lines starting like Project("{FAE04EC0-301F-11D3-BF4B-00C04F79EFBC}") = "SCSM.Support.Tools.HealthStatus.Presentation", "SCSM.Support.Tools.HealthStatus.Presentation\SCSM.Support.Tools.HealthStatus.Presentation.csproj", "{1D3CDF91-3DF3-46E5-ACC7-E56EFB7E5828}"
    # and get the path to .csproj
    $csprojPaths = @()
    [string]$slnLine = ""
    foreach($slnLine in $slnContent)
    {
        if ( $slnLine.StartsWith('Project("{') -and $slnLine.Contains('.csproj"') ) {
            $csprojPaths += $slnLine.Split('=')[1].Split(',')[1].Replace('"','').Trim()
        }
    }

    foreach($csprojPath in $csprojPaths)
    {
        [string]$csprojContent = [System.IO.File]::ReadAllText( (Resolve-Path "$folderName_MPResource\$csprojPath") )
        if ($csprojContent.IndexOf('System.Net.Http') -lt 0) {
            continue # if no "System.Net.Http" found just continue to next csproj
        }

        [xml]$csprojXml = [xml]::new()
        $csprojXml.LoadXml($csprojContent)

        # ensure it is like below
        <#
        <Reference Include="System.Net.Http, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a, processorArchitecture=MSIL">
            <HintPath>C:\Windows\Microsoft.NET\assembly\GAC_MSIL\System.Net.Http\v4.0_4.0.0.0__b03f5f7f11d50a3a\System.Net.Http.dll</HintPath>
        </Reference>
        #>
        foreach($elmItemGroup in $csprojXml.DocumentElement.ItemGroup) {
            foreach($elmReference in $elmItemGroup.Reference) {
                if ( $elmReference.Include.Trim().StartsWith("System.Net.Http,") -or $elmReference.Include.Trim() -eq "System.Net.Http" ) {
                    if ( $elmReference.HintPath -and $elmReference.HintPath.EndsWith("Microsoft.NET\assembly\GAC_MSIL\System.Net.Http\v4.0_4.0.0.0__b03f5f7f11d50a3a\System.Net.Http.dll") ) {
                        #good, that is what we want, continue...
                    }
                    else {
                        Write-Error "System.Net.Http has been found as a Reference in $csprojPath but no HintPath found that points to the GAC for v4.0.0.0. This eventually will compile with v4.2.0.0 but may crash the console at customers with older version (but still .NET FW 4.7.2)"
                        return #actually the above Write-Error will cause ADO to break but good to have a return                    
                    }
                }
            }
        }
    }
#endregion

$VSProjects = @()
$VSProjects += $slnName
#$VSProjects += "SCSM.Support.Tools.Library\SCSM.Support.Tools.Library.csproj"
#$VSProjects += "SCSM.Support.Tools.Main.Presentation\SCSM.Support.Tools.Main.Presentation.csproj"
#$VSProjects += "SCSM.Support.Tools.HealthStatus.Presentation\SCSM.Support.Tools.HealthStatus.Presentation.csproj"

foreach($VSProject in $VSProjects) {
    ."C:\Windows\Microsoft.NET\Framework64\v4.0.30319\MSBuild.exe" "$folderName_MPResource\$VSProject" -t:clean,rebuild -verbosity:diagnostic /p:Configuration=$Configuration    
}
 
# read-host " "
