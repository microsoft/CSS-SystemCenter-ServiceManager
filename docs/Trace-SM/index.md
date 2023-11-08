# Trace-SM
Download the latest release: [Trace-SM.ps1]({{ site.latestDownloadLink }}/Trace-SM.ps1)   

## Description
Trace-SM.ps1 can be used to collect trace files which will be used by Microsoft Support in troubleshooting. Usually, instructions will be provided by the Microsoft support engineer.

## Purpose
To easily collect (start/stop) and format SCSM specific traces. 

## How to run
1. Save the script Trace-SM.ps1 on a machine where any SCSM component is installed.
1. Open a Windows PowerShell window as an Administrator (PowerShell ISE can also be used).
1. Navigate to the folder where you saved the script.
2. Run the script as below:  
   .\Trace-SM.ps1

## Parameters
- *-TraceOperation* (optional)  
  - *ShowStatus* -> this is the default operation, shows current trace status.
  - *Start* -> starts traces. Stops them if already running and moves them to a new subfolder.
  - *Stop* -> stops traces.
  - *StopAndFormat* -> stops traces and then starts formatting them.  
   
- -*MaxFileSizeMB* (optional, only effective with the Start operation)
  - Can be set to a numeric value in MBytes. Default is 100 MB.
    
- -*NewFileWhenMaxsizeReached* (optional, only effective with the Start operation)
  - Default is circular file tracing. Old trace info is overridden when max file size is reached.  
  When this switch is provided then old trace info will be retained because a new trace file will be created everytime when max file size is reached.
    
- *Areas* (optional, only effective with the Start operation)
  - If not set, the default is to trace all "areas" which are Default, SDK, ConsoleUI, Connectors, DataWarehouse, Workflows, PortalSSP, Performance. To start only specific areas provide their names as comma delimited.

## Examples
- ### To show current trace status
```
.\Trace-SM.ps1
```
or
```
.\Trace-SM.ps1 ShowStatus
```
or
```
.\Trace-SM.ps1 -TraceOperation ShowStatus
```

Sample Output
```
SCSM Trace    Status  ETL Max File size (MB) Is ETL Circular? Etl file Location                        
----------    ------  ---------------------- ---------------- -----------------                        
Default       Running                    100             True C:\Windows\temp\SMTrace\Default.etl      
SDK           Running                    100             True C:\Windows\temp\SMTrace\SDK.etl          
ConsoleUI     Running                    100             True C:\Windows\temp\SMTrace\ConsoleUI.etl    
Connectors    Running                    100             True C:\Windows\temp\SMTrace\Connectors.etl   
DataWarehouse Running                    100             True C:\Windows\temp\SMTrace\DataWarehouse.etl
Workflows     Running                    100             True C:\Windows\temp\SMTrace\Workflows.etl    
PortalSSP     Running                    100             True C:\Windows\temp\SMTrace\PortalSSP.etl    
Performance   Running                    100             True C:\Windows\temp\SMTrace\Performance.etl  
```

- ### To start all SCSM traces
```
.\Trace-SM.ps1 Start
```
or
```
.\Trace-SM.ps1 -TraceOperation Start
```
Sample Output (note that existing traces are retained by moving then into a sub folder)
```
Stopping SCSM traces ...
Stopping Default ...
Stopping SDK ...
Stopping ConsoleUI ...
Stopping Connectors ...
Stopping DataWarehouse ...
Stopping Workflows ...
Stopping PortalSSP ...
Stopping Performance ...
ETL files already exist in C:\Windows\temp\SMTrace. Moving them into OldTracesStoppedAtUtc_2023-11-08__15.14.32.343
Starting SCSM traces ...
Starting Default ...
Starting SDK ...
Starting ConsoleUI ...
Starting Connectors ...
Starting DataWarehouse ...
Starting Workflows ...
Starting PortalSSP ...
Starting Performance ...

SCSM Trace    Status  ETL Max File size (MB) Is ETL Circular? Etl file Location
----------    ------  ---------------------- ---------------- -----------------
Default       Running                    100             True C:\Windows\temp\SMTrace\Default.etl
SDK           Running                    100             True C:\Windows\temp\SMTrace\SDK.etl
ConsoleUI     Running                    100             True C:\Windows\temp\SMTrace\ConsoleUI.etl
Connectors    Running                    100             True C:\Windows\temp\SMTrace\Connectors.etl
DataWarehouse Running                    100             True C:\Windows\temp\SMTrace\DataWarehouse.etl
Workflows     Running                    100             True C:\Windows\temp\SMTrace\Workflows.etl
PortalSSP     Running                    100             True C:\Windows\temp\SMTrace\PortalSSP.etl
Performance   Running                    100             True C:\Windows\temp\SMTrace\Performance.etl
```
    
- ### To stop all SCSM traces
```
.\Trace-SM.ps1 Stop
```
or
```
.\Trace-SM.ps1 -TraceOperation Stop
```
Sample Output
```
Stopping SCSM traces ...
Stopping Default ...
Stopping SDK ...
Stopping ConsoleUI ...
Stopping Connectors ...
Stopping DataWarehouse ...
Stopping Workflows ...
Stopping PortalSSP ...
Stopping Performance ...

SCSM Trace    Status  ETL Max File size (MB) Is ETL Circular? Etl file Location
----------    ------  ---------------------- ---------------- -----------------
Default       Stopped
SDK           Stopped
ConsoleUI     Stopped
Connectors    Stopped
DataWarehouse Stopped
Workflows     Stopped
PortalSSP     Stopped
Performance   Stopped
```

- ### To stop all SCSM traces and start formatting
```
.\Trace-SM.ps1 StopAndFormat
```
or
```
.\Trace-SM.ps1 -TraceOperation StopAndFormat
```
Sample Output (note that while formatting is running in a separate command window, this command is blocked)
```
Stopping SCSM traces ...
Stopping Default ...
Stopping SDK ...
Stopping ConsoleUI ...
Stopping Connectors ...
Stopping DataWarehouse ...
Stopping Workflows ...
Stopping PortalSSP ...
Stopping Performance ...
Formatting all ETL files in C:\Windows\temp\SMTrace, this can take a few minutes, please wait ...
Formatting completed. Press ENTER to navigate to the SCSM Trace folder ...
```

- ### To start a specific trace in non-circular mode and with a size greater than 100MB
```
.\Trace-SM.ps1 -TraceOperation Start -MaxFileSizeMB 250 -NewFileWhenMaxsizeReached -Areas Connectors
```
Sample Output (note that the ETL file name has a number which will increase if max file is reached)
```
Stopping SCSM traces ...
Stopping Connectors ...
Starting SCSM traces ...
Starting Connectors ...

SCSM Trace Status  ETL Max File size (MB) Is ETL Circular? Etl file Location                       
---------- ------  ---------------------- ---------------- -----------------                       
Connectors Running                    250            False C:\Windows\temp\SMTrace\Connectors.1.etl
```

## Do you want to contribute to this script?
[Here]({{ site.GitHubRepoLink }}/Trace-SM) is the GitHub repo.
