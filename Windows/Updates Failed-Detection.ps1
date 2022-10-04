[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $WULogFile = "$env:TEMP\$(Get-Date -Format yyyyMMdd-HHmmss)-WindowsUpdate.log"
)

#Get The Current Windows Uodate Logs
Get-WindowsUpdateLog -LogPath $WULogFile | Out-Null

$Date = Get-Date -Format yyyy/MM/dd
$WULOG = Get-Content $WULogFile

$WULOG | % { 
    IF (($_ -like "*FAILED*") -and ($_.Substring(0,10) -match $date))
    {
        Write-Host -ForegroundColor "Red" "Failed Line: $($_)"
        #Write-Host "$($_.Substring(0,10))"
        #IF ($($_.))
    }
}