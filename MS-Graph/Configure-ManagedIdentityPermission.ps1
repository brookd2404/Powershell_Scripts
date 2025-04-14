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
version: 1.1

Changes:
    1.0 - Initial version
    1.1 - Added error handling and logging for better debugging.
#>

param (
    [ValidateSet("SystemAssigned", "UserManaged")]
    [string]$MIType,
    [string]$subscriptionId,
    [string]$resourceName,
    [string]$resourceGroupName,
    [string[]]$perms
)

try {
    Write-Output "Connecting to Azure account with subscription ID: $subscriptionId"
    Connect-AzAccount -Subscription $subscriptionId
    Write-Output "Successfully connected to Azure account."
} catch {
    Write-Output "Error connecting to Azure account: $_"
    throw
}

try {
    switch ($MIType) {
        SystemAssigned {
            Write-Output "Fetching system-assigned managed identity for resource: $resourceName in resource group: $resourceGroupName"
            $resource = Get-AzResource -ResourceGroupName $resourceGroupName -Name $resourceName
            $servicePrincipal = Get-AzADServicePrincipal -ObjectId $resource.Identity.PrincipalId
            Write-Output "Successfully retrieved system-assigned managed identity."
        }
        UserManaged {
            Write-Output "Fetching user-assigned managed identity for resource: $resourceName in resource group: $resourceGroupName"
            $identity = Get-AzUserAssignedIdentity -ResourceGroupName $resourceGroupName -Name $resourceName
            $servicePrincipal = Get-AzADServicePrincipal -ObjectId $identity.PrincipalId
            Write-Output "Successfully retrieved user-assigned managed identity."
        }
    }
} catch {
    Write-Output "Error retrieving managed identity: $_"
    throw
}

try {
    Write-Output "Fetching Microsoft Graph service principal."
    $graphAPISP = Get-AzADServicePrincipal -DisplayName "Microsoft Graph"
    Write-Output "Successfully retrieved Microsoft Graph service principal."
} catch {
    Write-Output "Error retrieving Microsoft Graph service principal: $_"
    throw
}

foreach ($perm in $perms) {
    try {
        Write-Output "Assigning permission '$perm' to the managed identity."
        $roleId = ($graphAPISP.AppRoles | Where-Object { $_.Value -eq $perm }).Id
        New-AzADServiceAppRoleAssignment -PrincipalId $servicePrincipal.Id -ResourceId $graphAPISP.Id -AppRoleId $roleId
        Write-Output "Successfully assigned permission '$perm'."
    } catch {
        Write-Output "Error assigning permission '$perm': $_"
    }
}