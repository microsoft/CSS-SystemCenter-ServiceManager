#region internal function definitions used by Collector and also Analyzer
function GetCurrentUser() {
    [System.Security.Principal.WindowsIdentity]::GetCurrent()
}
function IsRunningAsElevated() {
    return $(([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
}
function CreateNewFileInTargetFolder($fileName) {
    New-Item -Force -ItemType File -Path $resultFolder -Name $fileName | Out-Null
}
function CreateNewFolderInTargetFolder($folderName) {
    New-Item -Force -ItemType Directory -Path $resultFolder -Name $folderName | Out-Null
}
function GetFileNameInTargetFolder($fileName) {
    return Join-Path -Path $resultFolder -ChildPath $fileName
}
function GetFileContentInTargetFolder($fileName) {
    return Get-Content -Path (Join-Path -Path $resultFolder -ChildPath $fileName) | Out-String
    #return [IO.File]::ReadAllText( (Join-Path -Path $resultFolder -ChildPath $fileName) )
}
function DeleteFileInTargetFolder($fileName) {
    return Remove-Item -Path (Join-Path -Path $resultFolder -ChildPath $fileName)
}
function FileDoesExistInTargetFolder($fileName) {
    return Test-Path -Path (Join-Path -Path $resultFolder -ChildPath $fileName)
}
function FileDoesNotExistInTargetFolder($fileName) {
    return -Not (FileDoesExistInTargetFolder $fileName)
}
function CopyFileToTargetFolder($fileName, $subFolderName) {
  if ([string]::IsNullOrEmpty($subFolderName) -or $subFolderName -eq ".") { 
    Copy-Item $fileName -Destination $resultFolder}
  else  {
    New-Item -ItemType Directory -Force -Path "$resultFolder\$subFolderName" | Out-Null
    Copy-Item $fileName -Destination "$resultFolder\$subFolderName" }
}
function MoveFileInTargetFolder($fileName, $subFolderName) {
    $fileToMove=GetFileNameInTargetFolder $fileName
    CopyFileToTargetFolder $fileToMove $subFolderName
    DeleteFileInTargetFolder $fileName
}
function CopyFileWithNewNameInTargetFolder($sourceFileName, $targetFileName) {  
    Copy-Item "$resultFolder\$sourceFileName" -Destination "$resultFolder\$targetFileName" 
}
function AppendOutputToFileInTargetFolder($obj, $fileName) {
    $resultFilePath = Join-Path -Path $resultFolder -ChildPath $fileName    
    if (!(Test-Path $resultFilePath))
    {
       New-Item $resultFilePath -ItemType File -Force | Out-Null
    }
    $obj | Out-File -FilePath $resultFilePath -Encoding utf8 -Append 
}

function SaveSQLResultSetsToFiles($SQLInstance, $SQLDatabase, $SQLQuery, $fileName, $includeBatchInResultSet, [int]$SqlCommandTimeoutSeconds = 0) 
{
    if (-not (Get-Variable -Name SQLResultSetCounter -Scope Script -ErrorAction SilentlyContinue)) {
    #if ([string]::IsNullOrEmpty($script:SQLResultSetCounter)) 
        $script:SQLResultSetCounter=1
    }
    
    $batches = $SQLQuery -split '(?:\bGO\b)'
    foreach($batch in $batches)
    {
        if ([string]::IsNullOrEmpty($batch.Trim())) {continue}
        $DS= Try-Invoke-SqlCmd -SQLInstance $SQLInstance -SQLDatabase $SQLDatabase -Query $batch -SqlCommandTimeoutSeconds $SqlCommandTimeoutSeconds
        $targetCsvFileName = $fileName 

#        if ($DS.Tables.Count -eq 0) { # write the Sql Print messages
#            AppendOutputToFileInTargetFolder $global:SqlPrintMessages $targetCsvFileName
#        }
#        else {
            foreach($dataTable in $DS.Tables) 
            {            
                if ([string]::IsNullOrEmpty($targetCsvFileName))
                {
                    $targetCsvFileName = "SQLResultSet_$script:SQLResultSetCounter.csv"
                    $script:SQLResultSetCounter++
                }            
                SaveSQLResultToFile ($dataTable) $targetCsvFileName $batch #$includeBatchInResultSet      
            }
            AppendOutputToFileInTargetFolder $global:SqlPrintMessages $targetCsvFileName

#       }

        if ($includeBatchInResultSet -eq $null) {$includeBatchInResultSet=$true}
        if ($includeBatchInResultSet) {
            AppendOutputToFileInTargetFolder "" $targetCsvFileName
            AppendOutputToFileInTargetFolder "/*------------------------`r`n$($batch.Trim())`r`n------------------------*/" $targetCsvFileName 
        }
    }
}

function SaveSQLResultToFile($dataTable, $fileName, $batch)  #, $includeBatchInResultSet) 
{
    $TempFileName = ([guid]::NewGuid()).ToString()    
    AppendOutputToCsvFileInTargetFolder ($dataTable) $TempFileName
    #if ($includeBatchInResultSet -eq $null) {$includeBatchInResultSet=$true}
    #if ($includeBatchInResultSet) {
    #    AppendOutputToFileInTargetFolder "" $TempFileName
    #    AppendOutputToFileInTargetFolder "/*------------------------`r`n$($batch.Trim())`r`n------------------------*/" $TempFileName 
    #}
    AppendOutputToFileInTargetFolder "" $fileName
    AppendOutputToFileInTargetFolder (GetFileContentInTargetFolder $TempFileName) $fileName
    DeleteFileInTargetFolder $TempFileName
}

function Try-Invoke-SqlCmd
{
param (
        [Parameter(Mandatory=$true)] [string]$SQLInstance,
        [Parameter(Mandatory=$true)] [string]$SQLDatabase,
        [Parameter(Mandatory=$true)] [string]$Query,
        [Parameter(Mandatory=$false)] [int]$SqlCommandTimeoutSeconds = 0
)
# I do not use Invoke-Sqlcmd anymore because it requires 1. distinct column names and 2. Module "SqlServer" to be installed
#      $DS = Invoke-Sqlcmd -ServerInstance $SQLInstance -Database $SQLDatabase -Query $Query -OutputAs DataSet -QueryTimeout 0 -OutputSqlErrors $true -IncludeSqlUserErrors -MaxCharLength ([int32]::MaxValue)
#      return $DS;

    if ($SqlCommandTimeoutSeconds -eq 0) {
        $DS = Invoke-AlternativeSqlCmd_WithoutTimeout $SQLInstance $SQLDatabase $Query
    }
    else {
        $DS = Invoke-AlternativeSqlCmd_WithTimeout $SQLInstance $SQLDatabase $Query $SqlCommandTimeoutSeconds

    }
    return $DS;

}
function Invoke-AlternativeSqlCmd_WithoutTimeout($SQLInstance, $SQLDatabase, $SQLQuery)
{
    $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
    $SqlConnection.ConnectionString = "Server=$SQLInstance; Database=$SQLDatabase; Trusted_Connection=True"
    $SqlConnection.Open() 

    $SqlAdp = New-Object System.Data.SqlClient.SqlDataAdapter
    $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
    $SqlCmd.CommandText = $SQLQuery
    $SqlCmd.Connection = $SqlConnection
    $SqlCmd.CommandTimeout = 0 # do NOT change this!
    $SqlAdp.SelectCommand = $SqlCmd

        $global:SqlPrintMessages=""
        $handler = [System.Data.SqlClient.SqlInfoMessageEventHandler] {
            param($sender, $event) 
            $global:SqlPrintMessages += "`n" + $event.Message 
        };
        $SqlConnection.add_InfoMessage($handler); 
        $SqlConnection.FireInfoMessageEventOnUserErrors = $true;


    $DS = New-Object System.Data.DataSet
    $SqlAdp.Fill($DS) | out-null  # keep the out-null otherwise $DS will return as Object[]
    return $DS;
}

function Invoke-AlternativeSqlCmd_WithTimeout($SQLInstance, $SQLDatabase, $SQLQuery, [int]$SqlCommandTimeoutSeconds)
{
    # no need for a background job, query will run indefinitely and sync
    if ($SqlCommandTimeoutSeconds -eq 0) {
        Invoke-AlternativeSqlCmd_WithoutTimeout $SQLInstance $SQLDatabase $SQLQuery
        return
    }

    $code = { 
    
        #region Getting input params
        #because of:  https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_automatic_variables?view=powershell-5.1#input
        #and https://docs.microsoft.com/en-us/dotnet/api/system.collections.ienumerator?view=netframework-4.8#remarks
        if ($input.MoveNext()) { $inputs = $input.Current } else { return }  
        #endregion  

        function Invoke-AlternativeSqlCmd_WithoutTimeout($SQLInstance, $SQLDatabase, $SQLQuery)
        {
            $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
            $SqlConnection.ConnectionString = "Server=$SQLInstance; Database=$SQLDatabase; Trusted_Connection=True"
            $SqlConnection.Open() 

            $SqlAdp = New-Object System.Data.SqlClient.SqlDataAdapter
            $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
            $SqlCmd.CommandText = $SQLQuery
            $SqlCmd.Connection = $SqlConnection
            $SqlCmd.CommandTimeout = 0 # do NOT change this!
            $SqlAdp.SelectCommand = $SqlCmd

                $global:SqlPrintMessages=""
                $handler = [System.Data.SqlClient.SqlInfoMessageEventHandler] {
                    param($sender, $event) 
                    $global:SqlPrintMessages += "`n" + $event.Message 
                };
                $SqlConnection.add_InfoMessage($handler); 
                $SqlConnection.FireInfoMessageEventOnUserErrors = $true;

            $DS = New-Object System.Data.DataSet
            $SqlAdp.Fill($DS) | out-null  # keep the out-null otherwise $DS will return as Object[]
            return $DS;
        }
     
        $SQLInstance, $SQLDatabase, $SQLQuery = $inputs  
        Invoke-AlternativeSqlCmd_WithoutTimeout -SQLInstance $SQLInstance -SQLDatabase $SQLDatabase -SQLQuery $SQLQuery
    }

    $jobParams = @($SQLInstance, $SQLDatabase, $SQLQuery)
    $job = Start-Job -ScriptBlock $code -InputObject $jobParams
    $PIDofNewJob = (Get-WmiObject win32_process -filter "Name='powershell.exe' AND ParentProcessId=$PID" -Property ProcessID,CreationDate | Sort-Object -Property CreationDate -Descending | Select-Object -First 1 -Property ProcessId).ProcessId

    $timeoutsecs = $SqlCommandTimeoutSeconds
    Wait-Job -Job $job -Timeout $timeoutsecs | Out-Null

    if ( $job.State -eq "Running"  ) {        
        Stop-Process -Id $PIDofNewJob  | Out-Null 
        Write-Host "Stopped PID: $PIDofNewJob because of timeout secs: $timeoutsecs for query: $SQLQuery"   
    } 
    if ($job.State -eq "Completed") { 
        Receive-Job -Job $job
    }
    Remove-Job -Job $job -Force | Out-Null
    #$global:SqlPrintMessages #todo
}
function AppendOutputToCsvFileInTargetFolder($dataTable, $fileName) {     
    $resultFilePath = Join-Path -Path $resultFolder -ChildPath $fileName
    if ($dataTable.Rows.Count -eq 0) 
    {
        $header = ""
        foreach ($col in $dataTable.Columns) {
            $header += $col.ColumnName +","
        }
        $header = $header.Remove($header.Length-1,1) 
        AppendOutputToFileInTargetFolder $header $fileName
    } 
    else 
    {
        #$dataTable | export-csv -Path $resultFilePath -Encoding UTF8 -Append -NoTypeInformation
        AppendOutputToFileInTargetFolder ($dataTable | ConvertTo-Csv -NoTypeInformation) $fileName
    }
}

function GetNewSB() {return [System.Text.StringBuilder]::new();}
function SB_Append($sb, $text) {[void]$sb.Append( $text )}
function SB_AppendLine($sb, $text) {[void]$sb.AppendLine( $text )}

#function IsAnyScsmRoleInstalled() {
 # $regItems = [object[]](GP HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*  | ?{$_.DisplayName -like "*Service Manager*"})
 # $regItems.Count -gt 0
#}


function IsThisAnyScsmMgmtServer() { #includes WF, Secondary and DW    
    return ((IsThisScsmMgmtServer) -or (IsThisScsmDwMgmtServer))
}
function IsThisScsmMgmtServer() {  #includes WF, Secondary
    $regSetupExists = Test-Path -Path 'HKLM:\SOFTWARE\Microsoft\System Center\2010\Service Manager\Setup' -ErrorAction SilentlyContinue
    $regMGExists = Test-Path -Path 'HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Server Management Groups' -ErrorAction SilentlyContinue
    $regSDKType = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\System Center\2010\Common\SDK Service' -ErrorAction SilentlyContinue)."SDK Service Type"

    return ($regSetupExists -and $regMGExists -and ($regSDKType -eq 1))
}
function IsThisScsmDwMgmtServer() {
    $regSetupExists = Test-Path -Path 'HKLM:\SOFTWARE\Microsoft\System Center\2010\Service Manager\Setup' -ErrorAction SilentlyContinue
    $regMGExists = Test-Path -Path 'HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Server Management Groups' -ErrorAction SilentlyContinue
    $regSDKType = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\System Center\2010\Common\SDK Service' -ErrorAction SilentlyContinue)."SDK Service Type"

    return ($regSetupExists -and $regMGExists -and ($regSDKType -eq 2))
}
function IsThisScsmWfMgmtServer() {
    $qry = @'
    select bme.Name, bme.DisplayName
    FROM dbo.[ScopedInstanceTargetClass] sitc
        inner join ManagedType mt on mt.ManagedTypeId = sitc.ManagedTypeId
        inner join BaseManagedEntity bme on bme.BaseManagedEntityId = sitc.ScopedInstanceId and bme.IsDeleted=0
    where mt.ManagedTypeId = dbo.fn_ManagedTypeId_MicrosoftSystemCenterWorkflowTarget()
'@
    $SQLInstance_SCSM = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\System Center\2010\Common\Database').DatabaseServerName
    $SQLDatabase_SCSM = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\System Center\2010\Common\Database').DatabaseName
    $ds = Try-Invoke-SqlCmd -SQLInstance $SQLInstance_SCSM -SQLDatabase $SQLDatabase_SCSM -Query $qry
    if ($ds.Tables.Count -eq 0) {
        Write-Host "Error in IsThisScsmWfMgmtServer(): $global:SqlPrintMessages"
    }
    $WfDisplayName = $ds.Tables[0].DisplayName
    return ( ($env:COMPUTERNAME -eq $WfDisplayName) -or ([System.Net.Dns]::GetHostEntry([string]$env:computername).HostName -eq $WfDisplayName) )
}
function IsThisScsmSecondaryMgmtServer() {
    return ((IsThisScsmMgmtServer) -and (-not (IsThisScsmWfMgmtServer)))
}
function IsScsmHtmlPortalInstalled() {
    $PortalVirtualDirectory = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\System Center\2010\Service Manager\Setup' -ErrorAction SilentlyContinue).PortalVirtualDirectory
    return ($PortalVirtualDirectory -ne $null)
}
function IsScsmConsoleInstalled() {
# todo
    $PortalVirtualDirectory = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\System Center\2010\Service Manager\Setup' -ErrorAction SilentlyContinue).PortalVirtualDirectory
    return ($PortalVirtualDirectory -ne $null)
}

function IsThisHostingServiceManagerDB() {

$SQLInstance_SCSM = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\System Center\2010\Common\Database').DatabaseServerName
$SQLDatabase_SCSM = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\System Center\2010\Common\Database').DatabaseName
}
function IsThisHostingDwStagingAndDwRepDB() {

}
function IsThisHostingDwDataMartDB() {

}
function GetScsmDWSsrsServer() {
    $class= get-scclass -Name Microsoft.SystemCenter.ResourceAccessLayer.SrsResourceStore # -ComputerName <DWServerName>  
    $SrsServer= get-scclassinstance -class $class #-ComputerName <DWServerName>  
    $SrsServer.Server #  DataService  ????
}
function GetScsmDWSsasServer() {
    $class= get-scclass -Name Microsoft.SystemCenter.ResourceAccessLayer.ASResourceStore # -ComputerName <DWServerName>  
    $OLAPServer= get-scclassinstance -class $class #-ComputerName <DWServerName>  
    $OLAPServer.Server    
}
function GetMachineNameFromSqlInstance($SqlInstanceName) {
    $tmp = $SqlInstanceName.Split("\\")[0]
    $tmp.Split(",")[0]
}
function GetPortFromSqlInstance($SqlInstanceName) {
	$port = $SqlInstanceName.Split(",")[1]
	if ($port -eq $null) { 
	        1433 
	}
	else { 
	    [int]($port.trim()) 
	}
	
}
function GetNamedInstanceNameFromSqlInstance($SqlInstanceName) {
    $tmp = $SqlInstanceName.Split("\\")[1]
    if ($tmp -eq $null) {
        $namedInstanceName=""
    }
    else {
        $namedInstanceName=$tmp.Split(",")[0]
    }
    $namedInstanceName
}
function Get-UserFriendlyTimeSpane ($Duration) {
    $Day = switch ($Duration.Days) {
        0 { $null; break }       
        Default {"{0}d." -f $Duration.Days}
    }

    $Hour = switch ($Duration.Hours) {
        0 { $null; break }       
        Default { "{0}h:" -f $Duration.Hours }
    }

    $Minute = switch ($Duration.Minutes) {
        0 { $null; break }       
        Default { "{0}m" -f $Duration.Minutes }
    }

    $Second = switch ($Duration.Seconds) {
        0 { $null; break }        
        Default { ":{0}s" -f $Duration.Seconds }
    }

    "$Day$Hour$Minute$Second"
}
function MakeNewZipFile($source,$archive) { #https://stackoverflow.com/questions/40692024/zip-and-unzip-file-in-powershell-4
    Add-Type -assembly "system.io.compression.filesystem"
    [io.compression.zipfile]::CreateFromDirectory($source, $archive)
}
function GetSqlErrorLogFiles ($SQLInstance, $SQLDatabase){
    CreateNewFolderInTargetFolder "ERRORLOG"   

    $errorlogLocalfilename=(Try-Invoke-SqlCmd -SQLInstance $SQLInstance -SQLDatabase $SQLDatabase -Query "select cast(SERVERPROPERTY(N'errorlogfilename') as nvarchar(512)) as errorlogfilename").Tables[0].errorlogfilename
    AppendOutputToFileInTargetFolder "errorlogLocalfilename: $errorlogLocalfilename `n" 'ERRORLOG\Notes.txt' 
    $DriveOfErrorlogfilename = $errorlogLocalfilename.substring(0,1)
    $RestOfErrorlogfilename = $errorlogLocalfilename.substring(2)        
    $errorlogRemotefilename="\\$(GetMachineNameFromSqlInstance $SQLInstance)\$DriveOfErrorlogfilename$\$RestOfErrorlogfilename"

    [long]$SizeOfRecentSqlErrorlogFile= (Get-Item  -Path $errorlogRemotefilename   -ErrorAction SilentlyContinue | select Length | measure -Sum -Property Length -ErrorAction SilentlyContinue).Sum 
    [long]$TotalSizeOfSqlErrorlogFiles= (Get-Item -Path "$errorlogRemotefilename*" -ErrorAction SilentlyContinue | select Length | measure -Sum -Property Length -ErrorAction SilentlyContinue).Sum 

    if ($SizeOfRecentSqlErrorlogFile -gt 0) {
        if ($TotalSizeOfSqlErrorlogFiles -le 200MB ) {
            Get-Item -Path "$errorlogRemotefilename*" | % { CopyFileToTargetFolder ($_.Fullname) "ERRORLOG" }
            AppendOutputToFileInTargetFolder "All ERRORLOG file(s) copied." 'ERRORLOG\Notes.txt'            
        }
        elseif ($SizeOfRecentSqlErrorlogFile -le 100MB){
            CopyFileToTargetFolder $errorlogRemotefilename "ERRORLOG"
            AppendOutputToFileInTargetFolder "Only recent ERRORLOG file copied. TotalSizeOfSqlErrorlogFiles:$TotalSizeOfSqlErrorlogFiles" 'ERRORLOG\Notes.txt'            
        }
        else {
            AppendOutputToFileInTargetFolder "ERRORLOG file(s) too big: SizeOfRecentSqlErrorlogFile:$SizeOfRecentSqlErrorlogFile   TotalSizeOfSqlErrorlogFiles:$TotalSizeOfSqlErrorlogFiles" 'ERRORLOG\Notes.txt'            
        }
    }
    else {
        AppendOutputToFileInTargetFolder "Error while accessing remote SQL ERRORLOG file(s): errorlogLocalfilename:$errorlogLocalfilename `n $_" 'ERRORLOG\Notes.txt'
        AppendOutputToFileInTargetFolder "Now trying to read SQL ERRORLOG entries via xp_readerrorlog" 'ERRORLOG\Notes.txt'
        try {
            SaveSQLResultSetsToFiles $SQLInstance $SQLDatabase "xp_readerrorlog" "ERRORLOG_via_xp_readerrorlog.txt" -SqlCommandTimeoutSeconds 4
            MoveFileInTargetFolder 'ERRORLOG_via_xp_readerrorlog.txt' "ERRORLOG"
        }
        catch {
            AppendOutputToFileInTargetFolder "Error while accessing SQL ERRORLOG entries via xp_readerrorlog `n $_" 'ERRORLOG\Notes.txt'
        } 
    }
}
function GetEmailSendingRules() {

    if(! (Get-Module -ListAvailable -Name SMLets)) {
        "N/A because SMLets is not installed." 
        return 
    } 

    $rules = @()
    $wkfs = Get-SCSMWorkflow  | where {  ($_.EnableNotification -and $_.Notification) -or 
                                        ($_.WorkflowSubscription -is [Microsoft.EnterpriseManagement.Subscriptions.NotificationSubscription]) 
                                      } 
    foreach($wkf in $wkfs)
    {   
        if ($wkf.WorkflowSubscription.SubscriptionType -is [Microsoft.EnterpriseManagement.Subscriptions.RelationshipTypeSubscription])
        {       
            $class = Get-SCSMRelationship -Id $wkf.WorkflowSubscription.SubscriptionType.SourceTypeId
            $classDisplayName = $class.DisplayName 

            $sourceType = Get-SCSMClass -id $class.Source.Type.Id 
            $targetType = Get-SCSMClass -id $class.Target.Type.Id 
            $classDisplayName += " (" + $sourceType.DisplayName + " -> " + $targetType.DisplayName + ")"
        }  
        elseif ($wkf.WorkflowSubscription.SubscriptionType -is [Microsoft.EnterpriseManagement.Subscriptions.InstanceTypeSubscription])
        {   
            $class = Get-SCSMClass -id $wkf.WorkflowSubscription.SubscriptionType.TypeId
            $classDisplayName = $class.DisplayName    
        }
        else
        {
            $exc = "unexpected SubscriptionType!!!"
            $exc
            continue
        } 

        $peopleToNotify = ""
        $templateAndRecipients = ""
        $templates = ""
	    $recipients = ""

        if ($wkf.WorkflowSubscription -is [Microsoft.EnterpriseManagement.Subscriptions.WorkflowSubscription])
        {  
		    $templates = $wkf.Notification | % { $_.Template.DisplayName + "; " } 
		    $templates = "$templates"
		
            $recipients = $wkf.Notification | % { $_.User + "; " } 	
		    $recipients = "$recipients"		
        }
        elseif ($wkf.WorkflowSubscription -is [Microsoft.EnterpriseManagement.Subscriptions.NotificationSubscription])
        {
		    $templates = $wkf.WorkflowSubscription.TemplateIds | % { Get-SCSMObjectTemplate -Id $_.Guid } | % { $_.DisplayName }
		
		    $recipients = $wkf.WorkflowSubscription.Recipients | % { Get-SCSMObject -Id $_.Recipient} | % { $_.DisplayName + "; " }
		    $recipients = "$recipients"	
            $recipients += [system.String]::Join("; ", $wkf.WorkflowSubscription.RelatedRecipients)				
        }
        else
        {
            $exc = "unexpected Workflow Subscription Type "
            $exc
            continue
        }

        $rule = New-Object System.Object
        $rule | Add-Member -type NoteProperty -Name "The Rule" -Value $wkf.DisplayName
        $rule | Add-Member -type NoteProperty -Name "in Management Pack" -Value $wkf.ManagementPack.DisplayName    
        $rule | Add-Member -type NoteProperty -Name "is" -Value @{$true="Enabled";$false="Disabled"}[$wkf.Enabled]
        $rule | Add-Member -type NoteProperty -Name "Runs when each" -Value $classDisplayName
    
        $subscriptionType = switch ($wkf.WorkflowSubscription.SubscriptionType.GetType().Name)
        {
            InstanceTypeSubscription {"is"}
            RelationshipTypeSubscription {"Relationship"}
            default {"unknown??? :" + $wkf.WorkflowSubscription.SubscriptionType.GetType().Name}
        }
        $rule | Add-Member -type NoteProperty -Name "(Type)" -Value $subscriptionType    
        $editableInConsole = -Not ($subscriptionType -eq "Relationship")    
    
        $operation = switch ($wkf.WorkflowSubscription.SubscriptionType.Operation)
        {
            Add {"created"}
            Update {"updated"}
            PeriodicQuery {"periodically checked"}
            default {"unknown!!!"}
        }
        $rule | Add-Member -type NoteProperty -Name "is:" -Value $operation     
     
        $rule | Add-Member -type NoteProperty -Name "It is of type" -Value  @{$true="Workflow";$false="Notification"}[$wkf.WorkflowSubscription.GetType().Name -eq "WorkflowSubscription"] 
        $rule | Add-Member -type NoteProperty -Name "and can be edited" -Value @{$true="in Console";$false="only in MP xml"}[ $editableInConsole]

        $hasCriteria = ($wkf.Criteria.length -gt 0)
        $rule | Add-Member -type NoteProperty -Name "and has any criteria?" -Value @{$true="Yes";$false="No"}[$hasCriteria]

        $rule | Add-Member -type NoteProperty -Name "Templates" -Value $templates
	    $rule | Add-Member -type NoteProperty -Name "Recipients" -Value $recipients
        $rule | Add-Member -type NoteProperty -Name "Time Added" -Value $wkf.WorkflowSubscription.TimeAdded
        $rule | Add-Member -type NoteProperty -Name "Last Modified" -Value $wkf.WorkflowSubscription.LastModified
        $rule | Add-Member -type NoteProperty -Name "Description" -Value $wkf.Description
        $rule | Add-Member -type NoteProperty -Name "Criteria" -Value $wkf.Criteria
    
        $rules += $rule  
    }
    $rules
}
#region Zipping in PS 2.0
#credits: https://gist.github.com/deadlydog/4d3d98ca10c5c6b62e29f7e793850305

# Recursive function to calculate the total number of files and directories in the Zip file.
function GetNumberOfItemsInZipFileItems($shellItems)
{
	[int]$totalItems = $shellItems.Count
	foreach ($shellItem in $shellItems)
	{
		if ($shellItem.IsFolder)
		{ $totalItems += GetNumberOfItemsInZipFileItems -shellItems $shellItem.GetFolder.Items() }
	}
	$totalItems
}

# Recursive function to move a directory into a Zip file, since we can move files out of a Zip file, but not directories, and copying a directory into a Zip file when it already exists is not allowed.
function MoveDirectoryIntoZipFile($parentInZipFileShell, $pathOfItemToCopy)
{
	# Get the name of the file/directory to copy, and the item itself.
	$nameOfItemToCopy = Split-Path -Path $pathOfItemToCopy -Leaf
	if ($parentInZipFileShell.IsFolder)
	{ $parentInZipFileShell = $parentInZipFileShell.GetFolder }
	$itemToCopyShell = $parentInZipFileShell.ParseName($nameOfItemToCopy)
	
	# If this item does not exist in the Zip file yet, or it is a file, move it over.
	if ($itemToCopyShell -eq $null -or !$itemToCopyShell.IsFolder)
	{
		$parentInZipFileShell.MoveHere($pathOfItemToCopy)
		
		# Wait for the file to be moved before continuing, to avoid erros about the zip file being locked or a file not being found.
		while (Test-Path -Path $pathOfItemToCopy)
		{ Start-Sleep -Milliseconds 10 }
	}
	# Else this is a directory that already exists in the Zip file, so we need to traverse it and copy each file/directory within it.
	else
	{
		# Copy each file/directory in the directory to the Zip file.
		foreach ($item in (Get-ChildItem -Path $pathOfItemToCopy -Force))
		{
			MoveDirectoryIntoZipFile -parentInZipFileShell $itemToCopyShell -pathOfItemToCopy $item.FullName
		}
	}
}

# Recursive function to move all of the files that start with the File Name Prefix to the Directory To Move Files To.
function MoveFilesOutOfZipFileItems($shellItems, $directoryToMoveFilesToShell, $fileNamePrefix)
{
	# Loop through every item in the file/directory.
	foreach ($shellItem in $shellItems)
	{
		# If this is a directory, recursively call this function to iterate over all files/directories within it.
		if ($shellItem.IsFolder)
		{ 
			$totalItems += MoveFilesOutOfZipFileItems -shellItems $shellItem.GetFolder.Items() -directoryToMoveFilesTo $directoryToMoveFilesToShell -fileNameToMatch $fileNameToMatch
		}
		# Else this is a file.
		else
		{
			# If this file name starts with the File Name Prefix, move it to the specified directory.
			if ($shellItem.Name.StartsWith($fileNamePrefix))
			{
				$directoryToMoveFilesToShell.MoveHere($shellItem)
			}
		}			
	}
}

function Expand-ZipFile
{
	[CmdletBinding()]
	param
	(
		[parameter(Position=1,Mandatory=$true)]
		[ValidateScript({(Test-Path -Path $_ -PathType Leaf) -and $_.EndsWith('.zip', [StringComparison]::OrdinalIgnoreCase)})]
		[string]$ZipFilePath, 
		
		[parameter(Position=2,Mandatory=$false)]
		[string]$DestinationDirectoryPath, 
		
		[Alias("Force")]
		[switch]$OverwriteWithoutPrompting
	)
	
	BEGIN { }
	END { }
	PROCESS
	{	
		# If a Destination Directory was not given, create one in the same directory as the Zip file, with the same name as the Zip file.
		if ($DestinationDirectoryPath -eq $null -or $DestinationDirectoryPath.Trim() -eq [string]::Empty)
		{
			$zipFileDirectoryPath = Split-Path -Path $ZipFilePath -Parent
			$zipFileNameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($ZipFilePath)
			$DestinationDirectoryPath = Join-Path -Path $zipFileDirectoryPath -ChildPath $zipFileNameWithoutExtension
		}
		
		# If the directory to unzip the files to does not exist yet, create it.
		if (!(Test-Path -Path $DestinationDirectoryPath -PathType Container)) 
		{ New-Item -Path $DestinationDirectoryPath -ItemType Container > $null }

		# Flags and values found at: https://msdn.microsoft.com/en-us/library/windows/desktop/bb759795%28v=vs.85%29.aspx
		$FOF_SILENT = 0x0004
		$FOF_NOCONFIRMATION = 0x0010
		$FOF_NOERRORUI = 0x0400

		# Set the flag values based on the parameters provided.
		$copyFlags = 0
		if ($OverwriteWithoutPrompting)
		{ $copyFlags = $FOF_NOCONFIRMATION }
	#	{ $copyFlags = $FOF_SILENT + $FOF_NOCONFIRMATION + $FOF_NOERRORUI }

		# Get the Shell object, Destination Directory, and Zip file.
	    $shell = New-Object -ComObject Shell.Application
		$destinationDirectoryShell = $shell.NameSpace($DestinationDirectoryPath)
	    $zipShell = $shell.NameSpace($ZipFilePath)
		
		# Start copying the Zip files into the destination directory, using the flags specified by the user. This is an asynchronous operation.
	    $destinationDirectoryShell.CopyHere($zipShell.Items(), $copyFlags)

		# Get the number of files and directories in the Zip file.
		$numberOfItemsInZipFile = GetNumberOfItemsInZipFileItems -shellItems $zipShell.Items()
		
		# The Copy (i.e. unzip) operation is asynchronous, so wait until it is complete before continuing. That is, sleep until the Destination Directory has the same number of files as the Zip file.
		while ((Get-ChildItem -Path $DestinationDirectoryPath -Recurse -Force).Count -lt $numberOfItemsInZipFile)
		{ Start-Sleep -Milliseconds 100 }
	}
}

function Compress-ZipFile
{
	[CmdletBinding()]
	param
	(
		[parameter(Position=1,Mandatory=$true)]
		[ValidateScript({Test-Path -Path $_})]
		[string]$FileOrDirectoryPathToAddToZipFile, 
	
		[parameter(Position=2,Mandatory=$false)]
		[string]$ZipFilePath,
		
		[Alias("Force")]
		[switch]$OverwriteWithoutPrompting
	)
	
	BEGIN { }
	END { }
	PROCESS
	{
		# If a Zip File Path was not given, create one in the same directory as the file/directory being added to the zip file, with the same name as the file/directory.
		if ($ZipFilePath -eq $null -or $ZipFilePath.Trim() -eq [string]::Empty)
		{ $ZipFilePath = Join-Path -Path $FileOrDirectoryPathToAddToZipFile -ChildPath '.zip' }
		
		# If the Zip file to create does not have an extension of .zip (which is required by the shell.application), add it.
		if (!$ZipFilePath.EndsWith('.zip', [StringComparison]::OrdinalIgnoreCase))
		{ $ZipFilePath += '.zip' }
		
		# If the Zip file to add the file to does not exist yet, create it.
		if (!(Test-Path -Path $ZipFilePath -PathType Leaf))
		{ New-Item -Path $ZipFilePath -ItemType File > $null }

		# Get the Name of the file or directory to add to the Zip file.
		$fileOrDirectoryNameToAddToZipFile = Split-Path -Path $FileOrDirectoryPathToAddToZipFile -Leaf

		# Get the number of files and directories to add to the Zip file.
		$numberOfFilesAndDirectoriesToAddToZipFile = (Get-ChildItem -Path $FileOrDirectoryPathToAddToZipFile -Recurse -Force).Count
		
		# Get if we are adding a file or directory to the Zip file.
		$itemToAddToZipIsAFile = Test-Path -Path $FileOrDirectoryPathToAddToZipFile -PathType Leaf

		# Get Shell object and the Zip File.
		$shell = New-Object -ComObject Shell.Application
		$zipShell = $shell.NameSpace($ZipFilePath)

		# We will want to check if we can do a simple copy operation into the Zip file or not. Assume that we can't to start with.
		# We can if the file/directory does not exist in the Zip file already, or it is a file and the user wants to be prompted on conflicts.
		$canPerformSimpleCopyIntoZipFile = $false

		# If the file/directory does not already exist in the Zip file, or it does exist, but it is a file and the user wants to be prompted on conflicts, then we can perform a simple copy into the Zip file.
		$fileOrDirectoryInZipFileShell = $zipShell.ParseName($fileOrDirectoryNameToAddToZipFile)
		$itemToAddToZipIsAFileAndUserWantsToBePromptedOnConflicts = ($itemToAddToZipIsAFile -and !$OverwriteWithoutPrompting)
		if ($fileOrDirectoryInZipFileShell -eq $null -or $itemToAddToZipIsAFileAndUserWantsToBePromptedOnConflicts)
		{
			$canPerformSimpleCopyIntoZipFile = $true
		}
		
		# If we can perform a simple copy operation to get the file/directory into the Zip file.
		if ($canPerformSimpleCopyIntoZipFile)
		{
			# Start copying the file/directory into the Zip file since there won't be any conflicts. This is an asynchronous operation.
			$zipShell.CopyHere($FileOrDirectoryPathToAddToZipFile)	# Copy Flags are ignored when copying files into a zip file, so can't use them like we did with the Expand-ZipFile function.
			
			# The Copy operation is asynchronous, so wait until it is complete before continuing.
			# Wait until we can see that the file/directory has been created.
			while ($zipShell.ParseName($fileOrDirectoryNameToAddToZipFile) -eq $null)
			{ Start-Sleep -Milliseconds 100 }
			
			# If we are copying a directory into the Zip file, we want to wait until all of the files/directories have been copied.
			if (!$itemToAddToZipIsAFile)
			{
				# Get the number of files and directories that should be copied into the Zip file.
				$numberOfItemsToCopyIntoZipFile = (Get-ChildItem -Path $FileOrDirectoryPathToAddToZipFile -Recurse -Force).Count
			
				# Get a handle to the new directory we created in the Zip file.
				$newDirectoryInZipFileShell = $zipShell.ParseName($fileOrDirectoryNameToAddToZipFile)
				
				# Wait until the new directory in the Zip file has the expected number of files and directories in it.
				while ((GetNumberOfItemsInZipFileItems -shellItems $newDirectoryInZipFileShell.GetFolder.Items()) -lt $numberOfItemsToCopyIntoZipFile)
				{ Start-Sleep -Milliseconds 100 }
			}
		}
		# Else we cannot do a simple copy operation. We instead need to move the files out of the Zip file so that we can merge the directory, or overwrite the file without the user being prompted.
		# We cannot move a directory into the Zip file if a directory with the same name already exists, as a MessageBox warning is thrown, not a conflict resolution prompt like with files.
		# We cannot silently overwrite an existing file in the Zip file, as the flags passed to the CopyHere/MoveHere functions seem to be ignored when copying into a Zip file.
		else
		{
			# Create a temp directory to hold our file/directory.
			$tempDirectoryPath = $null
			$tempDirectoryPath = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ([System.IO.Path]::GetRandomFileName())
			New-Item -Path $tempDirectoryPath -ItemType Container > $null
		
			# If we will be moving a directory into the temp directory.
			$numberOfItemsInZipFilesDirectory = 0
			if ($fileOrDirectoryInZipFileShell.IsFolder)
			{
				# Get the number of files and directories in the Zip file's directory.
				$numberOfItemsInZipFilesDirectory = GetNumberOfItemsInZipFileItems -shellItems $fileOrDirectoryInZipFileShell.GetFolder.Items()
			}
		
			# Start moving the file/directory out of the Zip file and into a temp directory. This is an asynchronous operation.
			$tempDirectoryShell = $shell.NameSpace($tempDirectoryPath)
			$tempDirectoryShell.MoveHere($fileOrDirectoryInZipFileShell)
			
			# If we are moving a directory, we need to wait until all of the files and directories in that Zip file's directory have been moved.
			$fileOrDirectoryPathInTempDirectory = Join-Path -Path $tempDirectoryPath -ChildPath $fileOrDirectoryNameToAddToZipFile
			if ($fileOrDirectoryInZipFileShell.IsFolder)
			{
				# The Move operation is asynchronous, so wait until it is complete before continuing. That is, sleep until the Destination Directory has the same number of files as the directory in the Zip file.
				while ((Get-ChildItem -Path $fileOrDirectoryPathInTempDirectory -Recurse -Force).Count -lt $numberOfItemsInZipFilesDirectory)
				{ Start-Sleep -Milliseconds 100 }
			}
			# Else we are just moving a file, so we just need to check for when that one file has been moved.
			else
			{
				# The Move operation is asynchronous, so wait until it is complete before continuing.
				while (!(Test-Path -Path $fileOrDirectoryPathInTempDirectory))
				{ Start-Sleep -Milliseconds 100 }
			}
			
			# We want to copy the file/directory to add to the Zip file to the same location in the temp directory, so that files/directories are merged.
			# If we should automatically overwrite files, do it.
			if ($OverwriteWithoutPrompting)
			{ Copy-Item -Path $FileOrDirectoryPathToAddToZipFile -Destination $tempDirectoryPath -Recurse -Force }
			# Else the user should be prompted on each conflict.
			else
			{ Copy-Item -Path $FileOrDirectoryPathToAddToZipFile -Destination $tempDirectoryPath -Recurse -Confirm -ErrorAction SilentlyContinue }	# SilentlyContinue errors to avoid an error for every directory copied.

			# For whatever reason the zip.MoveHere() function is not able to move empty directories into the Zip file, so we have to put dummy files into these directories 
			# and then remove the dummy files from the Zip file after.
			# If we are copying a directory into the Zip file.
			$dummyFileNamePrefix = 'Dummy.File'
			[int]$numberOfDummyFilesCreated = 0
			if ($fileOrDirectoryInZipFileShell.IsFolder)
			{
				# Place a dummy file in each of the empty directories so that it gets copied into the Zip file without an error.
				$emptyDirectories = Get-ChildItem -Path $fileOrDirectoryPathInTempDirectory -Recurse -Force -Directory | Where-Object { (Get-ChildItem -Path $_ -Force) -eq $null }
				foreach ($emptyDirectory in $emptyDirectories)
				{
					$numberOfDummyFilesCreated++
					New-Item -Path (Join-Path -Path $emptyDirectory.FullName -ChildPath "$dummyFileNamePrefix$numberOfDummyFilesCreated") -ItemType File -Force > $null
				}
			}		

			# If we need to copy a directory back into the Zip file.
			if ($fileOrDirectoryInZipFileShell.IsFolder)
			{
				MoveDirectoryIntoZipFile -parentInZipFileShell $zipShell -pathOfItemToCopy $fileOrDirectoryPathInTempDirectory
			}
			# Else we need to copy a file back into the Zip file.
			else
			{
				# Start moving the merged file back into the Zip file. This is an asynchronous operation.
				$zipShell.MoveHere($fileOrDirectoryPathInTempDirectory)
			}
			
			# The Move operation is asynchronous, so wait until it is complete before continuing.
			# Sleep until all of the files have been moved into the zip file. The MoveHere() function leaves empty directories behind, so we only need to watch for files.
			do
			{
				Start-Sleep -Milliseconds 100
				$files = Get-ChildItem -Path $fileOrDirectoryPathInTempDirectory -Force -Recurse | Where-Object { !$_.PSIsContainer }
			} while ($files -ne $null)
			
			# If there are dummy files that need to be moved out of the Zip file.
			if ($numberOfDummyFilesCreated -gt 0)
			{
				# Move all of the dummy files out of the supposed-to-be empty directories in the Zip file.
				MoveFilesOutOfZipFileItems -shellItems $zipShell.items() -directoryToMoveFilesToShell $tempDirectoryShell -fileNamePrefix $dummyFileNamePrefix
				
				# The Move operation is asynchronous, so wait until it is complete before continuing.
				# Sleep until all of the dummy files have been moved out of the zip file.
				do
				{
					Start-Sleep -Milliseconds 100
					[Object[]]$files = Get-ChildItem -Path $tempDirectoryPath -Force -Recurse | Where-Object { !$_.PSIsContainer -and $_.Name.StartsWith($dummyFileNamePrefix) }
				} while ($files -eq $null -or $files.Count -lt $numberOfDummyFilesCreated)
			}
			
			# Delete the temp directory that we created.
			Remove-Item -Path $tempDirectoryPath -Force -Recurse > $null
		}
	}
}
#endregion 
function Show-AllSelectedNone($allSelected, $collection, $separator, $allWording, $noneWording) {
if (-not $separator) { $separator = [char]10 }
if (-not $allWording) { $allWording = "(all)" }
if (-not $noneWording) { $noneWording = "(none)" }

    $result = ""
    if ($allSelected -eq $true) { 
        $result = $allWording 
    } 
    else {
        if (-not $collection) {
            $result = $noneWording
         } 
         #else {
         #   $result = ""
         #}

        ForEach ($item in $collection)
        {
            $valueToDisplay = $item.DisplayName
            if( $valueToDisplay.Trim().Length -eq 0 ) {
                $valueToDisplay = $item.Id.ToString()
            }
            $result +=  $separator + $valueToDisplay
        }        
    }
    
    if ($result.StartsWith($separator)) { $result = $result.Substring($separator.Length) }

    $result
}
function ConvertTo-Scriptblock { # https://www.thomasmaurer.ch/2011/11/powershell-convert-string-to-scriptblock/
Param(
[Parameter(
    Mandatory = $true,
    ParameterSetName = '',
    ValueFromPipeline = $true)]
    [string]$string=" "
)
    $scriptBlock = [scriptblock]::Create($string)
    return $scriptBlock
}
function InvokeCommandFromString ($scriptAsString, $computerName) {
    $scriptBlock = ConvertTo-Scriptblock $scriptAsString
    InvokeCommand $scriptBlock $computerName 
} 
function InvokeCommand ($scriptBlock, $computerName) {    
    if (-not $computerName -or $computerName -eq "localhost" -or $computerName -eq "127.0.0.1" -or $computerName -eq "$Env:COMPUTERNAME" -or $computerName -eq "$Env:COMPUTERNAME.$Env:USERDNSDOMAIN" `
    -or ((Get-NetIPAddress -AddressFamily IPv4 | Select-Object IPAddress) | ? { $_.IPAddress -eq $computerName }).IPAddress.Count -gt 0
    
     ) {
         Invoke-Command -ScriptBlock $scriptBlock 2>&1   # Caller should check if   -isnot [System.Management.Automation.ErrorRecord] 
    }
    else {
        Invoke-Command -ComputerName $computerName -ScriptBlock $scriptBlock 2>&1  # Caller should check if   -isnot [System.Management.Automation.ErrorRecord]
    }
}
function Run2ndOnlyIf1stSucceeds([scriptblock]$scriptBlock1, [scriptblock]$scriptBlock2) {

    $resultOf1 = Invoke-Command -ScriptBlock $scriptBlock1

    if ($resultOf1 -is [System.Management.Automation.ErrorRecord])  {
        $resultOf1
    }
    else { #Very IMPORTANT: $scriptBlock2  should "contain" exactly the variable   "$resultOf1"    if the "result" of $scriptBlock1  will be used inside.
        Invoke-Command -ScriptBlock $scriptBlock2 -ArgumentList $resultOf1
    }
}
function Abs($value) {
    $result = $null
    if ([double]::TryParse($value, [System.Globalization.NumberStyles]::Any, $null, [ref] $result)) {    
        [Math]::Abs($value)
    }
    else {
        $value
    }   
}
function WithThousandSeparators($numValue) {
    "{0:#,##0.##########}" -f $numValue
}
function InvokeCommand_AlwaysReturnOutput_ButOnlyWriteErrorToConsole([scriptblock]$scriptBlock) {
    $vNonSuccess=$null; 
    $vSuccess=$null; 
    Invoke-Command -ScriptBlock $scriptBlock -OutVariable vSuccess -ErrorVariable vNonSuccess | Out-Null; 
    if ($vNonSuccess.Count -eq 0) {
        $vSuccess
    } 
    else {
        $vNonSuccess
    };
}
function CalculateCollectorTimings($collectorFolder) {
    $firstFile = "CollectorVersion.txt"
    $firstFileFound = $false
    [datetime]$prevDateTime = [datetime]::MinValue

    $tbl = New-Object System.Data.DataTable "CollectorTimings"
    $col1 = New-Object System.Data.DataColumn Duration  # This is NOT calculated as File.LastWriteTime-CreationTime. It is the LastWriteTime diff between the current and previous file
    $col2 = New-Object System.Data.DataColumn EndTime
    $col3 = New-Object System.Data.DataColumn CreationTime
    $col4 = New-Object System.Data.DataColumn FileName
    $tbl.Columns.Add($col1)
    $tbl.Columns.Add($col2)
    $tbl.Columns.Add($col3)
    $tbl.Columns.Add($col4)

    $files = Get-ChildItem -Path $collectorFolder  -Recurse | Sort-Object -Property LastWriteTime 
    foreach($file in $files) {
        if ($file.Mode -like 'd*') {continue}
        if (!$firstFileFound) {
            if ($file.Name -eq $firstFile) {
                $firstFileFound = $true
                $prevDateTime = $file.LastWriteTime
            }
            else {
                continue;
            }
        }
        [timespan]$duration = $file.LastWriteTime - $prevDateTime
        $prevDateTime = $file.LastWriteTime

        $row = $tbl.NewRow()
        $row.Duration = $duration.ToString("dd\:hh\:mm\.ss\.fff")
        $row.CreationTime = $file.CreationTime.ToString("yyyy\-MM\-dd\_\_hh\:mm\.ss\.fff")
        $row.EndTime = $file.LastWriteTime.ToString("yyyy\-MM\-dd\_\_hh\:mm\.ss\.fff")
        $row.FileName = $file.Name

         $tbl.Rows.Add($row)
    }
    $tbl
} 

function StartProcessAsync($processFileName, $argsToProcess, $outputFileName="") {

#Start_Async -processFileName $processFileName -argsToProcess $argsToProcess -outputFileName $outputFileName

    $code = {
        #region Getting input params
        #because of:  https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_automatic_variables?view=powershell-5.1#input
        #and https://docs.microsoft.com/en-us/dotnet/api/system.collections.ienumerator?view=netframework-4.8#remarks
        if ($input.MoveNext()) { $inputs = $input.Current } else { return }  
        #endregion

        $processFileName, $argsToProcess = $inputs 

        $pinfo = New-Object System.Diagnostics.ProcessStartInfo
        $pinfo.FileName = $processFileName
        $pinfo.Arguments = $argsToProcess
        $pinfo.RedirectStandardError = $true
        $pinfo.RedirectStandardOutput = $true
        $pinfo.UseShellExecute = $false
        $p = New-Object System.Diagnostics.Process
        $p.StartInfo = $pinfo
        $p.Start() | Out-Null
        $p.WaitForExit()
        $output = $p.StandardOutput.ReadToEnd()
        $output += $p.StandardError.ReadToEnd()
        $output 
    }
    $jobParams = @($processFileName, $argsToProcess)
    Start_Async -code $code -inputObject $jobParams -outputFileName $outputFileName

return

    $outputFileName = $outputFileName.Trim()
    if ($outputFileName.Length -gt 0) {
        $outputFileName = $preFix_SaveTo + $outputFileName
    }

    $jobParams = @($processFileName, $argsToProcess)

    Start-Job -ScriptBlock {

        #region Getting input params
        #because of:  https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_automatic_variables?view=powershell-5.1#input
        #and https://docs.microsoft.com/en-us/dotnet/api/system.collections.ienumerator?view=netframework-4.8#remarks
        if ($input.MoveNext()) { $inputs = $input.Current } else { return }  
        #endregion

        $processFileName, $argsToProcess = $inputs 

        $pinfo = New-Object System.Diagnostics.ProcessStartInfo
        $pinfo.FileName = $processFileName
        $pinfo.Arguments = $argsToProcess
        $pinfo.RedirectStandardError = $true
        $pinfo.RedirectStandardOutput = $true
        $pinfo.UseShellExecute = $false
        $p = New-Object System.Diagnostics.Process
        $p.StartInfo = $pinfo
        $p.Start() | Out-Null
        $p.WaitForExit()
        $output = $p.StandardOutput.ReadToEnd()
        $output += $p.StandardError.ReadToEnd()
        $output 

    } -Name $outputFileName -InputObject $jobParams | Out-Null
}
function StartScriptBlock_Async([scriptblock]$code, $inputObject, [scriptblock]$initializationScript, $outputFileName="") {

Start_Async -code $code -inputObject $inputObject -initializationScript $initializationScript -outputFileName $outputFileName
return

    $outputFileName = $outputFileName.Trim()
    if ($outputFileName.Length -gt 0) {
        $outputFileName = $preFix_SaveTo + $outputFileName
    }

    Start-Job -ScriptBlock $code -InputObject $inputObject -Name $outputFileName -InitializationScript $initializationScript | Out-Null
}

function GetFunctionDeclaration($functionName) {
    $result = "function $functionName {`n"
    $result += ( Get-Command -Name $functionName ).Definition
    $result += "}`n"
    $result
}

function Start_Async {
    [CmdletBinding()]
    param (

        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'Program',
            HelpMessage = 'Enter the path to the Program executable')
        ]
        [string]$processFileName,

        [Parameter(
            Mandatory = $false,
            ParameterSetName = 'Program',
            HelpMessage = 'Enter arguments (as a string array) to pass to the Program')
        ]
        [string[]]$argsToProcess,


        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'ScriptBlock',
            HelpMessage = 'Enter the PS script block to run')
        ]
        [scriptblock]$code,

        [Parameter(
            Mandatory = $false,
            ParameterSetName = 'ScriptBlock',
            HelpMessage = 'Enter an array (usually of strings) to be used inside the Script Block')
        ]
        $inputObject,

        [Parameter(
            Mandatory = $false,
            ParameterSetName = 'ScriptBlock',
            HelpMessage = 'Enter the function names refered in the script block')
        ]
        [string[]]$initializationScript=@(),

        [Parameter(
            Mandatory = $false,
            ParameterSetName = 'Program',
            HelpMessage = 'Enter the file name into which the outputs will be appended')
        ]
        [Parameter(
            Mandatory = $false,
            ParameterSetName = 'ScriptBlock',
            HelpMessage = 'Enter the file name into which the outputs will be appended')
        ]
        [string]$outputFileName=""
    )

    $outputFileName = $outputFileName.Trim()
    if ($outputFileName.Length -gt 0) {
        $outputFileName = $preFix_SaveTo + $outputFileName
    }

    if ($processFileName) {

        $jobParams = @($processFileName, $argsToProcess)

        Start-Job -ScriptBlock {

            #region Getting input params
            #because of:  https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_automatic_variables?view=powershell-5.1#input
            #and https://docs.microsoft.com/en-us/dotnet/api/system.collections.ienumerator?view=netframework-4.8#remarks
            if ($input.MoveNext()) { $inputs = $input.Current } else { return }  
            #endregion

            $processFileName, $argsToProcess = $inputs 

            $pinfo = New-Object System.Diagnostics.ProcessStartInfo
            $pinfo.FileName = $processFileName
            $pinfo.Arguments = $argsToProcess
            $pinfo.RedirectStandardError = $true
            $pinfo.RedirectStandardOutput = $true
            $pinfo.UseShellExecute = $false
            $p = New-Object System.Diagnostics.Process
            $p.StartInfo = $pinfo
            $p.Start() | Out-Null
            $p.WaitForExit()
            $output = $p.StandardOutput.ReadToEnd()
            $output += $p.StandardError.ReadToEnd()
            $output 

        } -Name $outputFileName -InputObject $jobParams | Out-Null
    }
    else {
        [string]$initializationScriptAsString = if ($initializationScript) {
            [string]::Join("", $initializationScript)
        }
        else {
            " "
        }
        [scriptblock]$initializationScriptAsScriptBlock = [scriptblock]::Create($initializationScriptAsString)
        Start-Job -ScriptBlock $code -InputObject $inputObject -Name $outputFileName -InitializationScript $initializationScriptAsScriptBlock | Out-Null    
    }

}

