[string]$Key = "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore"
[string]$Value = "AutoDownload"
[int]$ExpectedValueData = 4
[string]$LogPath = "$env:SystemDrive\Windows\Logs\PowerON_ForceEnableStoreUpdates.log"

Start-Transcript $LogPath

IF(Test-Path -Path $Key) {
    "$Key Exists"
    IF(-Not(((Get-ItemProperty -Path $Key -Name $Value -ErrorAction SilentlyContinue).$Value) -match 4))  {
        "$Value is not equal to $ExpectedValue, or it doe not exist. Will Create/Amend $Value."
        Set-ItemProperty -Path $Key -Name $Value -Value $ExpectedValueData
    }
} ELSE {
    "$Key Does not exist, Will Create the Key and Value."
    New-Item -ItemType Directory -Path $Key
    New-ItemProperty -Path $Key -Name $Value -PropertyType Dword -Value $ExpectedValueData
}

Stop-Transcript
