[CmdletBinding()]
param (
    [Parameter()]
    [string]
    #Download center URL: https://www.hp.com/us-en/solutions/client-management-solutions/download.html
    $downloadURL = "https://hpia.hpcloud.hp.com/downloads/cmsl/hp-cmsl-1.7.1.exe",
    [Parameter()]
    [string]
    $tempSPPath = "$env:TEMP\HPSP",
    [Parameter(Mandatory = $true)]
    [ValidateSet("Install", "Uninstall")]
    [array]
    $Action = @("Install", "Uninstall")
)


switch ($Action)
{
    Install
    {

        if (-not(Test-Path -Path $tempSPPath)) {
            New-Item -Path $tempSPPath -ItemType Directory | Out-Null
        }
        
        $installerPath = Join-Path -Path $tempSPPath -ChildPath "HP-CMSL.exe"

        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($downloadURL, $installerPath)

        Start-Process -FilePath $installerPath -ArgumentList "/VERYSILENT /NORESTART /SUPPRESSMSGBOXES" -Wait

    }
    Uninstall
    {
        $uninstallerPath = "$env:ProgramFiles\WindowsPowerShell\HP.CMSL.UninstallerData\unins000.exe"
        Start-Process -FilePath $uninstallerPath -ArgumentList "/VERYSILENT NORESTART /SUPPRESSMSGBOXES" -Wait
    }
}