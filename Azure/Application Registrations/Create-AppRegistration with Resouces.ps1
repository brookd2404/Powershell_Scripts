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


$requiredGrants = [Microsoft.Open.AzureAD.Model.RequiredResourceAccess]::new(
    "00000003-0000-0000-c000-000000000000", # Microsoft Graph
    @(
        #[Microsoft.Open.AzureAD.Model.ResourceAccess]::new("e1fe6dd8-ba31-4d61-89e7-88639da4683d","Scope") # OpenID
        [Microsoft.Open.AzureAD.Model.ResourceAccess]::new("0e263e50-5827-48a4-b97c-d940288653c7","Scope") # Directory.AccessAsUser.All
        [Microsoft.Open.AzureAD.Model.ResourceAccess]::new("a154be20-db9c-4678-8ab7-66f6cc099a59","Scope") # openid
        [Microsoft.Open.AzureAD.Model.ResourceAccess]::new("63dd7cd9-b489-4adf-a28c-ac38b9a0f962","Scope") # User.Invite.All
        [Microsoft.Open.AzureAD.Model.ResourceAccess]::new("204e0828-b5ca-4ad8-b9f3-f32a958e7cc4","Scope") # User.ReadWrite.All
        [Microsoft.Open.AzureAD.Model.ResourceAccess]::new("d01b97e9-cbc0-49fe-810a-750afd5527a3","Scope") # RoleManagement.ReadWrite.Directory
        [Microsoft.Open.AzureAD.Model.ResourceAccess]::new("3c3c74f5-cdaa-4a97-b7e0-4e788bfcfb37","Scope") # PrivilegedAccess.ReadWrite.AzureAD
    )
)

$NewSplat = @{
    DisplayName = "Created with PS"
    RequiredResourceAccess = $requiredGrants
}

New-AzureADApplication @NewSplat