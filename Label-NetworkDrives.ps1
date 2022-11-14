$array = @(
    [pscustomobject]@{Share = '\\Yourserver.domain.local\Share'; DisplayName = "My Awesome Share" }
)

$mountPoints2 = "HKU:\$($prof.PSChildName)\Software\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2"
FOREACH ($obj in $array) {
    $shareKey = (Join-Path -Path $mountPoints2 -ChildPath $obj.Share.Replace('\', '#') )
    IF (-Not(Test-Path -Path $shareKey)) {
        New-Item -ItemType Directory -Path $shareKey | Out-Null
    }
    New-ItemProperty -Path $shareKey -Name "_LabelFromReg" -Type String -Value $obj.DisplayName | Out-Null
}

$checkfile = "$env:LocalAppData\Software\DriveMapping\DriveMappingLabels.ps1.tag"
IF (-Not(Test-Path -Path (Split-Path $checkfile))) {
    New-Item -ItemType Directory -Path (Split-Path $checkfile) | Out-Null
}
Out-File -FilePath $checkfile -Force