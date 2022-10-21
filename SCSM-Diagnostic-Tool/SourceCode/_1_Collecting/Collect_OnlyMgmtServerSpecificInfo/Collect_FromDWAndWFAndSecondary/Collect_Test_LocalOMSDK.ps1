function Collect_Test_LocalOMSDK() {
    AppendOutputToFileInTargetFolder (Test-NetConnection -ComputerName localhost -Port 5724) Telnet_localhost_5724.txt
    AppendOutputToFileInTargetFolder (Test-Connection -ComputerName localhost | ft -Wrap -Autosize ) Ping_localhost_5724.txt
}