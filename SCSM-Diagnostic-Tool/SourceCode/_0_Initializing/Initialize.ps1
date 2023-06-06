function Initialize() {

    $versionUpdated = SelfUpdate 

    SelfElevate $versionUpdated
    
    #region EULA
    if (-not (IsEulaAccepted)) {
        Write-Host "End User License Agreement has been declined. Aborting." -ForegroundColor DarkGray
        return $false
    }
    #endregion
    
    InitStatInfo

    return $true
}