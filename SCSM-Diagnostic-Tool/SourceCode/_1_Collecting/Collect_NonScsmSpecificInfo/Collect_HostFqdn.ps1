function Collect_HostFqdn() {
    AppendOutputToFileInTargetFolder ([System.Net.Dns]::GetHostByName($env:computerName).HostName) Hostname_fqdn.txt
}