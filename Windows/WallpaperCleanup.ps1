$KeysTODelete = @{
    WallPaper = "Software\Microsoft\Windows\CurrentVersion\Policies\System"
    WallPaperStyle = "Software\Microsoft\Windows\CurrentVersion\Policies\System"
    InstallTheme = "SOFTWARE\Microsoft\Windows\CurrentVersion\Themes"
}

$LMKeys = @{
    NoChangingWallpaper = "SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\ActiveDesktop"
}

$Items = Get-ChildItem "Registry::HKEY_USERS\" | Select -Property *

$Items | ForEach-Object {
    Foreach ($Key in $KeysTODelete.Keys) {
        $ItemPath = "Registry::" + $_.Name + "\" + $KeysTODelete[$Key]
        Write-Host $ItemPath
        IF (Get-ItemProperty $ItemPath -Name $Key -ErrorAction SilentlyContinue ) {
            Remove-ItemProperty -Path $ItemPath -Name $Key
        }
    }

    Foreach ($LMKey in $LMKeys.Keys) {
        $LMItemPath = "Registry::" + $_.Name + "\" + $LMKeys[$LMKey]
        Write-Host $LMItemPath
        IF (Get-ItemProperty $ItemPath -Name $LMKey -ErrorAction SilentlyContinue ) {
            Remove-ItemProperty -Path $ItemPath -Name $LMKey
        }
    }
}