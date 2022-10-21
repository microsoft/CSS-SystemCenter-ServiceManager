function Check_TimeDiffBetweenMSAndSQL() {
 #check time diff (for SM server roles)  #TODO

    $timeDiffInSecs = [int]::MaxValue
    $fileContainsError = $true

    [string]$tmp = GetFileContentInSourceFolder TimeDiff_BtwMS_AndSQL_viaWin32tm.txt
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
        $tmp = GetFirstLineThatStartsWith (GetFileContentInSourceFolder TimeDiff_BtwMS_AndSQL.txt) "TotalSeconds"  
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

    if ($fileContainsError) {

        $MS_Utc = [datetime]::MinValue
        $SQL_Utc = [datetime]::MinValue

        $MS_Utc_Str = (GetFileContentInSourceFolder Get-UtcDate.txt).Trim()
        if ( [datetime]::TryParseExact($MS_Utc_Str,"yyyy-MM-dd__HH:mm.ss.fff", $null, [System.Globalization.DateTimeStyles]::None, [ref] $MS_Utc) ) {
            $SQL_Utc_Csv = ConvertFrom-Csv (GetSanitizedCsv (GetFileContentInSourceFolder SQL_Date.csv))
            $SQL_Utc_Str = $SQL_Utc_Csv.UtcTime
            if ( [datetime]::TryParseExact($SQL_Utc_Str,"yyyy-MM-dd__HH:mm.ss.fff", $null, [System.Globalization.DateTimeStyles]::None, [ref] $SQL_Utc) ) {
                
                $fileContainsError = $false
                $timeDiffInSecs = $MS_Utc.Subtract($SQL_Utc).TotalSeconds
                [int]$timeDiffInSecs = [System.Math]::Abs($timeDiffInSecs)
            }
            else {  $fileContainsError = $true  }         
        }
        else {  $fileContainsError = $true  } 
    }

    $dataRow = GetEmptyResultRow
    $dataRow.RuleName="Time diff between MS and SQL"
    $dataRow.RuleDesc="The time diff between the machine and the SQL box should be less than 5 minutes (<= 300 secs). $(GetAnchorForExternal 'https://docs.microsoft.com/en-us/windows/security/threat-protection/security-policy-settings/maximum-tolerance-for-computer-clock-synchronization#best-practices' 'Best Practice') "
    $dataRow.RuleResult="Actual: "
    if (IsSourceScsmMgmtServer) { $dataRow.SAPCategories = "s*\other" }
    if (IsSourceScsmDwMgmtServer) { $dataRow.SAPCategories = "dw\other" } 
    $dataRow.ProblemSeverity=[ProblemSeverity]::Warning

    if ($fileContainsError) {
        $dataRow.RuleResult = "Time diff between MS and SQL couldn't be measured from these files: $(CollectorLink TimeDiff_BtwMS_AndSQL.txt), $(CollectorLink TimeDiff_BtwMS_AndSQL_viaWin32tm.txt), $(CollectorLink Get-UtcDate.txt), $(CollectorLink SQL_Date.csv). <br/>$(IgnoreRuleIfText) no symptoms are happening that seem to be caused by Kerberos issues."
        $Result_Problems += $dataRow
    }
    elseif ($timeDiffInSecs -le 300) { 
        $dataRow.RuleResult += "$timeDiffInSecs seconds."
        $Result_OKs += $dataRow 
    }
    else {        
        $dataRow.RuleResult += "$timeDiffInSecs seconds! Time diff between MS and SQL is greater than 5 minutes! (Measured in these files: $(CollectorLink TimeDiff_BtwMS_AndSQL.txt), $(CollectorLink TimeDiff_BtwMS_AndSQL_viaWin32tm.txt), $(CollectorLink Get-UtcDate.txt), $(CollectorLink SQL_Date.csv)). <br/>$(IgnoreRuleIfText) no symptoms are happening that seem to be caused by Kerberos issues."
        $Result_Problems += $dataRow
    }
}