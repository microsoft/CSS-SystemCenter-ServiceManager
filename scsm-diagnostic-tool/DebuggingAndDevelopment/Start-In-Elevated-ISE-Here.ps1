# Debug/Develop in a location other than the tool directory stucture. That's not to clutter within the development folder.
# "LastBuild" must be an existing sibling folder of this script's folder !!!
# Note: LastBuild is included in  .gitignore
$testFolder = (Join-Path (Split-Path $PSScriptRoot -Parent) -ChildPath LastBuild) # 'C:\temp\tests'

# version needs to be fetched from there, "before" copying the starting script to $testFolder
$toolVersion = Get-Content -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath version.txt)

[string]$scriptFilePath = Join-Path $testFolder (Split-Path $PSCommandPath -Leaf)
Copy-Item -Path $PSCommandPath -Destination $scriptFilePath -Force

[bool]$script:debugmode = $false # set to $true to change behaviour such as skipping compression at the end, open up the Findings.html etc.

# "SourceCode" must be an existing sibling folder of this script's folder !!!
Get-ChildItem -Path (Join-Path (Split-Path $PSScriptRoot -Parent) -ChildPath SourceCode ) -Filter *.ps1 -Recurse | % { . $_.FullName }
main;
