  
<#PSScriptInfo
 
.VERSION 2.0
 
.AUTHOR David Brook
 
.COMPANYNAME EUC365
 
.COPYRIGHT
 
.TAGS Autopilot; Intune; Mobile Device Management
 
.LICENSEURI
 
.PROJECTURI 
 
.ICONURI
 
.EXTERNALMODULEDEPENDENCIES
 
.REQUIREDSCRIPTS
 
.EXTERNALSCRIPTDEPENDENCIES
 
.RELEASENOTES
Version 2.0: Added the ability to make the script accept command line arguments for just the Hash and also allow Group Tags
Version 1.0: Original published version.
 
#>


<#
.SYNOPSIS
This script will import devices to Microsoft Endpoint Manager Autopilot using the device's hardware hash.  
 
.DESCRIPTION
This script will import devices to Microsoft Endpoint Manager Autopilot using the device's hardware hash with the added capability of been able to add a Group Tag.

.PARAMETER MSGraphVersion
The Version of the MS Graph API to use
Default: Beta
e.g: 1.0

.PARAMETER MsGraphHost
The MS Graph API Host
Default: graph.microsoft.com

.PARAMETER ClientID
This is the Azure AD App Registration Client ID

.PARAMETER ClientSecret
This is the Azure AD App Registration Client Secret

.PARAMETER TenantId
Your Azure Tenant ID

.PARAMETER Hash
This parameter is to be used if you want to import a specific hash from either a file or copying and pasting from an application. 
 
.PARAMETER GroupTag
This Parameter is to be used if you want to Tag your devices with a specific group tag. 

.EXAMPLE
.\Enroll_to_Autopliot_Unattended.ps1 -ClientID "<Your Client ID>" -Client Secret "<YourClientSecret>" -TenantID "<YourTenantID>"

This will enroll the device it is running on to Autopilot, Please note this will need to be done as an administrator
 
.EXAMPLE
.\Enroll_to_Autopliot_Unattended.ps1 -ClientID "<Your Client ID>" -Client Secret "<YourClientSecret>" -TenantID "<YourTenantID>" -GroupTag "Sales Device"

This will enroll the device it is running on to Autopilot with a Group Tag of Sales Device, Please note this will need to be done as an administrator
 
.EXAMPLE
.\Enroll_to_Autopliot_Unattended.ps1 -ClientID "<Your Client ID>" -Client Secret "<YourClientSecret>" -TenantID "<YourTenantID>" -Hash "<A Hash>"

This will enroll the inputed deivce Hash to Autopilot, this can be done against a group of CSV files etc. 
  
#>
param(
    [Parameter(DontShow = $true)]
    [string]
    $MsGraphVersion = "beta",
    [Parameter(DontShow = $true)]
    [string]
    $MsGraphHost = "graph.microsoft.com",
    #The AzureAD ClientID (Application ID) of your registered AzureAD App
    [string]
    $ClientID = "<YourClientID>",
    #The Client Secret for your AzureAD App
    [string]
    $ClientSecret = "<YourSecret>",
    #Your Azure Tenent ID
    [string]
    $TenantId = "<YourTenant>",
    [string]
    $Hash,
    [string]
    $GroupTag
)

Begin
{
    #Create the body of the Authentication of the request for the OAuth Token
    $Body = @{client_id=$ClientID;client_secret=$ClientSecret;grant_type="client_credentials";scope="https://$MSGraphHost/.default";}
    #Get the OAuth Token 
    $OAuthReq = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" -Body $Body
    #Set your access token as a variable
    $global:AccessToken = $OAuthReq.access_token
}
Process
{
    if(!$Hash) {
        $session = New-CimSession
        # Get the common properties.
        Write-Verbose "Checking $comp"
        $serial = (Get-CimInstance -CimSession $session -Class Win32_BIOS).SerialNumber
        # Get the hash (if available)
        $devDetail = (Get-CimInstance -CimSession $session -Namespace root/cimv2/mdm/dmmap -Class MDM_DevDetail_Ext01 -Filter "InstanceID='Ext' AND ParentID='./DevDetail'")
        if ($devDetail)
        {
            $hash = $devDetail.DeviceHardwareData
        }
        else
        {
            $hash = ""
        }
        Remove-CimSession $session
    }
}
End
{
    if(!($GroupTag)) {
        $PostData = @{
            'hardwareIdentifier' = "$hash"
        } | ConvertTo-Json
    } else {
        $PostData = @{
            'hardwareIdentifier' = "$hash"
            'groupTag' = "$GroupTag"
        } | ConvertTo-Json
    }

    $Post =  Invoke-RestMethod -Method POST -Uri "https://$MSGraphHost/$MsGraphVersion/devicemanagement/importedWindowsAutopilotDeviceIdentities" -Headers @{Authorization = "Bearer $AccessToken"; 'Content-Type' = 'application/json'} -Body $PostData
    DO {
        Write-Host "Waiting for device import"
        Start-Sleep 10
    }
    UNTIL ((Invoke-RestMethod -Method Get -Uri "https://$MsGraphHost/$MsGraphVersion/Devicemanagement/importedwindowsautopilotdeviceidentities/$($Post.ID)" -Headers @{Authorization = "Bearer $AccessToken"} | Select-Object -ExpandProperty State) -NOTmatch "unknown")
    Invoke-RestMethod -Method Get -Uri "https://$MsGraphHost/$MsGraphVersion/Devicemanagement/importedwindowsautopilotdeviceidentities/$($Post.ID)" -Headers @{Authorization = "Bearer $AccessToken"} | Select-Object -ExpandProperty State
}
