
$Key = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
$Value = "DoNotConnectToWindowsUpdateInternetLocations"
$LogFile = "C:\Windows\Logs\Added_DoNotConnectToWindowsUpdateInternetLocations_atESP.log"

IF(-Not(test-Path -Path $LogFile)) {
    Start-Transcript -Path $LogFile

  IF(Get-ItemProperty -Path $Key -Name $Value -ErrorAction SilentlyContinue) { 
    Write-Host "$Value exists under $Key, Will Updated to Value 1"
    Set-ItemProperty -Path $Key -Name $Value -Value 1 -Force -ErrorAction Stop
    } ELSE {
        Write-Host "$Value does not exist, creating"
        New-ItemProperty -Path $Key -Name $Value -Value 1 -Force -ErrorAction Stop
        
    }
Stop-Transcript
}
