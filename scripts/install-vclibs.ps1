    Invoke-WebRequest https://download.microsoft.com/download/B/E/1/BE1F235A-836D-42AC-9BC1-8F04C9DA7E9D/vc_uwpdesktop.140.exe -o "C:\Windows\Temp\vc_uwpdesktop.140.exe"
    C:\Windows\Temp\vc_uwpdesktop.140.exe /install  /quiet /norestart /log "C:\Windows\Temp\uwpdesktop.log"
    Get-Content "C:\Windows\Temp\uwpdesktop.log"