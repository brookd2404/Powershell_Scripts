###########DETECTION############
[string]
$DownloadVersion = "20.169.0823.0008"
$HKLMKey6432 = "Registry::HKLM\SOFTWARE\WOW6432Node\Microsoft\OneDrive"
$HKLMKey = "Registry::HKLM\SOFTWARE\Microsoft\OneDrive"

IF (((Get-ItemProperty -Path $HKLMKey6432).Version -ge $DownloadVersion) -or ((Get-ItemProperty -Path $HKLMKey).Version -ge $DownloadVersion)) { 
    Write-Output "$DownloadVersion or later is installed"
}
################################