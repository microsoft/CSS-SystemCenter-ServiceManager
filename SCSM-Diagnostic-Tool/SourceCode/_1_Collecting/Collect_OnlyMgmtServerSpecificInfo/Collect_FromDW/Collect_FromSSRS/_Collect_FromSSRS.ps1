function Collect_FromSSRS() {
    #region DO NOT MOVE THIS! To be used in subsequent functions
    $SsrsUrl = (Try-Invoke-SqlCmd -SQLInstance $SQLInstance_SCSMDW -SQLDatabase $SQLDatabase_SCSMDW -Query 'select DataService_98B2DDF9_D9FD_9297_85D3_FCF36F1D016B as SsrsUrl from MT_Microsoft$SystemCenter$ResourceAccessLayer$SrsResourceStore').Tables[0].SsrsUrl
    #endregion

    Collect_Test_SsrsWebService
    Collect_SsrsVersion
    Collect_SsrsObjectsInfo
}