function GetFilesInfoFromDirectory($pStartingPath) {
   Get-ChildItem -Path $pStartingPath -Recurse -Force | Select-Object Length, lastwritetimeutc, @{Name="Version";Expression={$_.VersionInfo.ProductVersion}}, FullName | ConvertTo-Csv -NoTypeInformation
}

function RamSB([scriptblock]$pscriptBlock, [string]$phase, [string]$outputString) # Ram is abbreviation of: Run and measure. Requires script block
{   
#IMPORTANT: Do NOT forget to send the $pscriptBlock inside curly brackets {} at the CALLER code    or   with [scriptblock]::Create() as done in Ram()

    if (!$phase -or $phase -eq "") {
        $phase = "Collector"
    }
    $fileName = "$phase-MeasuredScriptBlocks.csv"
    $startTime = [datetime]::Now.ToString("yyyy\-MM\-dd\_\_hh\:mm\.ss\.fff")
    $timeElapsed = (Measure-Command -Expression $pscriptBlock).ToString("hh\:mm\:ss\.fff")
    if ($outputString -and $outputString -ne "") {
        $pscriptBlockText = $outputString
    }
    else {
        $pscriptBlockText = $pscriptBlock.ToString()
    }
    $EndTime = [datetime]::Now.ToString("yyyy\-MM\-dd\_\_hh\:mm\.ss\.fff")

    $lineToAdd = """$timeElapsed"",""$EndTime"",""$startTime"",""$pscriptBlockText"""
    AppendOutputToFileInTargetFolder $lineToAdd $fileName
}

