﻿function Check_DelayedWorkflows_2019UR2Only_2016UR10Only() {

    $dataRow = GetEmptyResultRow
    $dataRow.RuleName="Delayed Workflows (2019 UR2 only)"
    if ($SCSM_Version -eq '7.5.7487.231') {      
        $dataRow.RuleName = "Delayed Workflows (2016 UR10 only)"
    }

    $patchTitle = "2019 UR2"
    $patchUrl = 'https://support.microsoft.com/en-us/topic/update-rollup-2-for-system-center-service-manager-2019-kb4558753-9211f013-33a5-fee4-ea18-d4c35befa831'
    $patchUrlTitle = 'UR2 article'
    if ($SCSM_Version -eq '7.5.7487.231') {   
        $patchTitle = "2016 UR10"
        $patchUrl = 'https://support.microsoft.com/en-us/topic/update-rollup-10-for-system-center-2016-service-manager-9ffb4362-551d-8a8d-3746-a25d3f379f74'
        $patchUrlTitle = 'UR10 article'
    }
    $dataRow.RuleDesc=@"
Due to bug #829977, workflows are delayed because the MonitoringHost.exe process is intermittently crashing. Event ID 1026 is also logged in the event viewer together with UnauthorizedAccessException.
This only happens with $patchTitle where a stored procedure is causing this issue. A SQL script has been released to fix this stored procedure in the $(GetAnchorForExternal "$patchUrl" "$patchUrlTitle") 'Known issues in this update' section.
"@
    
    $dataRow.RuleResult="The stored procedure is fine. $(CollectorLink SQL_ForRFH_829977.csv)"
    $dataRow.SAPCategories = "wf*" 
    $dataRow.ProblemSeverity=[ProblemSeverity]::Critical

    $spIsCorrect = $false
    $spContent = (GetFileContentInSourceFolder SQL_ForRFH_829977.csv)
    [string]$contentToCheck = ( GetSubstringFromString $spContent '@SaclIsOn' '@RowCount' -includeEndingText $true )
    $contentToCheck = ( GetSubstringFromString $contentToCheck 'As' '@RowCount' )
    $contentToCheck = $contentToCheck.Replace("DECLARE","").Trim()

    if ([string]::IsNullOrWhiteSpace($contentToCheck)) { 
        $spIsCorrect = $true 
    }
    elseif ( $contentToCheck.StartsWith('/*') ){ 
        $spIsCorrect = $true 
    }

    if ($spIsCorrect ) { $Result_OKs += $dataRow }   
    else {        
        $dataRow.RuleResult = @"
The stored procedure $(CollectorLink SQL_ForRFH_829977.csv) seems to be wrong and is most likely causing workflows to be delayed.
The SQL script $(GetAnchorForExternal 'https://download.microsoft.com/download/3/d/5/3d54d436-3da9-4181-b74c-5a3031998657/Workaround_UnauthorizedAccessException.sql' 'SQL script workaround') needs to executed after applying $patchTitle.
<br/><b>Important:</b> It is mandatory to run the workaround SQL script after applying $patchTitle onto the Primary (WF) management server. However, if $patchTitle is applied later onto Secondary management server(s) then the 'wrong' stored procedure will come back into the SM database.
Therefore, it's important to run the workaround SQL script <u>after</u> the last patched management server. It's OK to run the workaround SQL script several times.
"@
        $Result_Problems += $dataRow
    } 
}
 