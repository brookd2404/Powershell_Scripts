$UninstallKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"
$UninstallKeyWow6432Node = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\"
$AppName = "Dell Digital Delivery"
function Uninstall-Application {
    try {
        "Uninstalling $AppName"
        IF (Get-ChildItem -Path $UninstallKey | Get-ItemProperty | Where-Object {$_.DisplayName -like "*$AppName*"} -ErrorAction SilentlyContinue) {
            "Uninstalling $AppName"
            $UninstallGUID = (Get-ChildItem -Path $UninstallKey | Get-ItemProperty | Where-Object {$_.DisplayName -like "*$AppName*"}).PSChildName
            $UninstallArgs = "/X " + $UninstallGUID + " /qn"
            Start-Process "MSIEXEC.EXE" -ArgumentList $UninstallArgs -Wait
        }      
        
        IF (Get-ChildItem -Path $UninstallKeyWow6432Node | Get-ItemProperty | Where-Object {$_.DisplayName -like "*$AppName*"} -ErrorAction SilentlyContinue) {
            "Uninstalling $AppName" 
            $UninstallGUID = (Get-ChildItem -Path $UninstallKeyWow6432Node | Get-ItemProperty | Where-Object {$_.DisplayName -like "*$AppName*"}).PSChildName
            $UninstallArgs = "/X " + $UninstallGUID + " /qn"
            Start-Process "MSIEXEC.EXE" -ArgumentList $UninstallArgs -Wait
        } 
    } catch {
        Write-Error "failed to Uninstall $AppName"
    }
}
Uninstall-Application


$UwpApp = Get-AppxPackage -Name "*DellCommandUpdate*"

IF ($UwpApp) {
    $UwpApp | Remove-AppXPackage
}