
 #  REQUIRES elevation !!!!!!!!!!!!

# SKIP strong name verification
reg DELETE "HKLM\Software\Microsoft\StrongName\Verification" /f
reg ADD    "HKLM\Software\Microsoft\StrongName\Verification\*,31bf3856ad364e35" /f
 
   if ($env:PROCESSOR_ARCHITECTURE -eq "AMD64")
   {
       reg DELETE "HKLM\Software\Wow6432Node\Microsoft\StrongName\Verification" /f
       reg ADD    "HKLM\Software\Wow6432Node\Microsoft\StrongName\Verification\*,31bf3856ad364e35" /f
    } 
# restart the app 

<#  

    # To revert to the default = VERIFY strong name
    reg DELETE "HKLM\Software\Microsoft\StrongName\Verification" /f
 
       if ($env:PROCESSOR_ARCHITECTURE -eq "AMD64")
       {
           reg DELETE "HKLM\Software\Wow6432Node\Microsoft\StrongName\Verification" /f
        } 
    # restart the app 



    # To DETECT if strong name is skipped?
    Get-Item -Path "HKLM:\Software\Microsoft\StrongName\Verification\*,31bf3856ad364e35"
    if ($env:PROCESSOR_ARCHITECTURE -eq "AMD64")
    {
        Get-Item -Path "HKLM:\Software\Wow6432Node\Microsoft\StrongName\Verification\*,31bf3856ad364e35"
    } 

#>