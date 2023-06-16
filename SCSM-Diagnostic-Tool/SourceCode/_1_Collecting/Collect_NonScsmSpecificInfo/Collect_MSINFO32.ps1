function Collect_MSINFO32() {
#Starting MSINFO32 in the background and hide it after 2 seconds
 
    Start-Job -ScriptBlock {

        $win32 = Add-Type -Namespace Win32 -Name Funcs -PassThru -MemberDefinition @'
            [DllImport("user32.dll", CharSet = CharSet.Auto)]
            public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);

            [DllImport("user32.dll", CharSet = CharSet.Auto)]
            public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
'@
        $SW_HIDE = 0;

        $p = Start-Process msinfo32.exe -PassThru -ArgumentList $input

        Start-Sleep -Seconds 2
        $hWnd = $win32::FindWindow( '#32770', "System Information")
        if ($hWnd -ne 0) {
            $win32::ShowWindow($hWnd, $SW_HIDE)
        }
        $p.WaitForExit()

    } -InputObject  "/report ""$((GetFileNameInTargetFolder "msinfo32.txt"))""" | Out-Null
}