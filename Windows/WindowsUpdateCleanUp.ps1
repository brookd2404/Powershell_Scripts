
Stop-Service -Name wuauserv -Force
Stop-Service -Name cryptSvc -Force
Stop-Service -Name bits -Force
Stop-Service -Name msiserver -Force

IF (Test-Path C:\Windows\SoftwareDistribution.OLD) {
    Remove-Item -Path C:\Windows\SoftwareDistribution.old -Recurse -Force
}

IF (Test-Path C:\System32\catroot2.old) {
    Remove-Item -Path C:\System32\catroot2.old -Recurse -Force
}

Rename-Item C:\Windows\SoftwareDistribution SoftwareDistribution.old
Rename-Item C:\Windows\System32\catroot2 Catroot2.old

Start-Service -Name wuauserv 
Start-Service -Name cryptSvc
Start-Service -Name bits
Start-Service -Name msiserver