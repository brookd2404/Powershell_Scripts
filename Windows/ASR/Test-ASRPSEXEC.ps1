<#
.SYNOPSIS
    A quick and dirty script to download and install PSTools from Microsoft Sysinternals, and launch PSEXEC.
.DESCRIPTION
    A quick and dirty script to download and install PSTools from Microsoft Sysinternals, and launch PSEXEC.

    The intention of this script is to be used in a lab environment to quickly install PSTools on a Windows 10 machine to test ASR Rules.
#>

[CmdletBinding()]
param (
    [Parameter(HelpMessage = "The Download URL of the file to PSTools.")]
    [string]
    $PSToolsURL = "https://download.sysinternals.com/files/PSTools.zip",
    [Parameter(HelpMessage = "The Temp Directory to use for the script.")]
    [string]
    $TempDir = "$env:TEMP\ASRTesting"
)

# Create the Temp Directory
if (-not (Test-Path -Path $TempDir)) {
    New-Item -Path $TempDir -ItemType Directory | Out-Null
}

# Download the PSTools
Write-Host "Downloading PSTools..."
[System.Net.WebClient]::new().DownloadFile($PSToolsURL, "$TempDir\PSTools.zip")
Write-Host "Download Complete."
Write-Host "Extracting PSTools..."
Expand-Archive -Path "$TempDir\PSTools.zip" -DestinationPath $TempDir -Force
Write-Host "Extraction Complete."
Write-Host "Attempting to launch PSEXEC..."
Start-Process -FilePath "$TempDir\PsExec.exe" -ArgumentList "-i -s cmd.exe -accepteula" -Wait

# Remove the Temp Directory
Remove-Item -Path $TempDir -Recurse -Force
