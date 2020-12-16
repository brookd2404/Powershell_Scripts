Param (
    [string]$GraphVersion = "beta",
    [String]$TenantID,
    [String]$ClientID,
    [String]$ClientSecret,
    [string]$Output
)

IF (!([String]::IsNullOrEmpty($Output))) {
    IF (!(Test-Path (Split-Path $Output))) {
        try {
            MKDIR (Split-Path $Output) -ErrorAction Stop | Out-Null
        }
        catch {
            Write-Output $Error[0]
            Throw "Unable to create the directory $(split-path $Output)"
        }
    }
} else {
    Throw "The output directory cannot be created"
}
FUNCTION Connect-AzAD_Token {
    param (
        $DelegateID = "",
        [Parameter(DontShow = $true)]
        [string]
        $global:MsGraphVersion = "beta",
        [Parameter(DontShow = $true)]
        [string]
        $global:MsGraphHost = "graph.microsoft.com",
        $global:GraphURI = "https://$MSGraphHost/$MsGraphVersion",
        [string]$Tenant,
        [string]$ClientID,
        [string]$ClientSecret
    )

    IF (($ClientID) -and ($ClientSecret)) {
        #Create the body of the Authentication of the request for the OAuth Token
        $Body = @{client_id=$ClientID;client_secret=$ClientSecret;grant_type="client_credentials";scope="https://$MSGraphHost/.default";}
        #Get the OAuth Token 
        $OAuthReq = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" -Body $Body
        #Return access token as a variable
        $OAuthReq.access_token
    } ELSE {
        Write-Host -ForegroundColor Cyan "Checking for AzureAD module..."
        $AADMod = Get-Module -Name "AzureAD" -ListAvailable

        if (!($AADMod)) {
            Write-Host -ForegroundColor Yellow "AzureAD PowerShell module not found, looking for AzureADPreview"
            $AADModPrev = Get-Module -Name "AzureADPreview" -ListAvailable
            #Check to see if the AzureAD Preview Module is insalled, If so se that as the AAD Module Else Insall the AzureAD Module
            IF ($AADModPrev) {
                $AADMod = Get-Module -Name "AzureADPreview" -ListAvailable
            } else {
                try {
                    Write-Host -ForegroundColor Yello "AzureAD Preview is not installed..."
                    Write-Host -ForegroundColor Cyan "Attempting to Install the AzureAD Powershell module..."
                    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -ErrorAction Stop | Out-Null
                    Install-Module AzureAD -Force -ErrorAction Stop
                }
                catch {
                    Throw "Failed to install the AzureAD PowerShell Module" 
                }   
            }
        }

        $AADMod = ($AADMod | Select-Object -Unique | Sort-Object)[-1]
    
        $ADAL = Join-Path $AADMod.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
        $ADALForms = Join-Path $AADMod.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"
        [System.Reflection.Assembly]::LoadFrom($ADAL) | Out-Null
        [System.Reflection.Assembly]::LoadFrom($ADALForms) | Out-Null

        $global:UserInfo = Connect-AzureAD -ErrorAction Stop

        # Microsoft Intune PowerShell Enterprise Application ID 
        $MIPEAClientID = "d1ddf0e4-d672-4dae-b554-9d5bdfd93547"
    
        # The redirectURI
        $RedirectURI = "urn:ietf:wg:oauth:2.0:oob"
        #The Authority to connect with (YOur Tenant)
        IF ($Tenant) {
            $TenantID = $Tenant
        } Else {
            $TenantID = $UserInfo.TenantID
        }
        Write-Host -Foregroundcolor Cyan "Connected to Tenant: $TenantID"
        $Auth = "https://login.microsoftonline.com/$TenantID"

        try {
            $AuthContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $Auth
        
            # https://msdn.microsoft.com/en-us/library/azure/microsoft.identitymodel.clients.activedirectory.promptbehavior.aspx
            # Change the prompt behaviour to force credentials each time: Auto, Always, Never, RefreshSession
            $platformParameters = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.PlatformParameters" -ArgumentList "Auto"
            $userId = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.UserIdentifier" -ArgumentList ($UserInfo.Account, "OptionalDisplayableId")
            $global:authResult = $AuthContext.AcquireTokenAsync(("https://" + $MSGraphHost),$MIPEAClientID,$RedirectURI,$platformParameters,$userId).Result
            # If the accesstoken is valid then create the authentication header
            if($authResult.AccessToken){
                # Creating header for Authorization token
                $AADAccessToken = $authResult.AccessToken
                return $AADAccessToken
            } else {
                Throw "Authorization Access Token is null, please re-run authentication..."
            }
        }
        catch {
            Write-Host -ForegroundColor Red $_.Exception.Message
            Write-Host -ForegroundColor Red $_.Exception.ItemName
            Throw "There was an exception while running this module"
        }
    }
}

Write-Output "Setting API URL(s)"
[string]$Script:GraphURL = "https://graph.microsoft.com/" + $GraphVersion

$ConnectParams = @{}
IF ($TenantID) {$ConnectParams.Add('Tenant',$TenantID)}
IF ($ClientID) {$ConnectParams.Add('ClientID',$ClientID)}
IF ($ClientSecret) {$ConnectParams.Add('ClientSecret',$ClientSecret)}

try {
    Write-Output "Attempting Azure Authentication"
    $global:AccessToken = Connect-AzAD_Token @ConnectParams -ErrorAction Stop
    $global:Intune_Headers =  @{Authorization = "Bearer $AccessToken"}
    Write-Output "Azure Authentication Successful"
} catch {
    Write-Output $Error[0]
    Throw "Unable to connect to Azure AD"
}

try {
    Write-Output "Getting all Windows Update Rings"
    $AllUpdateRings = @{
        Method = "GET"
        URI = "$GraphURL/deviceManagement/deviceConfigurations?`$filter=isof('microsoft.graph.windowsUpdateForBusinessConfiguration')"
        Headers = $Intune_Headers
        ContentType = "Application/JSON"
    }

    $UpdateRings = Invoke-RestMethod @AllUpdateRings -ErrorAction Stop
    $global:All_UpdateRings = @()
    $All_UpdateRings += $UpdateRings
    $Count = 1
    while(!([String]::IsNullOrEmpty($UpdateRings.'@odata.nextLink'))) {
        Write-Output "Querying Azure AD Devices @odata.next link NO: $($Count)..."
        $UpdateRings_NextLink = @{
            Method = "GET"
            URI = $UpdateRings.'@odata.nextLink'
            Headers = $Intune_Headers
            ContentType = "application/JSON"
        }
        $UpdateRings = Invoke-RestMethod @UpdateRings_NextLink -ErrorAction Stop
        $All_UpdateRings += $UpdateRings
        $Count++
    }

    Write-Output "Update Ring Count $($All_UpdateRings.Value.Count)"
} catch {
    Write-Output $Error[0]
    Throw "Failed to get Update Rings"
}

$All_UpdateRings | Export-Csv C:\Temp\Test.csv

ForEach ($Ring in $AllUpdateRings) {
    Write-Output "Working on $($Ring.DisplayName)"


}