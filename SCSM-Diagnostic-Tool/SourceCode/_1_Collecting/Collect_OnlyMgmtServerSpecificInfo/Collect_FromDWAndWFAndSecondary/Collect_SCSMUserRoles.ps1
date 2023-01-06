﻿function Collect_SCSMUserRoles_Async() {
    
    $initializationScript = ""    

    $initializationScript += GetFunctionDeclaration Collect_SCSMUserRoles
    $initializationScript += GetFunctionDeclaration Show-AllSelectedNone
        $initializationScript += @"
    if (!(Get-Module System.Center.Service.Manager)) {    
            Import-Module ((Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\System Center\2010\Service Manager\Setup').InstallDirectory +'PowerShell\' +'System.Center.Service.Manager.psd1') -force 
    }
"@
    $initializationScript += GetFunctionDeclaration Try-Invoke-SqlCmd
        $initializationScript += GetFunctionDeclaration Invoke-AlternativeSqlCmd_WithoutTimeout
        $initializationScript += GetFunctionDeclaration Invoke-AlternativeSqlCmd_WithTimeout
    $initializationScript += GetFunctionDeclaration AppendOutputToFileInTargetFolder

#   $initializationScript = ConvertTo-Scriptblock $initializationScript
    $code = {

        if ($input.MoveNext()) { $inputs = $input.Current } else { return }  
        $SQLInstance_SCSM, $SQLDatabase_SCSM, $resultFolder = $inputs 
     
        Collect_SCSMUserRoles 
     }

    $inputObject = @($SQLInstance_SCSM, $SQLDatabase_SCSM, $resultFolder)

#    StartScriptBlock_Async -code $code -initializationScript $initializationScript -inputObject $inputObject
Start_Async -code $code -inputObject $inputObject -initializationScript $initializationScript
}

function Collect_SCSMUserRoles() {
# SCSM User Roles  with ALL Details
    $roles = Get-SCSMUserRole | Sort-Object -Property DisplayName
    $tbl = New-Object System.Data.DataTable "UserRoles"
    
    $col1 = New-Object System.Data.DataColumn DisplayName
    $col2 = New-Object System.Data.DataColumn Queues
    $col3 = New-Object System.Data.DataColumn ConfigurationItemGroups
    $col4 = New-Object System.Data.DataColumn CatalogItemGroups
    $col5 = New-Object System.Data.DataColumn Tasks
    $col6 = New-Object System.Data.DataColumn Views
    $col7 = New-Object System.Data.DataColumn FormTemplates
    $col8 = New-Object System.Data.DataColumn Users
    $col9 = New-Object System.Data.DataColumn Profile
    $col10 = New-Object System.Data.DataColumn LastModified
    $col11 = New-Object System.Data.DataColumn LastModifiedBy

    $tbl.Columns.Add($col1)
    $tbl.Columns.Add($col2)
    $tbl.Columns.Add($col3)
    $tbl.Columns.Add($col4)
    $tbl.Columns.Add($col5)
    $tbl.Columns.Add($col6)
    $tbl.Columns.Add($col7)
    $tbl.Columns.Add($col8)
    $tbl.Columns.Add($col9)
    $tbl.Columns.Add($col10)
    $tbl.Columns.Add($col11)

    foreach($role in $roles) {
        $row = $tbl.NewRow()

        $row.DisplayName = $role.DisplayName
        $row.Queues = Show-AllSelectedNone $role.AllQueues $role.Queue
        $row.ConfigurationItemGroups = Show-AllSelectedNone $role.AllGroups $role.Group
        $row.CatalogItemGroups = Show-AllSelectedNone $role.AllCatalogGroups $role.CatalogGroup
        $row.Tasks = Show-AllSelectedNone $role.AllTasks $role.Task
        $row.Views = Show-AllSelectedNone $role.AllViews $role.View
        $row.FormTemplates = Show-AllSelectedNone $role.AllFormTemplates $role.FormTemplate
        $row.Users = [string]( $role.User | %{ $_ + [char]10 } )
        $row.LastModified = $role.LastModified
        $row.LastModifiedBy = $role.LastModifiedBy

        $dsUserRole = Try-Invoke-SqlCmd -SQLInstance $SQLInstance_SCSM  -SQLDatabase $SQLDatabase_SCSM -Query "SELECT (select ProfileName from Profile where ProfileId = UserRole.ProfileId) as ProfileName FROM UserRole where UserRoleName = '$($role.UserRole.ToString())'"
        $row.Profile = $dsUserRole.Tables[0].ProfileName

        $tbl.Rows.Add($row)
    }
    AppendOutputToFileInTargetFolder (  $tbl | ConvertTo-Csv -NoTypeInformation) Get-SCSMUserRole_WithAllDetails.csv
}
