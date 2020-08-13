<#PSScriptInfo
 
.VERSION 3.0
 
.AUTHOR David Brook
 
.COMPANYNAME EUC365
 
.COPYRIGHT
 
.TAGS Microsoft Endpoint Manager; SCCM
 
.LICENSEURI
 
.PROJECTURI
 
.ICONURI
 
.EXTERNALMODULEDEPENDENCIES
 
.REQUIREDSCRIPTS
 
.EXTERNALSCRIPTDEPENDENCIES
 
.RELEASENOTES
Version 3.0: Converted Most actions to input params 
Version 2.0: Added the ability to make the script accept command line arguments
Version 1.0: Original published version.
 
#>


<#
.SYNOPSIS
This script will create an Active Directory Group and Endpoint Manager Collection with a Dynamic Query to Enumerate the Active Directory Group. 
 
.DESCRIPTION
This script will create an AD Group and Dynamic Query Endpoint Manager user collection based on the AppName command line input. 

.PARAMETER EPMPSModule
The location of the Endpoint Manager Powershell Module 

.PARAMETER AppName
The name of the App

e.g Visual Studio Code 1.44

This will create the group GRP-EPM-Visual Studio Code 1.44 in AD and the same user collection with a dynamic query in Endpoint Manager

.PARAMETER ScheduleMinutes
The time in which a Schedule sync will run for the collection in Minutes

e.g 30 - This will create a 30 minute schedule

.PARAMETER GroupPrefix
The group name prefix
Default: GRP-EPM
e.g GRP-EPM - This will create a group called GRP-EPM-<AppName>

.PARAMETER LookupDomain
The NETBIOs name of the Domain the group will exist in

.PARAMETER GroupOU
The Full LDAP Location of the OU where the Group will be created 


.PARAMETER GroupDescription
The Description to be added to the AD Group
Default: Endpoint Manager Application Access for $AppName
e.g Endpoint Manager Application Access for MyApp 1.0

.PARAMETER LimitingCollection
The Endpoint Manager Collection that Limits the Items the group can query against
Default: All Users and User Groups



.EXAMPLE
.\CreateEPMGroup-CreateCollection.ps1 -AppName "MyApp 1.0"
 
.EXAMPLE
.\CreateEPMGroup-CreateCollection.ps1 -AppName "MyApp 1.0" -ScheduleMinutes 30
 
.EXAMPLE
.\CreateEPMGroup-CreateCollection.ps1 -AppName "MyApp 1.0" -GroupPrefix "GRP-EPM" -ScheduleMinutes 30 
This will create an AD Group Called GRP-EPM-MyApp 1.0 
 
.EXAMPLE
.\CreateEPMGroup-CreateCollection.ps1 -AppName "MyApp 1.0" -GroupPrefix "GRP-EPM" -LookupDomain "CORP" -ScheduleMinutes 30 

.EXAMPLE
.\CreateEPMGroup-CreateCollection.ps1 -AppName "MyApp 1.0" -GroupPrefix "GRP-EPM" -LookupDomain "CORP" -ScheduleMinutes 30 -GroupOU "OU=ENDPOINT MANAGER DEPLOYMENTS,OU=CORP GROUPS,DC=CORP,DC=INTERNAL"
 
#>


[CmdletBinding()]
param (
    [Parameter()]
    [ValidateNotNull()] 
    [ValidateScript({Test-Path $_})]
    [string]
    $EPMPSModule = "<YourModule>",
    [Parameter(mandatory=$true)]
    [ValidateNotNull()] 
    [string]
    $AppName,
    [Parameter()]
    [ValidateRange(30,60)]
    [int]
    $ScheduleMinutes = 30,
    [Parameter()]
    [ValidateNotNull()] 
    [string]
    $GroupPrefix = 'GRP-EPM',
    [Parameter()]
    [ValidateNotNull()] 
    [string]
    $LookupDomain = "DOMAIN",
    [Parameter()]
    [ValidateNotNull()] 
    [string]
    $GroupOU = "OU=DEPLOYMENTS,DC=DOMAIN,DC=INTERNAL",
    [Parameter()]
    [ValidateNotNull()] 
    [string]
    $GroupDescription = "Endpoint Manager Application Access for $AppName",
    [Parameter()]
    [ValidateNotNull()] 
    [string]
    $LimitingCollection = "All Users and User Groups",
    [Parameter()]
    [ValidateNotNull()] 
    [string]
    #You will need to put a : after your site code
    $siteCode
)

#Import The SCCM Module and change to the Site Server context
Import-Module $EPMPSModule
Push-Location $siteCode

Import-Module ActiveDirectory

# SCRIPT FUNCTION
# Add a AD group and addd at Endpoint CM collection based on a query rule of the member of the group that the user inputs.

# Variable Collection and Set Block
# Set a schedule to run every 30 minutes
# Get the group name from the user
# Alter the group name to be in the correct format for the query with domain and quotation marks around it.
# Set the query text for the add rule.

$Schedule = New-CMSchedule -RecurInterval Minutes -RecurCount $ScheduleMinutes
$GroupName = $GroupPrefix + "-" + $AppName
$queryGroupName = '"' + "$LookupDomain" + '\\' + $GroupName + '"'
$QueryRule = "select * from SMS_R_User where SMS_R_User.SecurityGroupName = $queryGroupName"

New-ADGroup -GroupScope Global -Name $GroupName -Description $GroupDescription -DisplayName $GroupName -GroupCategory Security -SamAccountName $GroupName -Path $GroupOU

#Add Collection
New-CMCollection -CollectionType User -LimitingCollectionName $LimitingCollection -NAME $GroupName -RefreshSchedule $schedule

#Set The Collection Rule
Add-CMUserCollectionQueryMembershipRule -CollectionName $GroupName -RuleName "AD Group Enum" -QueryExpression $QueryRule

Pop-Location
