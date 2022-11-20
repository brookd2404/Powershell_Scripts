[CmdletBinding()]
param (
    [String]
    $ExportPath = "$env:TEMP\AzureStorageFileShareExport",
    [string]
    $TenantID = "TenantID",
    [Array]
    [Parameter(DontShow = $true)]
    $AzModuleName = @("AzureAD") #Set the name of the Azure Module
)

#If the Export Path does not exist, Create it. 
if (-Not(Test-Path -Path $ExportPath)) {
    try {
        New-Item -ItemType Directory -Path $ExportPath | Out-Null
    }
    catch {
        Throw "Failed to create $exportPath Directory"    
    }
}


#If the Azure RM Module is not installed, Install it

FOREACH ($Module in $AzModuleName) 
{
    $AzModule = Get-Module -Name $Module -ListAvailable -ErrorAction SilentlyContinue
    IF (-not($AzModule)) {
        try {
            "Attempting to install Powershell Module ($Module) in the system context"
            Install-PackageProvider -Name
            Install-Module $Module
        }
        catch {
            "Attempting to install Powershell Module ($Module) in the current user context"
            Install-Module $Module -Scope CurrentUser -Force
            "Module Installed in the Current User Context"
        }
        Finally {
            "Unable to install the $Module Powershell Module"
        }
    }
}

Connect-AzureAD -TenantId $TenantID

Get-AzureADUser -All $true | Select-Object -Property displayName, ObjectID, OnPremisesSecurityIdentifier | Export-CSV -NoTypeInformation -Path "$ExportPath\$($TenantID)_AzureADUsers.csv"