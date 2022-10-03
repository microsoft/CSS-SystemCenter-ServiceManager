function Check_DateFormatOfExtractJobsSQLAccount() {
$linesIn_dbcc_useroptions = GetFileContentInSourceFolder ForExtractJob_dbcc_useroptions_FromDW_ToSMDB.txt 
 $isDateFormatCorrect = (GetLinesFromString ($linesIn_dbcc_useroptions)) -contains '"dateformat","mdy"' 
 $fileContainsAttention = $linesIn_dbcc_useroptions.contains('Attention!')

    $dataRow = GetEmptyResultRow
    $dataRow.RuleName="Date format of Extract Job's SQL Account"
    $dataRow.RuleDesc="The Extract Job (the one that does not start with 'DW_') reads data from SM DB every 5 minutes. There are many issues if the RunAs Account (in $(CollectorLink Get-SCSMRunAsAccount.txt)) that is connecting to SM DB (SQL info in $(CollectorLink SQL_DW_DataSources.csv)) has a dateformat other than 'mdy'. For example, in German installations it's usually 'dmy'. In this case, the 'Symptom' is: The Extract does not fail, but some data won't be picked up from the SM DB 'randomly'."
    $dataRow.RuleResult="Dateformat in SM DB for Extract Job's SQL Account is correct."
    $dataRow.SAPCategories = "dw*" 
    $dataRow.ProblemSeverity=[ProblemSeverity]::Warning

    if ( $isDateFormatCorrect -and (-not $fileContainsAttention) ) { $Result_OKs += $dataRow }
    elseif ( $isDateFormatCorrect -and $fileContainsAttention ) { 
        $dataRow.RuleResult = "The Collector did not run as Extract Job's RunAs Account. Check $(CollectorLink ForExtractJob_dbcc_useroptions_FromDW_ToSMDB.txt dbcc_useroptions) for details. <br/>$(IgnoreRuleIfText) the 'Symptom' has not happened, otherwise connect to SM DB with Extract's account and run 'dbcc useroptions', the 'dateformat' in the result must be 'mdy'."
        $dataRow.ProblemSeverity=[ProblemSeverity]::Warning
        $Result_Problems += $dataRow 
    }
    elseif ( (-not $isDateFormatCorrect) -and $fileContainsAttention ) { 
        $dataRow.RuleResult = "The Collector did not run as Extract Job's RunAs Account. Check $(CollectorLink ForExtractJob_dbcc_useroptions_FromDW_ToSMDB.txt dbcc_useroptions) for details. <br/>$(IgnoreRuleIfText) the 'Symptom' has not happened (bcz this can be false positive), otherwise connect to SM DB with Extract's account and run 'dbcc useroptions', the 'dateformat' in the result must be 'mdy'."
        $dataRow.ProblemSeverity=[ProblemSeverity]::Warning
        $Result_Problems += $dataRow 
    }

    elseif ( (-not $isDateFormatCorrect) -and (-not $fileContainsAttention) ) {        
        $dataRow.RuleResult = "The dateformat is not 'mdy' for Extract Job's RunAs Account. Check $(CollectorLink ForExtractJob_dbcc_useroptions_FromDW_ToSMDB.txt dbcc_useroptions). Most probably some data does NOT flow to the DW intermittently. This can be false positive, but better to change the Language of the Extract Job's SQL Account to 'English'."
        $dataRow.ProblemSeverity=[ProblemSeverity]::Critical
        $Result_Problems += $dataRow
    }
    else {
          $dataRow.ProblemSeverity=[ProblemSeverity]::Unclassified
          $Result_Problems += $dataRow
    }
}
