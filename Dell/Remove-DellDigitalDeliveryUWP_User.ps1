$AppName = "DellInc.DellDigitalDelivery"
$LogPath = "$env:LocalAppData\DellDigitalDelivery_Removal.log"

Start-Transcript $LogPath
IF( Get-AppxPackage -Name "*$AppName*" -ErrorAction SilentlyContinue) {
    "$AppName is installed, Attemptiing Removal"
    try {
        Get-AppxPackage -Name "*$AppName*"  | Remove-AppxPackage
        "Removal of $AppName Successful"
    } 
    catch {
        $Error[0]
        Throw "Failed to Remove $AppName"
    }
} ELSE {
    "$AppName is not installed on this device"
}
Stop-Transcript
