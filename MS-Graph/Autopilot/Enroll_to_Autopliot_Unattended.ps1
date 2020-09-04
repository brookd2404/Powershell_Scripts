  
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
    $ClientID,
    #The Client Secret for your AzureAD App
    [string]
    $ClientSecret,
    #Your Azure Tenent ID
    [string]
    $TenantId,
    [string]
    $Hash,
    [string]
    $GroupTag
)

Begin
{
    function Get-AuthToken {
        <#
        .SYNOPSIS
        This function is used to authenticate with the Graph API REST interface
        .DESCRIPTION
        The function authenticate with the Graph API Interface with the tenant name
        .EXAMPLE
        Get-AuthToken
        Authenticates you with the Graph API interface
        .NOTES
        NAME: Get-AuthToken
        #>
    
        [cmdletbinding()]
    
        param
        (
            [Parameter(Mandatory=$true)]
            $User
        )
    
        $userUpn = New-Object "System.Net.Mail.MailAddress" -ArgumentList $User
    
        $tenant = $userUpn.Host
    
        Write-Host "Checking for AzureAD module..."
    
            $AadModule = Get-Module -Name "AzureAD" -ListAvailable
    
            if ($AadModule -eq $null) {
    
                Write-Host "AzureAD PowerShell module not found, looking for AzureADPreview"
                $AadModule = Get-Module -Name "AzureADPreview" -ListAvailable
    
            }
    
            if ($AadModule -eq $null) {
                write-host
                write-host "AzureAD Powershell module not installed..." -f Red
                write-host "Install by running 'Install-Module AzureAD' or 'Install-Module AzureADPreview' from an elevated PowerShell prompt" -f Yellow
                write-host "Script can't continue..." -f Red
                write-host
                exit
            }
    
        # Getting path to ActiveDirectory Assemblies
        # If the module count is greater than 1 find the latest version
    
            if($AadModule.count -gt 1){
    
                $Latest_Version = ($AadModule | select version | Sort-Object)[-1]
    
                $aadModule = $AadModule | ? { $_.version -eq $Latest_Version.version }
    
                    # Checking if there are multiple versions of the same module found
    
                    if($AadModule.count -gt 1){
    
                    $aadModule = $AadModule | select -Unique
    
                    }
    
                $adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
                $adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"
    
            }
    
            else {
    
                $adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
                $adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"
    
            }
    
        [System.Reflection.Assembly]::LoadFrom($adal) | Out-Null
    
        [System.Reflection.Assembly]::LoadFrom($adalforms) | Out-Null
    
        $clientId = "d1ddf0e4-d672-4dae-b554-9d5bdfd93547"
    
        $redirectUri = "urn:ietf:wg:oauth:2.0:oob"
    
        $resourceAppIdURI = "https://graph.microsoft.com"
    
        $authority = "https://login.microsoftonline.com/$Tenant"
    
            try {
    
            $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority
    
            # https://msdn.microsoft.com/en-us/library/azure/microsoft.identitymodel.clients.activedirectory.promptbehavior.aspx
            # Change the prompt behaviour to force credentials each time: Auto, Always, Never, RefreshSession
    
            $platformParameters = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.PlatformParameters" -ArgumentList "Auto"
    
            $userId = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.UserIdentifier" -ArgumentList ($User, "OptionalDisplayableId")
    
            $authResult = $authContext.AcquireTokenAsync($resourceAppIdURI,$clientId,$redirectUri,$platformParameters,$userId).Result
    
                # If the accesstoken is valid then create the authentication header
    
                if($authResult.AccessToken){
    
                # Creating header for Authorization token
    
                $authHeader = @{
                    'Content-Type'='application/json'
                    'Authorization'= $authResult.AccessToken
                    'ExpiresOn'=$authResult.ExpCoiresOn
                    }
    
                return $authHeader
    
                }
    
                else {
    
                Write-Host
                Write-Host "Authorization Access Token is null, please re-run authentication..." -ForegroundColor Red
                Write-Host
                break
    
                }
    
            }
    
            catch {
    
            write-host $_.Exception.Message -f Red
            write-host $_.Exception.ItemName -f Red
            write-host
            break
    
            }
        }
            
    if (($ClientID) -and ($ClientSecret) -and ($TenantId) ) {
        #Create the body of the Authentication of the request for the OAuth Token
        $Body = @{client_id=$ClientID;client_secret=$ClientSecret;grant_type="client_credentials";scope="https://$MSGraphHost/.default";}
        #Get the OAuth Token 
        $OAuthReq = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" -Body $Body
        #Set your access token as a variable
        $global:AccessToken = $OAuthReq.access_token
    } else {
        $AADLogin = Connect-AzureAD
        $global:AccessToken = (Get-AuthToken -User $AADLogin.Account).Authorization
        Write-Host "Connected to tenant $($graph.TenantId)"
    }
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
