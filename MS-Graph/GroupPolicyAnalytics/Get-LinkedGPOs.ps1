<#
.SYNOPSIS
This script is intended to get Linked GPOs from a Specified OU, This must be run on a Machine with the Group Policy and ActiveDirectory Modules

.DESCRIPTION
This script is intended to get Linked GPOs from a Specified OU, This must be run on a Machine with the Group Policy and ActiveDirectory Modules

.PARAMETER GPOFolder
The folder where the Group Policy XML files Will be Exported to
Default: C:\Temp\GPOs
e.g: D:\Source\GPOs

.PARAMETER OU
This parameter is used to specify the target OU
Default: false

.EXAMPLE
.\Get-LinkedGPOs.ps1 -GPOFolder "D:\Source\GPOs" -OU "OU=Managed_Devices,DC=EUC365,DC=LAB"

#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [String]
    $GPOFolder,
    [Parameter(Mandatory = $true)]
    [String]
    $OU
)

#If the GPO FOlder location does not exist, Create it
IF (-NOT(Test-Path -Path $GPOFolder)) {
    New-Item -ItemType Directory -Path $GPOFolder | Out-Null
}

#Import the Active Directory Module
Import-Module ActiveDirectory 

$ouGPOs = Get-ADOrganizationalUnit $OU | Select-object -ExpandProperty LinkedGroupPolicyObjects | ForEach-object{$_.Substring(4,36)}
$ouGPOs | % { 
    "Exporting $($_)"
    Get-GPOReport -Guid $_ -ReportType Xml | Out-File (Join-path -Path $GPOFolder -ChildPath "$_.xml")
}