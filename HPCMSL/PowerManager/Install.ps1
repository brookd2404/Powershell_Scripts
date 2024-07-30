[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $requiredSoftware = 'HP Power Manager',
    [Parameter()]
    [string]
    $tempSPPath = "$env:TEMP\HPSP"
)

IF (-Not ("NuGet" -in (Get-PackageProvider).Name))
{
    Install-PackageProvider -Name NuGet -Force
}

#Check if the temp folder exists
if (-not (Test-Path -Path $tempSPPath))
{
    New-Item -Path $tempSPPath -ItemType Directory | Out-Null
}

$hpSoftwareInfo = Get-SoftpaqList -Category "Software" | Where-Object { $_.Name -match $requiredSoftware }

#Install the software
$savedSPFile = (Join-Path $tempSPPath -ChildPath "$($hpSoftwareInfo.id).exe")
Get-Softpaq -Number $hpSoftwareInfo.id -SaveAs $savedSPFile -Action silentinstall

#Clean up after install
IF (Test-Path $savedSPFile)
{
    Remove-Item -Path $savedSPFile -Force
}