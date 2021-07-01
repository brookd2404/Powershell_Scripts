
$Key = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
$Value = "DoNotConnectToWindowsUpdateInternetLocations"
$LogFile = "C:\Windows\Logs\Removed_DoNotConnectToWindowsUpdateInternetLocations_atESP.log"

IF(-Not(test-Path -Path $LogFile)) {
    Start-Transcript -Path $LogFile

  IF(Get-ItemProperty -Path $Key -Name $Value -ErrorAction SilentlyContinue) { 
    Write-Host "$Value exists under $Key, Will Remove"
    Remove-ItemProperty -Path $Key -Name $Value -force -ErrorAction Stop
    } ELSE {
        Write-Host "$Value does not exist, Skipping"
    }
Stop-Transcript
}
