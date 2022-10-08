function Check_GroomingAndPurging() {
 $dataRow = GetEmptyResultRow
    $dataRow.RuleName="Grooming and Purging"
    $dataRow.RuleDesc=@"
Data needs to be groomed and purged periodically. The table InternalJobHistory should have rows with StatusCode = 1.<br/>
In addition, grooming rules should run in their expected intervals. If not, WFs can lag and Consoles can face slowness. Please correlate with rule 'ECL row count' and overall SQL performance.
<br/>All info in $(CollectorLink SQL_InternalJobHistory.csv)
"@
    $dataRow.SAPCategories = "wf*"   
    $dataRow.ProblemSeverity=[ProblemSeverity]::Warning

    $anyIssuesFoundInGroomOrPurge = $false
    $dataRow.RuleResult="Commands which have problems in $(CollectorLink SQL_InternalJobHistory.csv):"

    $linesIn_SQL_InternalJobHistory = ConvertFrom-Csv (GetSanitizedCsv ( GetFileContentInSourceFolder SQL_InternalJobHistory.csv) ) 
    $isTheFirstRowInGroup = $true
    $groupNo = 1
    foreach ($groomRow in $linesIn_SQL_InternalJobHistory) {
        if ($groomRow.StatusCode -eq "StatusCode") {
            $isTheFirstRowInGroup = $true
            $groupNo++
            continue;
        }
        if ($isTheFirstRowInGroup) {
            $isTheFirstRowInGroup = $false

            if ($groomRow.StatusCode -ne "1") {
                $anyIssuesFoundInGroomOrPurge = $true
                $dataRow.RuleResult += "<li>$($groomRow.Command)</li>"
            }
            else {
                $groomIntervalInMinutes = 15
                if ($groupNo -ge 4) {
                    $groomIntervalInMinutes = 60*24 #daily
                } 
                [datetime]$lastGroomDateUtc = ParseSqlDate $groomRow.TimeFinished
                if ( $inputDateTimeUtc.Subtract($lastGroomDateUtc).TotalMinutes -gt ($groomIntervalInMinutes*2) ) { # we tolerate twice of the $groomIntervalInMinutes
                    $anyIssuesFoundInGroomOrPurge = $true
                    $dataRow.RuleResult += "<li>$($groomRow.Command)</li>"
                }                
            }
        }        
    }

    if (-not $anyIssuesFoundInGroomOrPurge) {
        $dataRow.RuleResult="Grooming and Purging are working fine."
        $Result_OKs += $dataRow 
    }
    else {
        $dataRow.RuleResult += "<br/><br/>$(IgnoreRuleIfText) there are no performance issues, however it is strongly suggest to fix this issue."
        $Result_Problems += $dataRow
    }
}