function Ram([string]$pscriptBlockText, [string]$phase, [string]$outputString) #   Ram is abbreviation of: Run and measure. Requires script block as string
{  
    [scriptblock]$pscriptBlock = [scriptblock]::Create($pscriptBlockText)
    RamSB -pscriptBlock $pscriptBlock -phase $phase -outputString $outputString
}

function GetInternetAvailability() {
    try {        
        $internetAvailable = InvokeWebRequest_WithProxy -Uri 'https://www.microsoft.com' -timeoutSec 5

        if ($internetAvailable -and $internetAvailable.StatusCode -eq 200) {
            AppendOutputToFileInTargetFolder 'Yes' InternetAvailable.txt
        }
    }
    catch {
        AppendOutputToFileInTargetFolder 'No' InternetAvailable.txt
    }
}

function GetProxy($uri) { #https://learn.microsoft.com/en-us/dotnet/api/system.net.iwebproxy.getproxy?view=netframework-4.8.1#examples
    $wpi = [System.Net.WebRequest]::GetSystemWebProxy()
    $wpi.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
    
    $webProxyServer = $null

    if ( !$wpi.IsBypassed($uri) ) {
        $webProxyServer = $wpi.GetProxy($uri);

        if ( (!$webProxyServer -or $webProxyServer -ne $null ) -and $webProxyServer -eq $uri) {
            $webProxyServer = $null
        }       
    }
    [bool]$proxyUseDefaultCredentials = ($webProxyServer -ne $null)

    @($webProxyServer,$proxyUseDefaultCredentials)
}
function InvokeWebRequest_WithProxy($uri, $timeoutSec=0, [switch]$useBasicParsing=$true, [switch]$useDefaultCredentials=$true, [string]$outFile=$null) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 
    $webProxyServer,$proxyUseDefaultCredentials = GetProxy($uri)    
    Invoke-WebRequest -Uri $uri -UseBasicParsing:$useBasicParsing -TimeoutSec $timeoutSec -UseDefaultCredentials:$useDefaultCredentials -Proxy $webProxyServer -ProxyUseDefaultCredentials:$proxyUseDefaultCredentials -OutFile $outFile | Out-Null
}
function InvokeRestMethod_WithProxy($uri, $body, $timeoutSec=0) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 
    $webProxyServer,$proxyUseDefaultCredentials = GetProxy($uri)   
    Invoke-RestMethod -Method Post -Uri $uri -Body $body -TimeoutSec $timeoutSec -UseBasicParsing -ContentType "application/json" -UseDefaultCredentials -Proxy $webProxyServer -ProxyUseDefaultCredentials:$proxyUseDefaultCredentials | Out-Null
}

