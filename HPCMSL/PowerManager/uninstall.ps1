[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $AppXName = "HPPowerManager"
)

#Detect if tha app is installed, if it is, uninstall it
$appXPackage = Get-AppxPackage | Where-Object { $_.Name -match $AppXName }

IF ($null -ne $appXPackage)
{
    $appXPackage | Remove-AppxPackage -AllUsers
}
