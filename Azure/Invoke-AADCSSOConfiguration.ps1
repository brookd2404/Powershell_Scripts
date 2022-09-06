param (
    $daCred = $(Get-Credential -Message "Please enter your Domain Administrator Credentials"),
    $gaCred = $(Get-Credential -Message "Please enter your Global Administrator Credentials"),
    $downloadLink = "https://download.microsoft.com/download/B/0/0/B00291D0-5A83-4DE7-86F5-980BC00DE05A/AzureADConnect.msi",
    $AADCMSIPath = "C:\Install\AzureADConnect.msi",
    $extractLocation = "C:\Install\AADC",
    $ModuleNames = @("AzureAD")
)


FOREACH ($Module in $ModuleNames) {
    IF (!(Get-Module -ListAvailable -Name $Module)) {
        try {
            Write-Output "Attempting to install $Module Module for the Current Device"
            Install-Module -Name $Module -Force -AllowClobber
        }
        catch {
            Write-Output "Attempting to install $Module Module for the Current User"
            Install-Module -Name $Module -Force -AllowClobber -Scope CurrentUser
        }
    }  
    Import-Module $Module
}

IF (-not(Test-Path -Path (Split-Path $AADCMSIPath -Parent))){
    New-Item -Path (Split-Path $AADCMSIPath -Parent) -ItemType Directory -Force
}

(New-Object System.Net.WebClient).DownloadFile($downloadLink, $AADCMSIPath)
Start-Process -FilePath MSIEXEC.exe -ArgumentList "/a `"$AADCMSIPath`" /qb TARGETDIR=$extractLocation" -Wait
Import-Module "$extractLocation\Microsoft Azure Active Directory Connect\AzureADSSO.psd1"
New-AzureADSSOAuthenticationContext -CloudCredentials $gaCred
Enable-AzureADSSOForest -OnPremCredentials $daCred