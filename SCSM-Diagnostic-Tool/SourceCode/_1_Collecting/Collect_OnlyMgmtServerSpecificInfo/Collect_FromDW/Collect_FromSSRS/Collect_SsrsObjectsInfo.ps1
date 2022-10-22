function Collect_SsrsObjectsInfo() {
    $Proxy = New-WebServiceProxy -Uri $SsrsUrl -Namespace SSRS.ReportingService2005 -UseDefaultCredential
    $ssrsItems = $Proxy.ListChildren('/' , $true) | Select-Object ID, Name, Path, Type, Hidden, CreatedBy, CreationDate, ModifiedBy, ModifiedDate, MimeType | select *, InheritsParentSecurity, EffectivePermissions    
    [System.Collections.ArrayList]$ssrsItemsArrayList=$ssrsItems
    $ssrsRootObj = [PSCustomObject]@{
        Id = ''
        Name = ''
        Path = '/'
        Type = ''
        Hidden = ''
        CreatedBy = ''
        CreationDate = ''
        ModifiedBy = ''
        ModifiedDate = ''
        MimeType = ''
        InheritsParentSecurity = ''
        EffectivePermissions = ''#($Proxy.GetPolicies('/',[ref]$true))
    }
    $ssrsItemsArrayList.Insert(0,$ssrsRootObj)    
    foreach ($ssrsItem in  $ssrsItemsArrayList)
    {
        $InheritsParent = $null
        $TempFileName = ([guid]::NewGuid()).ToString()    
        AppendOutputToFileInTargetFolder ($Proxy.GetPolicies($ssrsItem.Path,[ref]$InheritsParent) ) $TempFileName
        $ssrsItem.InheritsParentSecurity = $InheritsParent
        $ssrsItem.EffectivePermissions =  ( GetFileContentInTargetFolder $TempFileName )
        DeleteFileInTargetFolder $TempFileName 
    }
    AppendOutputToFileInTargetFolder ( $ssrsItemsArrayList | ConvertTo-Csv -NoTypeInformation ) "Ssrs-AllItems.csv"
}