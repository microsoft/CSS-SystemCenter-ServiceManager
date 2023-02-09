function Check_DWData_IsUpTodate(){
#Check if data in DW is up-to-date
$NewestDataInSM = ConvertFrom-Csv (GetSanitizedCsv (GetFileContentInSourceFolder SQL_FromSMDB_WorkItemsCount.csv))
$NewestDataInDw = ConvertFrom-Csv (GetSanitizedCsv (GetFileContentInSourceFolder SQL_NewestWorkItemsInDW.csv)) 

$NewestIRDateInSM = ParseSqlDate ($NewestDataInSM[0].Newest)
$NewestSRDateInSM = ParseSqlDate ($NewestDataInSM[2].Newest)
$NewestCRDateInSM = ParseSqlDate ($NewestDataInSM[4].Newest)

$NewestIRDateInDWRep = ParseSqlDate ($NewestDataInDw[0].'Created at')
$NewestSRDateInDWRep = ParseSqlDate ($NewestDataInDw[3].'Created at')
$NewestCRDateInDWRep = ParseSqlDate ($NewestDataInDw[6].'Created at')

$NewestIRDateInDWDM = ParseSqlDate ($NewestDataInDw[1].'Created at')
$NewestSRDateInDWDM = ParseSqlDate ($NewestDataInDw[4].'Created at')
$NewestCRDateInDWDM = ParseSqlDate ($NewestDataInDw[7].'Created at')

$TransformCommonIssue = $false
$LoadCommonIssue = $false

$MinutesBetweenSmAndDWRep = [int]::MaxValue
$MinutesBetweenSmAndDWDM = [int]::MaxValue

$allowMinutesDelayForTransformCommon = 30*2  # Used twice the default 30 minutes. todo: Can be set later by reading from get-swdwjobschedule.csv if the default schedule has been changed.
$allowMinutesDelayForLoadCommon = 60*2  # Used twice the default 60 minutes. todo Can be set later by reading from get-swdwjobschedule.csv if the default schedule has been changed.

    $dataRow = GetEmptyResultRow
    $dataRow.RuleName="DW data is up-to-date"
    $dataRow.RuleDesc=@"
The Load.Common job brings data into DWDataMart every 60 minutes. We are checking here if data is delayed (allowing twice the delay = 120 minutes) by comparing dates between $(CollectorLink SQL_FromSMDB_WorkItemsCount.csv SMDB) and $(CollectorLink SQL_NewestWorkItemsInDW.csv DWDataMart) to verify if Load.Common is working fine.
<br/><br/>We also compare between $(CollectorLink SQL_FromSMDB_WorkItemsCount.csv SMDB) and $(CollectorLink SQL_NewestWorkItemsInDW.csv DWRepository) to check the Transform.Common job by allowing a 60 minutes delay.
<br/><br/>We do these comparisons separately for Incident, Service Request and Changes Requests.
"@
    $dataRow.SAPCategories= "*etl*" , "*Mpsync*"
    $dataRow.ProblemSeverity=[ProblemSeverity]::Warning
    
    $dataRow.RuleResult=[string]::Empty

    $minutesDiff=(Abs $NewestIRDateInDWDM.Subtract($NewestIRDateInSM).TotalMinutes)
    if ( $minutesDiff -gt $allowMinutesDelayForLoadCommon ) {                                                                                                                                                                                  
        $dataRow.RuleResult += "<li>IRs are delayed for more than $allowMinutesDelayForLoadCommon minutes by Load.Common: $(  Get-UserFriendlyTimeSpane ([timespan]::FromMinutes($minutesDiff)) )</li>"
    }
    $minutesDiff=(Abs $NewestSRDateInDWDM.Subtract($NewestSRDateInSM).TotalMinutes)
    if ( $minutesDiff -gt $allowMinutesDelayForLoadCommon ) {
        $dataRow.RuleResult += "<li>SRs are delayed for more than $allowMinutesDelayForLoadCommon minutes by Load.Common: $(  Get-UserFriendlyTimeSpane ([timespan]::FromMinutes($minutesDiff)) )</li>"
    }
    $minutesDiff=(Abs $NewestCRDateInDWDM.Subtract($NewestCRDateInSM).TotalMinutes)
    if ( $minutesDiff -gt $allowMinutesDelayForLoadCommon ) {
        $dataRow.RuleResult += "<li>CRs are delayed for more than $allowMinutesDelayForLoadCommon minutes by Load.Common: $(  Get-UserFriendlyTimeSpane ([timespan]::FromMinutes($minutesDiff)) )</li>"
    }
    #----------------------------------------------------------------------------------------------------
    $dataRow.RuleResult += "<br/>"
    #----------------------------------------------------------------------------------------------------
    $minutesDiff=(Abs $NewestIRDateInDWRep.Subtract($NewestIRDateInSM).TotalMinutes)
    if ( $minutesDiff -gt $allowMinutesDelayForTransformCommon ) {
        $dataRow.RuleResult += "<li>IRs are delayed for more than $allowMinutesDelayForTransformCommon minutes by Transform.Common: $(  Get-UserFriendlyTimeSpane ([timespan]::FromMinutes($minutesDiff)) )</li>"
    }
    $minutesDiff=(Abs $NewestSRDateInDWRep.Subtract($NewestSRDateInSM).TotalMinutes)
    if ( $minutesDiff -gt $allowMinutesDelayForTransformCommon ) {
        $dataRow.RuleResult += "<li>SRs are delayed for more than $allowMinutesDelayForTransformCommon minutes by Transform.Common: $(  Get-UserFriendlyTimeSpane ([timespan]::FromMinutes($minutesDiff)) )</li>"
    }
    $minutesDiff=(Abs $NewestCRDateInDWRep.Subtract($NewestCRDateInSM).TotalMinutes)
    if ( $minutesDiff -gt $allowMinutesDelayForTransformCommon ) {
        $dataRow.RuleResult += "<li>CRs are delayed for more than $allowMinutesDelayForTransformCommon minutes by Transform.Common: $(  Get-UserFriendlyTimeSpane ([timespan]::FromMinutes($minutesDiff)) )</li>"
    }
    #----------------------------------------------------------------------------------------------------
    if ( $dataRow.RuleResult -eq [string]::Empty ) { 
        $dataRow.RuleResult="All look fine."
        $Result_OKs += $dataRow 
    }
    else { 
        $dataRow.RuleResult += "<br/>For the root cause, check these files: $(CollectorLink Get-SCDWJobSchedule.txt Get-SCDWJobSchedule), $(CollectorLink Get-SCDWJob.txt Get-SCDWJob), $(CollectorLink Get-SCDWJob_NumberOfBatches_5.txt 'Get-SCDWJob -NumberOfBatches 5'), $(CollectorLink SQL_InfraBatch.csv 'infra.Batch'), $(CollectorLink SQL_InfraWorkItem.csv 'infra.WorkItem'), $(CollectorLink SQL_LockDetails.csv 'LockDetails') and $(CollectorLink OperationsManager.evtx 'OM event log')."
        
        $dataRow.RuleResult += "</br></br>As the most stable solution, you may consider to restore all DW databases back to a date that was before the problem had started.<br/>However, in order to prevent data loss in the DW, the backup date should NOT be earlier than the 'Data Retention Days' of Work Items in the SM database"
        $smDbDataRetentionInfo = ConvertFrom-Csv ( GetSanitizedCsv (GetFileContentInSourceFolder SQL_FromSMDB_DataRetention.csv ) )
        if ($smDbDataRetentionInfo -and $smDbDataRetentionInfo.Count -gt 0) {
	        $smDbDataRetentionDays = ($smDbDataRetentionInfo | Select-Object -First 1).Days
	        [timespan]$ts = [timespan]::new($smDbDataRetentionDays,0,0,0,0)
	        $smDbDataRetentionDate = (Get-Date).Subtract($ts)	
	        $dataRow.RuleResult += ", which corresponds to $smDbDataRetentionDate."	
        }
        else {
	        $dataRow.RuleResult += "."
        } 
        $dataRow.RuleResult += " Please consult your SQL Server admin team for available backups."

        $dataRow.RuleResult += "</br></br>$(IgnoreRuleIfText) DW is used for MIM/FIM because MIM does not use IR, SR, CR, they have their own custom work item types."
        $Result_Problems += $dataRow 
    }
}