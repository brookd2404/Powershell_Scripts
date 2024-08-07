$CurrentOSLanguage = (Get-Culture).name
$Apps = @{
    "Microsoft.Windows.Notepad" = "notepad"
    "Microsoft.Windows.MSPaint" = "mspaint"
    "Microsoft.Windows.Wordpad" = "wordpad"
}

$Languages = @('en-us','en-my')


$Users = Get-CimInstance -ClassName Win32_LoggedOnUser -ErrorAction SilentlyContinue
$targetprocesses = @(Get-CimInstance -Query "Select * FROM Win32_Process WHERE Name='explorer.exe'" -ErrorAction SilentlyContinue)
if (($targetprocesses.Count -eq 0) -or ($Users.Antecedent.Name -match 'defaultuser0')){
    FOREACH ($Lang in $Languages) {
        IF($CurrentOSLanguage -match $Lang) {
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
        }
    }
}