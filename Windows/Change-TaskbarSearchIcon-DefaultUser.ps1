reg.exe load HKLM\DefUser "$Env:SystemDrive\Users\Default\NTUSER.DAT"

if (-not (Test-Path -Path "HKLM:\DefUser\Software\Microsoft\Windows\CurrentVersion\Search"))
{
    [Microsoft.Win32.RegistryKey]$HKUSearchKey = [Microsoft.Win32.Registry]::LocalMachine.CreateSubKey("DefUser\Software\Microsoft\Windows\CurrentVersion\Search", [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree)
    $HKUSearchKey.SetValue("SearchboxTaskbarMode", 1, [Microsoft.Win32.RegistryValueKind]::DWord)
    $HKUSearchKey.Flush()
    $HKUSearchKey.Close()
}
Start-Sleep -Seconds 5

$HKUSearchKey.Flush()
$HKUSearchKey.Close()

Start-Sleep -Seconds 5

reg.exe unload "HKLM\DefUser"

Start-Sleep -Seconds 5

