function SelfElevate($versionUpdated) {
    $arg_noSelfUpdate   = if ($Script:MyInvocation.UnboundArguments.Contains("-noSelfUpdate"))   {""}                else {"-noSelfUpdate"}
    $arg_acceptEula     = if ($Script:MyInvocation.UnboundArguments.Contains("-acceptEula"))     {"-acceptEula"}     else {""}
    $arg_nonInteractive = if ($Script:MyInvocation.UnboundArguments.Contains("-nonInteractive")) {"-nonInteractive"} else {""}

    if ( $versionUpdated -or
        -Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
        
        $CommandLine = "-ExecutionPolicy Bypass $arg_nonInteractive -File `"" + $Script:MyInvocation.MyCommand.Path + "`" $arg_noSelfUpdate $arg_acceptEula" # + $Script:MyInvocation.UnboundArguments
        Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
        Exit
    }
}