function ImportSmModule() {
    if (!(Get-Module System.Center.Service.Manager)) {    
        Import-Module ((Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\System Center\2010\Service Manager\Setup').InstallDirectory +'PowerShell\' +'System.Center.Service.Manager.psd1') -force 
    }
}
function ImportSmDwModule() {
    if (-not (Get-Module -name Microsoft.EnterpriseManagement.Warehouse.Cmdlets)) {
        Import-Module ((Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\System Center\2010\Service Manager\Setup').InstallDirectory  +'Microsoft.EnterpriseManagement.Warehouse.Cmdlets.psd1') -Force 
    }
}

function CreateScriptVariableIfNotYet($varName, $initValueIfNotExist) {
    $var = Get-Variable -Name $varName -Scope Script -ErrorAction SilentlyContinue
    if (!$var) {
         New-Variable -Name $varName -Scope Script -Value $initValueIfNotExist
    }
}

function GetAllFunctionDeclarations([string[]]$Except) {

    CreateScriptVariableIfNotYet -varName allFunctionDeclarations -initValueIfNotExist ""

    if($script:allFunctionDeclarations -eq "") {
        [string]$result = ""    
        $fns = (Get-Command -CommandType Function | ? { !$_.Source } | Select-Object -Property Name)

        foreach($fn in $fns) {
            if ($Except -contains $fn.Name) { continue }
            $result += GetFunctionDeclaration -functionName $fn.Name
        }
    
        if($script:allFunctionDeclarations -eq "") { 
            $script:allFunctionDeclarations = $result
        }
    }
    return $script:allFunctionDeclarations 
}

function RunAsync([scriptblock]$code, [hashtable]$vars) {

    $TempFileName = ([guid]::NewGuid()).ToString() + ".ps1";
    AppendOutputToFileInTargetFolder (GetAllFunctionDeclarations) $TempFileName

    if ($vars) {
        AppendOutputToFileInTargetFolder 'if ($input.MoveNext()) { $inputs = $input.Current } else { return }' $TempFileName

        $inputObjectHandler = @'        
        foreach($v in $inputs.Keys) {
            New-Variable -Name $v -Value $inputs[$v]
        }
'@
        AppendOutputToFileInTargetFolder $inputObjectHandler $TempFileName
    }

    AppendOutputToFileInTargetFolder $code $TempFileName
    $TempFileFullName = (GetFileNameInTargetFolder $TempFileName)
    AppendOutputToFileInTargetFolder "Remove-Item -Path '$TempFileFullName'" $TempFileName

    Start-Job -FilePath $TempFileFullName -InputObject $vars | Out-Null
}

function LogStatInfo([xml]$statInfoXml, [string]$sentBy) {    
    $statInfoXml.DocumentElement.SetAttribute("SentBy",$sentBy)
    $statInfoXmlString = $statInfoXml.OuterXml
    $body = ""
    try {
        $ms = New-Object System.IO.MemoryStream
        $cs = New-Object System.IO.Compression.GZipStream($ms, [System.IO.Compression.CompressionMode]::Compress)
        $sw = New-Object System.IO.StreamWriter($cs)
        $sw.Write($statInfoXmlString)
        $sw.Close();
        $statInfo = [System.Convert]::ToBase64String($ms.ToArray())

        $uri = "https://forms.office.com/formapi/api/72f988bf-86f1-41af-91ab-2d7cd011db47/groups/5ea18668-1df0-42b7-b3ef-ecdf1df4110b/forms('v4j5cvGGr0GRqy180BHbR2iGoV7wHbdCs-_s3x30EQtUOUhCQUNSQlNFMURRSkg2WjRMWEZEVzA1TyQlQCN0PWcu')/responses"
        $questionIDs = "r14f509ca5b734d3f9ed292e42acb011a","rf9b227915ae54f8d93d0206ee3210fa4","rd84c67987a6b46d1a9a63e5cc6511673","r75eaa58db25f4de992382ccbd5ae8d29","rf2e073ae17de40c2acfc126df96a6f12","rad0902e642e642e7adfa57d356af4a0a","r680f515af201463ebc6d6351d8b0f4f6","r3b0a6b63bc0641539ac6e09ac0ca0261","rc0adee71a32a4df0a5e6a4860e298372","r9a610a66fbb4403198599304ef9672dd","ra2d31dc706404b89971f6e4fdeec1660","rcd7ef7efecbe44309604c220eaf764ae","r681b9195ebd747678afc91ba1fca550a","r2a5259256bd747aca01c0ef97dcb4f89","r54744977d244425c980bcce9f9c4815e","r32cda0df62b240559e4549de6001a5fd","r341435b595bf4a73bd9aeb5f02f6f4c9","rec80bae2f680412984105a1653a395be","rf940f378876c46f88f6369fa744c6d24","rb11cda7c23124ed1a84825b2b639cdc5","r6aaf378ae130414ca9b82e0b962d4091","r20e2d35ffb764da1bc6ea57ce6c719bb","r50ad1aefa9e44974b3e68e4d37a52c82","r2365651122d34739ab89c206cab694b1","r61df2ecc323943d2a66ce4102e1e2589","r8dfc22761f1d4242ba0707a6ba99616d","r28eb66652ac445548895d9e71f385026","rd3ba560f279746568328659639264146","rde2045a22ca0481fb9f3fcda5f0f0e71","r80f495dc4fa44bdabbbc81007f7ae8f5","r4a61a52cfccd4ca084fb2bb43b303ba6","r1276cf9ab0734434a761e86ca42cdb1e","ra8c8729ffe3a4c38a9c61b746a70f8a5","r30c1f9fccf034e919fdea48b2ceedd89","r0802c6d952014ea29d80a2cc52ac6515","r36dcbfd13526475db4795664a34998f4","r30c43540200e4f88b5af94b5a73aa2bd","r70b8ea90a49949e8b8fe19cca077e94c","r7458f57b4713469fa0482f83489a0734","raec9bf88600c4b9dbda88f954856b137","raff6e5fcee1c45ed8485bdadb6cfaf6f","r3df52174834e40fb9676a147aebbbfeb","rcd0a646ec5f6455b89c9d946b3be8170","r954183c1808a4de9966bfc18b32d6cf2","rcd3d2c99be7642f092bd78bb2c03cd1c","r75e14134a3b944289262907f063bac48","r31dcecd7d60a46e8b410990d357c814f","r3c42754a21aa4cd2981daeb73ca398ec","r6e04640a043e4e0f89ac03a2f43c5c67","r0d4cfd7cdc7f44f3a377558fb9195a54"

        $maxCharsPerQuestion = 4000
        $bodyStart ='{"answers":"['
        $startPos = 0
        $answers = ""
        $isFirst = $true
        foreach($questionID in $questionIDs) {
            $subStringLength = $maxCharsPerQuestion
            if ($startPos + $subStringLength -gt $statInfo.Length) { 
                if ($startPos -gt $statInfo.Length) {
                    $answer = ""
                }
                else {
                    $answer = $statInfo.Substring($startPos)
                }
            }
            else {
                $answer = $statInfo.Substring($startPos, $subStringLength)
            }
            if ($isFirst) { $isFirst = $false } else { $answers += "," }
            $answers += "{\`"questionId\`":\`"$questionID\`",\`"answer1\`":\`"$answer\`"}"
            $startPos += $maxCharsPerQuestion
        }    
        $bodyEnd = ']"}'
        $body =  "$bodyStart$answers$bodyEnd"

        InvokeRestMethod_WithProxy -uri $uri -body $body -timeoutSec 20
    } catch { }     
}

function InitStatInfo() {
    CreateScriptVariableIfNotYet -varName statInfo -initValueIfNotExist ""
    $script:statInfo = [xml]::new()
    (GetStatInfo).AppendChild(  (CreateElementForStatInfo StatInfo)  )
    
    (GetStatInfoRoot).SetAttribute("SmdtRunVersion", (GetToolVersion) )
    CreateScriptVariableIfNotYet -varName smdtRunId -initValueIfNotExist ( [guid]::NewGuid().ToString() )
    (GetStatInfoRoot).SetAttribute("SmdtRunId",      $smdtRunId )
}

function GetStatInfo() { 
    $script:statInfo
}
function GetStatInfoRoot() { 
    (GetStatInfo).DocumentElement  #should return StatInfo
}
function GetSmEnvInStatInfo() {
    GetNodeInStatInfo -parentNode (GetStatInfoRoot) -subNodeName SmEnv  # do NOT use (GetStatInfoRoot).SmEnv, bcz if SmEnv has no child, that would return a String! https://stackoverflow.com/questions/19245359/how-to-add-a-child-element-for-xml-in-powershell
}

function GetNodeInStatInfo($parentNode, $subNodeName) {
    $parentNode.SelectSingleNode($subNodeName)
}
function AddToStatInfoRoot($newElem) {    
    (GetStatInfoRoot).AppendChild($newElem) | Out-Null
}
function CreateElementForStatInfo($elemTagName) {
    (GetStatInfo).CreateNode([System.Xml.XmlNodeType]::Element, $elemTagName, $null) 
}

function IsFileSignedByMicrosoft($filePath) {
    $sgn = Get-AuthenticodeSignature $filePath
    if ($sgn.Status -ne [System.Management.Automation.SignatureStatus]::Valid) { return $false }
    if ($sgn.SignerCertificate.Subject -notlike 'CN=Microsoft Corporation, *') { return $false }
    return $true
}
function AmIRunningAsSigned() {
    IsFileSignedByMicrosoft $scriptFilePath
}

function ConvertUpnToDomainUsername($upn) {
    $ADS_NAME_INITTYPE_GC = 3
    $UNKNOWN = 8
    $NT4NAME = 3
    $ns=New-Object -ComObject NameTranslate
    [System.__ComObject].InvokeMember("init","InvokeMethod",$null,$ns,($ADS_NAME_INITTYPE_GC,$null))
    [System.__ComObject].InvokeMember("Set","InvokeMethod",$null,$ns,($UNKNOWN,$upn))
    [System.__ComObject].InvokeMember("Get","InvokeMethod",$null,$ns,$NT4NAME)
}
#endregion
