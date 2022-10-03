#Debug/Develop in a location other than the tool directory stucture. That's not to mess up within the development folder
$testFolder = 'C:\temp\tests'

# "SourceCode" must be an existing sibling folder of this script's folder !!!
# version needs to be fetched here, "before" copying the starting script to $testFolder
$toolVersion = Get-Content -Path (Join-Path -Path (Join-Path (Split-Path $PSScriptRoot -Parent) -ChildPath SourceCode) -ChildPath version.txt)

[string]$scriptFilePath = Join-Path $testFolder (Split-Path $PSCommandPath -Leaf)
Copy-Item -Path $PSCommandPath -Destination $scriptFilePath -Force

[bool]$script:debugmode = $false # set to $true to change behaviour such as skipping compression at the end, open up the Findings.html etc.

# "SourceCode" must be an existing sibling folder of this script's folder !!!
Get-ChildItem -Path (Join-Path (Split-Path $PSScriptRoot -Parent) -ChildPath SourceCode ) -Filter *.ps1 -Recurse | % { . $_.FullName }
main;
