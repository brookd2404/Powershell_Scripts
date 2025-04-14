<#
.SYNOPSIS
Assigns Microsoft Graph API permissions to a managed identity in Azure.

.DESCRIPTION
This script assigns specified Microsoft Graph API permissions to either a system-assigned or user-assigned managed identity in Azure. It connects to the Azure account, retrieves the service principal for the managed identity, and assigns the required permissions.

.PARAMETER MIType
Specifies the type of managed identity. Valid values are "SystemAssigned" or "UserManaged".

.PARAMETER subscriptionId
The subscription ID where the managed identity resides.

.PARAMETER resourceName
The name of the resource associated with the managed identity.

.PARAMETER resourceGroupName
The name of the resource group containing the resource.

.PARAMETER perms
An array of Microsoft Graph API permissions to assign to the managed identity.

.EXAMPLE
Assign permissions to a system-assigned managed identity:
.\Configure-ManagedIdentityPermission.ps1 -MIType SystemAssigned -subscriptionId "12345-abcde-67890" -resourceName "myResource" -resourceGroupName "myResourceGroup" -perms @("User.Read", "Group.Read.All")

.EXAMPLE
Assign permissions to a user-assigned managed identity:
.\Configure-ManagedIdentityPermission.ps1 -MIType UserManaged -subscriptionId "12345-abcde-67890" -resourceName "myResource" -resourceGroupName "myResourceGroup" -perms @("User.Read", "Group.Read.All")

.NOTES
Author: David Brook
Date: 2025-04-14
version: 1.0

#>

param (
    [ValidateSet("SystemAssigned", "UserManaged")]
    [string]$MIType,
    [string]$subscriptionId,
    [string]$resourceName,
    [string]$resourceGroupName,
    [string[]]$perms
)

Connect-AzAccount -Subscription $subscriptionId

switch ($MIType) {
    SystemAssigned {
        $resource = Get-AzResource -ResourceGroupName $resourceGroupName -Name $resourceName
        $servicePrincipal = Get-AzADServicePrincipal -ObjectId $resource.Identity.PrincipalId
    }
    UserManaged {
        $identity = Get-AzUserAssignedIdentity -ResourceGroupName "<your-rg-name>" -Name "<identity-name>"
        $servicePrincipal = Get-AzADServicePrincipal -ObjectId $identity.PrincipalId

    }
}

$graphAPISP = Get-AzADServicePrincipal -DisplayName "Microsoft Graph"

foreach ($perm in $perms) {
    $roleId = ($graphAPISp.AppRoles | Where-Object { $_.Value -eq $perm }).Id
   New-AzADServiceAppRoleAssignment -PrincipalId $servicePrincipal.Id -ResourceId $graphAPISP.Id -AppRoleId $roleId
}