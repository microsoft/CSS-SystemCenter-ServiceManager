function Check_GoodDWDbBackupAvailability() {

    $warningDays = 7

    $dataRow = GetEmptyResultRow
    $dataRow.RuleName="DW DB Backups"
    $dataRow.RuleDesc="In order to recover a corrupted DW, recent $(CollectorLink SQL_BackupInfo.csv 'Backups of all DW databases') must exist. 
    <br/><u>More importantly</u>, the backup date should NOT be <u>earlier</u> than the $(CollectorLink SQL_FromSMDB_DataRetention.csv 'Data Retention Days') of Work Items in the SM database. 
    In that case, it's highly possible to recover the DW if it gets corrupted. Otherwise, data loss can happen in the DW and/or a re-installation of the DW can be necessary.
    <br/>This rule warns if there are less than $warningDays days before the backups will be useless."

    $dataRow.SAPCategories= "*dw*"
    $dataRow.ProblemSeverity=[ProblemSeverity]::Error
    $dataRow.RuleResult=""

    $showWarning = $false
    $showError = $false
    
    $smDbDataRetentionInfo = ConvertFrom-Csv ( GetSanitizedCsv (GetFileContentInSourceFolder SQL_FromSMDB_DataRetention.csv ) )
    if (-not $smDbDataRetentionInfo -or $smDbDataRetentionInfo.Count -eq 0) {
        $dataRow.RuleResult += " ! Data Retention info could not be retrieved from SM DB ($($SMDBInfo.SQLInstance_SMDB) / $($SMDBInfo.SQLDatabase_SMDB)) !<br/>"
        $showError = $true
    }
    else {        
        $smDbDataRetentionDays = ($smDbDataRetentionInfo | Select-Object -First 1).Days
        [timespan]$ts = [timespan]::new($smDbDataRetentionDays,0,0,0,0)
        $smDbDataRetentionDate = (Get-Date).Subtract($ts)
        $dataRow.RuleResult += "Data Retention in SM DB is set to $smDbDataRetentionDays days which corresponds to $smDbDataRetentionDate.<br/>"        
    }    
    
    $dwDBsBackupInfo = ConvertFrom-Csv ( GetSanitizedCsv (GetFileContentInSourceFolder SQL_BackupInfo.csv ) )
    if (-not $dwDBsBackupInfo) {
        $dataRow.RuleResult += "<br/> ! DW DB Backup Info could NOT be retrieved from $MainSQL_InstanceName !<br/>"
        $showError = $true
    }
    else {
        $dataRow.RuleResult += "<br/>DW DB Backups found:<br/>"
        $dataRow.RuleResult += "<style>table, th, td {border: 1px solid black;  border-collapse: collapse;}</style>"
        $dataRow.RuleResult += "<table>"
        $dataRow.RuleResult += "
        <tr>
        <td><b>DB Name</b></td>
        <td><b>Most recent<br/>backup date</b></td>
        <td><b>Remaining days before<br/>backup becomes useless</b></td>
        <td><b>Result</b></td>
        </tr>"

        $MainSQL_DbName, $DW_Rep_SQL_DbName, $DW_DM_SQL_DbName, $DW_CM_SQL_DbName, $DW_OM_SQL_DbName | % {

            $dwDbName = $_
            if ($dwDbName.Trim() -eq "") { continue } #that can happen if no CMDWDMart and OMDWDMart exists

            $dataRow.RuleResult += "<tr><td>$dwDbName</td>"

            $dwDBBackupInfo = $dwDBsBackupInfo | ? { $_.database_name -eq $dwDbName}
            if (-not $dwDBBackupInfo) {
                $dataRow.RuleResult += "<td>(none)</td><td>(n/a)</td><td>! NO backup !</td>"
                $showError = $true
            } 
            else {                
                [datetime]$lastBackupDate = $dwDBBackupInfo.LastBackupDate
                $dataRow.RuleResult += "<td>$lastBackupDate</td>"

                $remaingDays = $lastBackupDate.Subtract($smDbDataRetentionDate).Days
                $dataRow.RuleResult += "<td>$remaingDays</td>"

                $dataRow.RuleResult += "<td>"
                if ($remaingDays -gt $warningDays) {
                    $dataRow.RuleResult += "Good"
                }
                elseif ($remaingDays -lt 0) {
                    $dataRow.RuleResult += "! Useless !"
                    $showError = $true
                }
                 else{
                    $dataRow.RuleResult += "! Good, but will become useless soon !"
                    $showWarning = $true
                }
                $dataRow.RuleResult += "</td>"
            }
            $dataRow.RuleResult += "</tr>"
        }
        $dataRow.RuleResult += "</table>"
    }       

    if ( -not $showError -and -not $showWarning ) { 
        $Result_OKs += $dataRow 
    }
    elseif ( -not $showError -and $showWarning ) { 
        $dataRow.ProblemSeverity=[ProblemSeverity]::Warning
        $Result_Problems += $dataRow }
    else {        
        $dataRow.ProblemSeverity=[ProblemSeverity]::Error
        $Result_Problems += $dataRow
    }

    if ( $showError -or $showWarning ) {
        $dataRow.RuleResult += "<br/><br/>$(IgnoreRuleIfText) you have valid backups"
        if ($smDbDataRetentionInfo) {
            $dataRow.RuleResult += " that were taken after $smDbDataRetentionDate."
        }
        else {
            $dataRow.RuleResult += "."
        }
    }
#endregion
}