function Collect_FromSSAS() {
    #region DO NOT MOVE THIS! To be used in subsequent functions
    $SsasInfo = (Try-Invoke-SqlCmd -SQLInstance $SQLInstance_SCSMDW -SQLDatabase $SQLDatabase_SCSMDW -Query 'select Server_48B308F9_CF0E_0F74_83E1_0AEB1B58E2FA as SsasServerName,DataService_98B2DDF9_D9FD_9297_85D3_FCF36F1D016B as SsasDBName from MT_Microsoft$SystemCenter$ResourceAccessLayer$ASResourceStore').Tables[0]    
    [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.AnalysisServices") > $NULL
    $Server = New-Object Microsoft.AnalysisServices.Server
    $Server.Connect("Data source=$($SsasInfo.SsasServerName)") 
    $SsasDB=$Server.Databases["$($SsasInfo.SsasDBName)"] 
    #endregion SSAS  

    Collect_SsasDB
    Collect_SsasCubes
    Collect_SsasDimensions
    Collect_SsasDataSourceViews
    Collect_SsasDataSources
}