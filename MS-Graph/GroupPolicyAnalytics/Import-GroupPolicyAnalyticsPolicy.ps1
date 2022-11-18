<#PSScriptInfo
 
.VERSION 1.1
 
.AUTHOR David Brook
 
.COMPANYNAME EUC365
 
.COPYRIGHT
 
.TAGS Intune; Group Policy; Analytics
 
.RELEASENOTES
Version 1.0: Original published version.
Version 1.1: Made parameters mandatory where required.
 
#>

<#
.SYNOPSIS
This script is intended to be used to import group policy xml exports into group policy anlytics.

.DESCRIPTION
This script is intended to be used to import group policy xml exports into group policy anlytics. This is useful when looking to transition to Intune and analyse the compatability of policies within Intune.

.PARAMETER ModuleNames
Hidden Parameter: Intended to be used to specify required modules. 
Default: @("Microsoft.Graph")
e.g: @("Microsoft.Graph", "AZ.Accounts", "Az.Storage")

.PARAMETER LogOutputLocation
A location to store the output of records changed.
Default: C:\Temp
e.g: D:\Source\Logs

.PARAMETER GPOFolder
The folder where the Group Policy XML files reside
Default: C:\Temp\GPOs
e.g: D:\Source\GPOs

.PARAMETER Recurse
This parameter allows you to do recursive folders
Default: false

.EXAMPLE
.\Import-GroupPolicyAnalyticsPolicy.ps1 -LogOutputLocation "D:\Source\Logs" -GPOFolder "D:\Source\GPOs"

#>

[CmdletBinding()]
param (
    [Parameter(DontShow = $true)]
    [Array]
    $ModuleNames = @("Microsoft.Graph"),
    [Parameter(Mandatory = $true)]
    [String]
    $GPOFolder,
    [Switch]
    $Resurce,
    [String]
    $LogOutputLocation = "C:\Temp",
    [string]
    $TenantID,
    [switch]
    $UseDeviceAuthentication
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
IF (-NOT(Test-Path -Path $LogOutputLocation)) {
    New-Item -ItemType Directory -Path $LogOutputLocation | Out-Null
}

#Import the Required Module.
Import-Module Microsoft.Graph.DeviceManagement
#Set the Microsoft Graph Profile to Beta... because that's what Production runs on.
Select-MgProfile -Name Beta
#Connect to the Microsoft Graph with the required scope

$connectParams = @{
    Scopes = "DeviceManagementConfiguration.ReadWrite.All"
}
IF ($TenantID){$connectParams.Add("TenantID", $TenantID)} #Add the TenantID if Specified
IF ($UseDeviceAuthentication){$connectParams.Add("UseDeviceAuthentication", $true)} #Add the ability to use Device Auth
Connect-MgGraph @connectParams
#Current Group Policies
$curGPAs = Get-MgDeviceManagementGroupPolicyMigrationReport -All

#Get Child Items matching .XML in the GPOFolder
$gciSplat = @{
    Recurse = $(IF($Resurce){$true}else{$false})
    Path = $GPOFolder
    Filter = "*.xml"
}
$gpoFiles = Get-Childitem @gciSplat

$ExportData = @() #Create an empty array for the log data
#Foreach file in the gpoFiles
FOREACH ($gpoFile in $gpoFiles) {
    [XML]$xmlContent = Get-Content -Raw -Path $gpoFile.FullName
    $dInfo = New-Object PSObject
    $dInfo | Add-Member -MemberType NoteProperty -Name "Timestamp" -Value ((Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
    $dInfo | Add-Member -MemberType NoteProperty -Name "GPOName" -Value $xmlContent.GPO.Name
    switch ($xmlContent) {
        { (-NOT($curGPAs.DisplayName -contains $PSItem.GPO.Name)) -and (-Not([String]::IsNullOrEmpty($PSItem.GPO.Name))) } {
            $dInfo | Add-Member -MemberType NoteProperty -Name "CurrentlyExists" -Value $False
            try {
                $params = @{
                    GroupPolicyObjectFile = @{
                        OuDistinguishedName = $PSItem.GPO.Name
                        Content             = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes((Get-Content $gpoFile.FullName -Raw)))
                    }
                }
            
                New-MgDeviceManagementGroupPolicyMigrationReport -BodyParameter $params
                $dInfo | Add-Member -MemberType NoteProperty -Name "ImportState" -Value "Success"
                Write-Output "$($PSItem.GPO.Name) imported"
            }
            catch {
                $dInfo | Add-Member -MemberType NoteProperty -Name "ImportState" -Value "Error"
                Write-Output "$($PSItem.GPO.Name) failed to be imported"
                $Error[0]
            }
        }
        default {
            $dInfo | Add-Member -MemberType NoteProperty -Name "CurrentlyExists" -Value $true
            $dInfo | Add-Member -MemberType NoteProperty -Name "ImportState" -Value "NotRequired"
        }
    }
    $ExportData += $dInfo

}

$ExportData | Export-CSV -NoTypeInformation "$LogOutputLocation\$(Get-Date -Format yyyy-MM-dd)-GroupPolicyAnalyticsImport.csv" -Append
