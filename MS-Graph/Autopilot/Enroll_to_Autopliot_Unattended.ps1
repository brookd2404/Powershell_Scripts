  
<#PSScriptInfo
 
    .VERSION 3.0
    
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
    Version 3.0: Added a check for device registration before attempting to import the device, the script will also update the group tag if a new one is specified.
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

Begin {
    FUNCTION Connect-AzAD_Token {
        Write-Host -ForegroundColor Cyan "Checking for AzureAD module..."
        $AADMod = Get-Module -Name "AzureAD" -ListAvailable
    
        if (!($AADMod)) {
            Write-Host -ForegroundColor Yellow "AzureAD PowerShell module not found, looking for AzureADPreview"
            $AADModPrev = Get-Module -Name "AzureADPreview" -ListAvailable
            #Check to see if the AzureAD Preview Module is insalled, If so se that as the AAD Module Else Insall the AzureAD Module
            IF ($AADModPrev) {
                $AADMod = Get-Module -Name "AzureADPreview" -ListAvailable
            }
            else {
                try {
                    Write-Host -ForegroundColor Yello "AzureAD Preview is not installed..."
                    Write-Host -ForegroundColor Cyan "Attempting to Install the AzureAD Powershell module..."
                    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -ErrorAction Stop | Out-Null
                    Install-Module AzureAD -Force -ErrorAction Stop
                }
                catch {
                    Write-Host -ForegroundColor Red "Failed to install the AzureAD PowerShell Module `n $($Error[0])"
                    break 
                }
               
            }
    
        }
        else {
            Write-Host -ForegroundColor Green "AzureAD Powershell Module Found"
        }
    
        $AADMod = ($AADMod | Select-Object -Unique | Sort-Object)[-1]
        
        $ADAL = Join-Path $AADMod.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
        $ADALForms = Join-Path $AADMod.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"
        [System.Reflection.Assembly]::LoadFrom($ADAL) | Out-Null
        [System.Reflection.Assembly]::LoadFrom($ADALForms) | Out-Null
    
        $UserInfo = Connect-AzureAD
    
        # Microsoft Intune PowerShell Enterprise Application ID 
        $MIPEAClientID = "d1ddf0e4-d672-4dae-b554-9d5bdfd93547"
        # The redirectURI
        $RedirectURI = "urn:ietf:wg:oauth:2.0:oob"
        #The Authority to connect with (YOur Tenant)
        Write-Host -Foregroundcolor Cyan "Connected to Tenant: $($UserInfo.TenantID)"
        $Auth = "https://login.microsoftonline.com/$($UserInfo.TenantID)"
    
        try {
            $AuthContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $Auth
            
            # https://msdn.microsoft.com/en-us/library/azure/microsoft.identitymodel.clients.activedirectory.promptbehavior.aspx
            # Change the prompt behaviour to force credentials each time: Auto, Always, Never, RefreshSession
            $platformParameters = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.PlatformParameters" -ArgumentList "Auto"
            $userId = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.UserIdentifier" -ArgumentList ($UserInfo.Account, "OptionalDisplayableId")
            $authResult = $AuthContext.AcquireTokenAsync(("https://" + $MSGraphHost), $MIPEAClientID, $RedirectURI, $platformParameters, $userId).Result
            # If the accesstoken is valid then create the authentication header
            if ($authResult.AccessToken) {
                # Creating header for Authorization token
                $AADAccessToken = $authResult.AccessToken
                return $AADAccessToken
            }
            else {
                Write-Host -ForegroundColor Red "Authorization Access Token is null, please re-run authentication..."
                break
            }
        }
        catch {
            Write-Host -ForegroundColor Red $_.Exception.Message
            Write-Host -ForegroundColor Red $_.Exception.ItemName
            break
        }
    }
            
    if (($ClientID) -and ($ClientSecret) -and ($TenantId) ) {
        #Create the body of the Authentication of the request for the OAuth Token
        $Body = @{client_id = $ClientID; client_secret = $ClientSecret; grant_type = "client_credentials"; scope = "https://$MSGraphHost/.default"; }
        #Get the OAuth Token 
        $OAuthReq = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" -Body $Body
        #Set your access token as a variable
        $global:AccessToken = $OAuthReq.access_token
    }
    else {
        $global:AccessToken = Connect-AzAD_Token
    }
}
Process {
    $PostData = @{} #A blank hash table to store the data to be posted
    $session = New-CimSession 
    $serial = (Get-CimInstance -CimSession $session -Class Win32_BIOS).SerialNumber #Get the serial number of the device
    Write-Verbose "Checking if Device with serail number $serial is already registered"
    $apDeviceIdentatiesPost = (Invoke-RestMethod -Method GET -Uri "https://$MSGraphHost/$MsGraphVersion/devicemanagement/windowsAutopilotDeviceIdentities?`$filter=contains(serialNumber,'$serial')" `
            -Headers @{Authorization = "Bearer $AccessToken"; 'Content-Type' = 'application/json' }).value 

    IF (-not($apDeviceIdentatiesPost)) {
        Write-Verbose "Device with serial number $serial is not registered."
        $uploadRequired = $true
    }
    else {
        Write-Verbose "Device with serial number $serial is already registered."
    }

    if (!$Hash -and ($uploadRequired -eq $true)) {
        # Get the common properties.
        Write-Verbose "Checking $comp"
        # Get the hash (if available)
        $devDetail = (Get-CimInstance -CimSession $session -Namespace root/cimv2/mdm/dmmap -Class MDM_DevDetail_Ext01 -Filter "InstanceID='Ext' AND ParentID='./DevDetail'")
        if ($devDetail) {
            $hash = $devDetail.DeviceHardwareData
        }
        Remove-CimSession $session
    }

    if ($Hash) {
        Write-Verbose "Adding the hash to the post data"
        $PostData | Add-Member -MemberType NoteProperty -Name hardwareIdentifier -Value $Hash
    }

    IF ($GroupTag) {
        Write-Verbose "Checking if Group Tag is set"
        IF ($apDeviceIdentatiesPost) {
            IF (-not($apDeviceIdentatiesPost.groupTag -match $GroupTag)) {
                Write-Verbose "Group Tag is not set to $GroupTag"
                $updateGroupTag = $true
                Write-Verbose "Adding the Group Tag to the post data"
                $PostData | Add-Member -MemberType NoteProperty -Name groupTag -Value $GroupTag
            }
            ELSE {
                Write-Verbose "The Group Tag is already set to $GroupTag"
            }
        }
        ELSE {
            Write-Verbose "Adding the Group Tag to the post data"
            $PostData | Add-Member -MemberType NoteProperty -Name groupTag -Value $GroupTag
        }
    }
}
End {

    IF ($uploadRequired -eq $true) {
        $Post = Invoke-RestMethod -Method POST -Uri "https://$MSGraphHost/$MsGraphVersion/devicemanagement/importedWindowsAutopilotDeviceIdentities" `
            -Headers @{Authorization = "Bearer $AccessToken"; 'Content-Type' = 'application/json' } `
            -Body ($PostData | ConvertTo-Json)
        
        DO {
            Write-Host "Waiting for device import"
            Start-Sleep 10
        }
        UNTIL ((Invoke-RestMethod -Method Get -Uri "https://$MsGraphHost/$MsGraphVersion/Devicemanagement/importedwindowsautopilotdeviceidentities/$($Post.ID)" -Headers @{Authorization = "Bearer $AccessToken" } | Select-Object -ExpandProperty State) -NOTmatch "unknown")
        #Output the state of the device
        Invoke-RestMethod -Method Get -Uri "https://$MsGraphHost/$MsGraphVersion/Devicemanagement/importedwindowsautopilotdeviceidentities/$($Post.ID)" -Headers @{Authorization = "Bearer $AccessToken" } | Select-Object -ExpandProperty State    
    }
    elseif ($updateGroupTag -eq $true) {
        $Post = Invoke-RestMethod -Method POST -Uri "https://$MSGraphHost/$MsGraphVersion/devicemanagement/windowsAutopilotDeviceIdentities/$($apDeviceIdentatiesPost.id)/updateDeviceProperties" `
            -Headers @{Authorization = "Bearer $AccessToken"; 'Content-Type' = 'application/json' } `
            -Body ($PostData | ConvertTo-Json)
        
        Write-Verbose "The Group Tag for $serial has been updated to $groupTag"
        #This action may take up to 5 minutes to show in the Intune console
    }
}
