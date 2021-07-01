$Apps = @{
    "Microsoft.Windows.Notepad" = "notepad"
    "Microsoft.Windows.MSPaint" = "mspaint"
    "Microsoft.Windows.Wordpad" = "wordpad"
}


        FOREACH ($App in $Apps.Keys) {
            $LogPath = "$env:SystemDrive\Windows\Logs\Reinstall-Windows-OptionalFeatures_$App.log"
            IF (-not (Test-Path -Path $LogPath)) {
                Start-Transcript $LogPath
                IF (-Not(Get-Process -Name $Apps[$App] -ErrorAction SilentlyContinue)) {
                    try {
                        "Re-Installing $App"
                        Get-WindowsCapability -Online -Name "*$App*" | Remove-WindowsCapability -Online -ErrorAction Stop
                        Get-WindowsCapability -Online -Name "*$App*"  | Add-WindowsCapability -Online -ErrorAction Stop
                    }
                    catch {
                        $Error[0]
                        throw "Failure" 
                    }
                } ELSE {
                    "App is running, No need to re-install"
                }
            }
            Stop-Transcript
        }