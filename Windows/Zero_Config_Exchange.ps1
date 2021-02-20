<#

    Author: David Brook

    Purpose: ZeroConfig for Exchange Outlook Profiles in the Default User Profile

    Helpful guide: https://techcommunity.microsoft.com/t5/outlook-global-customer-service/zeroconfigexchange-automating-the-creation-of-an-outlook-profile/ba-p/389691

#>

param (
    [String]
    $ProfileName = "RB",
    #Outlook version – 16.0 = 2016, 15.0 = 2013
    [ValidateSet("16.0","15.0")]
    $OutlookVersion = "16.0"

)

$RegKey = "DefUser\Software\Microsoft\Office\$OutlookVersion\Outlook"

reg.exe load HKLM\DefUser "$Env:SystemDrive\Users\Default\NTUSER.DAT"

if (-not (Test-Path -Path "HKLM:\$RegKey"))
{
    [Microsoft.Win32.RegistryKey]$DefaultProfileKey = [Microsoft.Win32.Registry]::LocalMachine.CreateSubKey($RegKey, [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree)
    $DefaultProfileKey.SetValue("DefaultProfile", $ProfileName, [Microsoft.Win32.RegistryValueKind]::String)
    $DefaultProfileKey.Flush()
    $DefaultProfileKey.Close()
}

if (-not (Test-Path -Path "HKLM:\$RegKey\AutoDiscover"))
{
    [Microsoft.Win32.RegistryKey]$AutoDiscoverKey = [Microsoft.Win32.Registry]::LocalMachine.CreateSubKey("$RegKey\AutoDiscover", [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree)
    $AutoDiscoverKey.SetValue("ZeroConfigExchange", 1, [Microsoft.Win32.RegistryValueKind]::DWord)
    $AutoDiscoverKey.Flush()
    $AutoDiscoverKey.Close()
}

if (-not (Test-Path -Path "HKLM:\$RegKey\Profiles"))
{
    [Microsoft.Win32.RegistryKey]$ProfilesKey = [Microsoft.Win32.Registry]::LocalMachine.CreateSubKey("$RegKey\Profiles\$($ProfileName)", [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree)
    $ProfilesKey.Flush()
    $ProfilesKey.Close()
}

Start-Sleep -Seconds 5

$DefaultProfileKey.Flush()
$DefaultProfileKey.Close()
$AutoDiscoverKey.Flush()
$AutoDiscoverKey.Close()
$ProfilesKey.Flush()
$ProfilesKey.Close()

Start-Sleep -Seconds 5

reg.exe unload "HKLM\DefUser"