<#PSScriptInfo
 
.VERSION 1.0
 
.AUTHOR David Brook
 
.COMPANYNAME EUC365
 
.COPYRIGHT
 
.TAGS Autopilot; Intune; Windows Identities
 
.LICENSEURI
 
.PROJECTURI 
 
.ICONURI
 
.EXTERNALMODULEDEPENDENCIES
 
.REQUIREDSCRIPTS
 
.EXTERNALSCRIPTDEPENDENCIES
 
.RELEASENOTES
Version 1.0: Original published version.
 
#>

<#
.SYNOPSIS
This script is intended to remove the Windows Autopilot Identity Display Name.

.DESCRIPTION
This script is intended to remove the Windows Autopilot Identity Display Name. This is useful for cases where a change in business decision on device naming convention changes and can be managed via the Deployment Profiles.

.PARAMETER ModuleNames
Hidden Parameter: Intended to be used to specify required modules. 
Default: @("Microsoft.Graph")
e.g: @("Microsoft.Graph", "AZ.Accounts", "Az.Storage")

.PARAMETER LogOutputLocation
A location to store the output of records changed.
Default: C:\Temp
e.g: D:\Source\Logs

.EXAMPLE
.\Remove-AutopilotDisplayNameProperty.ps1 -LogOutputLocation "D:\Source\Logs"

#>

[CmdletBinding()]
param (
    [Parameter(DontShow = $true)]
    [Array]
    $ModuleNames = @("Microsoft.Graph"),
    [String]
    $LogOutputLocation = "C:\Temp"
)

#For Each Module in the ModuleNames Array, Attempt to install them
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
}

#If the Log location does not exist, Create it
IF (-NOT(Test-Path -Path $LogOutputLocation)){
    New-Item -ItemType Directory -Path $LogOutputLocation | Out-Null
}

#Import the Required Module.
Import-Module Microsoft.Graph.DeviceManagement
#Set the Microsoft Graph Profile to Beta... because that's what Production runs on.
Select-MgProfile -Name Beta
#Connect to the Microsoft Graph with the required scope
Connect-MgGraph -Scopes "DeviceManagementServiceConfig.ReadWrite.All"
#Obtain all Identities
$GraphDevices = Get-MgDeviceManagementWindowAutopilotDeviceIdentity -All

$ExportData = @() #Create an empty array for the log data
FOREACH ($Device in $GraphDevices) {
    $dInfo = New-Object PSObject
    $dInfo | Add-Member -MemberType NoteProperty -Name "DeviceSerial" -Value $Device.SerialNumber
    switch ($Device) {
        {-NOT($null -match $PSItem.DisplayName)} {
            $dInfo | Add-Member -MemberType NoteProperty -Name "DisplayNameSet" -Value $true
            $dInfo | Add-Member -MemberType NoteProperty -Name "DisplayNameValue" -Value $PSItem.DisplayName
            Write-Output "$($PSItem.SerialNumber) has the display name of $($PSItem.DisplayName)"
            try {
                $params = @{
                    DisplayName = ""
                }
                Update-MgDeviceManagementWindowAutopilotDeviceIdentityDeviceProperty -WindowsAutopilotDeviceIdentityId $PSItem.id -BodyParameter $params
                $dInfo | Add-Member -MemberType NoteProperty -Name "DisplayNameRemoved" -Value $true

            }
            catch {
                $dInfo | Add-Member -MemberType NoteProperty -Name "DisplayNameRemoved" -Value "ERROR"

            }
        }
        default {
            $dInfo | Add-Member -MemberType NoteProperty -Name "DisplayNameSet" -Value $false
            $dInfo | Add-Member -MemberType NoteProperty -Name "DisplayNameRemoved" -Value "NotRequired"
        }
    }
    $ExportData += $dInfo
}

$ExportData | Export-CSV -NoTypeInformation "$LogOutputLocation\$(Get-Date -Format yyyy-MM-dd)-WindowsAutopilotDeviceProperties.csv"