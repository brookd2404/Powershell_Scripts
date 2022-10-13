$array = @(
    [pscustomobject]@{Share = '\\myserver.mydomain.local\Source'; DisplayName = "Source Share" }
    [pscustomobject]@{Share = '\\myserver.mydomain.local\Sauce'; DisplayName = "Sauce Share" }
)


#Get List of User Profiles
$usrProfs = Get-ChildItem 'HKLM:Software/Microsoft/Windows NT/CurrentVersion/ProfileList' | Where-Object { $_.Getvalue('ProfileImagePath') -match "C:\\Users" }

#Map HKEY_Users
New-PSDrive HKU Registry HKEY_USERS | Out-Null

FOREACH ($prof in $usrProfs) {
    switch (Test-Path -Path HKU:\$($prof.PSChildName)\Software) {
        false {
            break
        }
        true {
            $mountPath2 = "HKU:\$($prof.PSChildName)\Software\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2"
            FOREACH ($obj in $array) {
                $shareKey = (Join-Path -Path $mountPath2 -ChildPath $obj.Share.Replace('\', '#') )
                IF (-Not(Test-Path -Path $shareKey)) {
                    New-Item -ItemType Directory -Path $shareKey | Out-Null
                }
                New-ItemProperty -Path $shareKey -Name "_LabelFromReg" -Type String -Value $obj.DisplayName | Out-Null
            }
        }
    }
}

#Load the Default User profile
reg.exe load HKLM\DefUser "$Env:SystemDrive\Users\Default\NTUSER.DAT"
FOREACH ($obj in $array) {
    $rootKey = "DefUser\Software\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2"
    $shareKey = (Join-Path -Path $rootKey -ChildPath $obj.Share.Replace('\', '#') )
    if (-not (Test-Path -Path "HKLM:\$ShareKey")) {
        [Microsoft.Win32.RegistryKey]$DefaultProfileKey = [Microsoft.Win32.Registry]::LocalMachine.CreateSubKey($shareKey, [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree)
        $DefaultProfileKey.SetValue("_LabelFromReg", $obj.DisplayName, [Microsoft.Win32.RegistryValueKind]::String)
        $DefaultProfileKey.Flush()
        $DefaultProfileKey.Close()
    }
}
$DefaultProfileKey.Flush()
$DefaultProfileKey.Close()
Start-Sleep -Seconds 5
reg.exe unload "HKLM\DefUser"

$checkfile = "$env:ProgramData\Software\drivemapping\mountpoint2.txt"
IF(-Not(Test-Path -Path (Split-Path $checkfile))) {
    New-Item -ItemType Directory -Path (Split-Path $checkfile) | Out-Null
}

"Complete $(Get-Date)" | Out-File -FilePath $checkfile -Force