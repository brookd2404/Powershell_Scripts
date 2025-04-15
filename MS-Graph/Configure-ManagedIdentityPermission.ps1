<#
.SYNOPSIS
Assigns Microsoft Graph API permissions to a managed identity in Entra.

.DESCRIPTION
This script assigns specified Microsoft Graph API permissions to either a system-assigned or user-assigned managed identity in Entra. It connects to the Microsoft Graph, retrieves the service principal for the managed identity, and assigns the required permissions.

.PARAMETER resourceName
The name of the managed identity.

.PARAMETER permissions
An array of Microsoft Graph API permissions to assign to the managed identity.

.EXAMPLE
Assign permissions to a managed identity:
.\Configure-ManagedIdentityPermission.ps1 -resourceName "myResource" -permissions @("User.Read", "Group.Read.All")

.NOTES
Author: David Brook
Date: 2025-04-15
version: 1.2

Changes:
    1.0 - Initial version
    1.1 - Added error handling and logging for better debugging.
    1.2 - Updated to use Microsoft.Graph PowerShell modules.
#>

param (
    [string]$subscriptionId,
    [string]$resourceName,
    [array]$permissions
)

try {
    Write-Output "Connecting to the Microsoft Graph API..."
    Connect-MgGraph -Scopes "Application.ReadWrite.All", "AppRoleAssignment.ReadWrite.All", "Directory.Read.All" -NoWelcom
    Write-Output "Successfully connected to Azure account."
} catch {
    Write-Output "Error connecting to the Microsoft Graph API"
    throw
}

try {
    Write-Output "Fetching managed identity with name: $resourceName"
    $servicePrincipal = Get-MgServicePrincipal -Filter "displayName eq '$resourceName'"
    if ($null -eq $servicePrincipal) {
        Write-Output "Managed identity '$resourceName' not found."
        throw "Managed identity '$resourceName' not found."
    }
    Write-Output "Successfully retrieved managed identity."
} catch {
    Write-Output "Error retrieving managed identity: $_"
    throw
}

try {
    Write-Output "Fetching Microsoft Graph service principal."
    $graphAPISP = Get-MgServicePrincipal -Filter "displayName eq 'Microsoft Graph'"
    Write-Output "Successfully retrieved Microsoft Graph service principal."
} catch {
    Write-Output "Error retrieving Microsoft Graph service principal: $_"
    throw
}

#Get Existing AppRoleAssignments
$existingAssignment = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $servicePrincipal.Id 
foreach ($perm in $permissions) {
    try {
        Write-Output "Assigning permission '$perm' to the managed identity."
        $roleId = ($graphAPISP.AppRoles | Where-Object { $_.Value -eq $perm -and $_.AllowedMemberTypes -contains "Application" }).Id
        if ($null -eq $roleId) {
            Write-Output "Permission '$perm' not found in Microsoft Graph API."
            throw "Permission '$perm' not found in Microsoft Graph API."
        }
        #Check if the permission is already assigned
        if ($existingAssignment.AppRoleId -contains $roleId) {
            Write-Output "Permission '$perm' is already assigned to the managed identity."
        } else {
            $permissionSplat = @{
                ServicePrincipalId = $servicePrincipal.Id
                ResourceId         = $graphAPISP.Id
                AppRoleId          = $roleId
                PrincipalId        = $servicePrincipal.id
            }
            New-MgServicePrincipalAppRoleAssignment @permissionSplat -ErrorAction Continue | Out-Null
            Write-Output "Successfully assigned permission '$perm'."
        }
    } catch {
        Write-Output "Error assigning permission '$perm': $_"
    }
}