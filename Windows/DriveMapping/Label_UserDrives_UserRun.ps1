$array = @(
    [pscustomobject]@{Share = '\\myserver.mydomain.local\Source'; DisplayName = "Source Share" }
    [pscustomobject]@{Share = '\\myserver.mydomain.local\Sauce'; DisplayName = "Sauce Share" }
)

FOREACH ($prof in $usrProfs) {
    switch (Test-Path -Path HKCU:\Software) {
        false {
            break
        }
        true {
            $mountPath2 = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2"
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

$checkfile = "$env:LocalAppData\Software\drivemapping\mountpoint2.txt"
IF(-Not(Test-Path -Path (Split-Path $checkfile))) {
    New-Item -ItemType Directory -Path (Split-Path $checkfile) | Out-Null
}

"Complete $(Get-Date)" | Out-File -FilePath $checkfile -Force