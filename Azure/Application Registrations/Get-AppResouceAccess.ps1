param (
    [String]
    $ObjectID,
    [Array]
    [Parameter(DontShow = $true)]
    $AzModuleName = @("AzureAD") #Set the name of the Azure Module
)

#region Install Modules if required
FOREACH ($Module in $AzModuleName) 
{
    $AzModule = Get-Module -Name $Module -ListAvailable -ErrorAction SilentlyContinue
    IF (-not($AzModule)) {
        try {
            "Attempting to install Powershell Module ($Module) in the system context"
            Install-Module $Module -Force -AllowClobber
        }
        catch {
            "Attempting to install Powershell Module ($Module) in the current user context"
            Install-Module $Module -Scope CurrentUser -Force -AllowClobber
            "Module Installed in the Current User Context"
        }
        Finally {
            "Unable to install the $Module Powershell Module"
        }
    }
}

#endregion Install Modules if required

Connect-AzureAD

$App = Get-AzureADApplication -ObjectId $ObjectID 

$App.RequiredResourceAccess.ResourceAccess