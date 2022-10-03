function Check_TimeDiffWithDC() {

    $timeDiffInSecs = [int]::MaxValue
    $fileContainsError = $true

    [string]$tmp = GetFileContentInSourceFolder TimeDiff_BtwDC_viaWin32tm.txt
    $fileContainsError = $tmp.contains(': 0x')
    if (-not $fileContainsError) {
        $posOfTimeDiff = $tmp.IndexOf(', -'); 
        if ($posOfTimeDiff -eq -1) { $posOfTimeDiff = $tmp.IndexOf(', +') }

        if ($posOfTimeDiff -eq -1) { $fileContainsError = $true }
        else {
            $posOfTimeDiff2 = $tmp.IndexOf('.',$posOfTimeDiff+2)
            if ($posOfTimeDiff2 -eq -1) { $fileContainsError = $true }
            else {
                $timeDiffInSecs_Str = $tmp.Substring( $posOfTimeDiff+2, $posOfTimeDiff2 - ($posOfTimeDiff+2) )
                
                if ( [int]::TryParse($timeDiffInSecs_Str, [ref] $timeDiffInSecs) ) {
                    $fileContainsError = $false
                    [int]$timeDiffInSecs = [System.Math]::Abs($timeDiffInSecs)
                }
                else {                    
                    $timeDiffInSecs = [int]::MaxValue
                }
            }
        }
    }

    if ($fileContainsError) {
        $tmp = GetFirstLineThatStartsWith (GetFileContentInSourceFolder TimeDiff_BtwDC.txt) "TotalSeconds"  
        if ( $tmp -eq $null ) {
            $timeDiffInSecs = [int]::MaxValue                    
        }
        else {
            $sourceNumberFormat = (GetFileContentInSourceFolder CurrentCulture.NumberFormat.csv) | ConvertFrom-Csv
            $posOfTimeDiff = $tmp.IndexOf(':')
            if ($posOfTimeDiff -eq -1) { $fileContainsError = $true }
            else {
                $posOfTimeDiff2 = $tmp.IndexOf( $sourceNumberFormat.NumberDecimalSeparator ,$posOfTimeDiff+1 )
                if ($posOfTimeDiff2 -eq -1) { $fileContainsError = $true }
                else {
                    $timeDiffInSecs_Str = $tmp.Substring( $posOfTimeDiff+1, $posOfTimeDiff2 - ($posOfTimeDiff+1) )
                
                    if ( [int]::TryParse($timeDiffInSecs_Str, [ref] $timeDiffInSecs) ) {
                        $fileContainsError = $false
                        [int]$timeDiffInSecs = [System.Math]::Abs($timeDiffInSecs)
                    }
                    else {
                        $timeDiffInSecs = [int]::MaxValue
                    }
                }
            }            
        }
    }

    $dataRow = GetEmptyResultRow
    $dataRow.RuleName="Time diff with DC"
    $dataRow.RuleDesc="The time diff between the machine and the DC should be less than 5 minutes (<= 300 secs). $(GetAnchorForExternal 'https://docs.microsoft.com/en-us/windows/security/threat-protection/security-policy-settings/maximum-tolerance-for-computer-clock-synchronization#best-practices' 'Best Practice') "
    $dataRow.RuleResult="Actual: "
    if (IsSourceScsmMgmtServer) { $dataRow.SAPCategories = "s*\other"}
    if (IsSourceScsmDwMgmtServer) { $dataRow.SAPCategories = "dw\other"} 
    
    $dataRow.ProblemSeverity=[ProblemSeverity]::Warning

    if ($fileContainsError) {
        $dataRow.RuleResult = "Time diff between DC couldn't be measured in one of these file: $(CollectorLink TimeDiff_BtwDC.txt), $(CollectorLink TimeDiff_BtwDC_viaWin32tm.txt). <br/>$(IgnoreRuleIfText) no symptoms are happening that seem to be caused by Kerberos issues."
        $Result_Problems += $dataRow
    }
    elseif ($timeDiffInSecs -le 300) { 
        $dataRow.RuleResult += "$timeDiffInSecs seconds."
        $Result_OKs += $dataRow 
    }
    else {        
        $dataRow.RuleResult += "$timeDiffInSecs seconds! Time diff between DC is greater than 5 minutes! (Measured in these files: $(CollectorLink TimeDiff_BtwDC.txt), $(CollectorLink TimeDiff_BtwDC_viaWin32tm.txt)). <br/>$(IgnoreRuleIfText) no symptoms are happening that seem to be caused by Kerberos issues."
        $Result_Problems += $dataRow
    }
}

