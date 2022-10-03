function Initialize() {

    SelfUpdate #TODO

    SelfElevate
    
    #region EULA
    if (-not (IsEulaAccepted)) {
        Write-Host "End User License Agreement has been declined. Aborting." -ForegroundColor DarkGray
        return $false
    }
    #endregion

    return $true
}