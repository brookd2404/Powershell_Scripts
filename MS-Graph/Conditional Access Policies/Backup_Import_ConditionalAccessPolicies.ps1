param(
    [Parameter(DontShow = $true)]
    [string]
    $MsGraphVersion = "beta",
    [Parameter(DontShow = $true)]
    [string]
    $MsGraphHost = "graph.microsoft.com",
    #The AzureAD ClientID (Application ID) of your registered AzureAD App with Delegate permissions
    [string]
    $DelegateClientID,
    #The AzureAD ClientID (Application ID) of your registered AzureAD App
    [string]
    $ClientID,
    #The Client Secret for your AzureAD App
    [string]
    $ClientSecret,
    #Your Azure Tenent ID
    [string]
    $TenantId,
    [Parameter()]
    [string]
    $OutputFolder = ".\ConditionalAccessPolicyBackup",
    [switch]
    $Import,
    [string]
    $ImportJSON

)#

FUNCTION Connect-AzAD_Token ($DelegateID){
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
                Write-Host -ForegroundColor Red "Failed to install the AzureAD PowerShell Module `n $($Error[0])"
                break 
            }
           
        }

    } else {
        Write-Host -ForegroundColor Green "AzureAD Powershell Module Found"
    }

    $AADMod = ($AADMod | Select-Object -Unique | Sort-Object)[-1]
    
    $ADAL = Join-Path $AADMod.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
    $ADALForms = Join-Path $AADMod.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"
    [System.Reflection.Assembly]::LoadFrom($ADAL) | Out-Null
    [System.Reflection.Assembly]::LoadFrom($ADALForms) | Out-Null

    $UserInfo = Connect-AzureAD

    # Your Azure Application ID 
    $MIPEAClientID = $DelegateID
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
        $authResult = $AuthContext.AcquireTokenAsync(("https://" + $MSGraphHost),$MIPEAClientID,$RedirectURI,$platformParameters,$userId).Result
        # If the accesstoken is valid then create the authentication header
        if($authResult.AccessToken){
            # Creating header for Authorization token
            $AADAccessToken = $authResult.AccessToken
            return $AADAccessToken
        } else {
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
# Web page used to help with getting the access token 
#https://morgantechspace.com/2019/08/get-graph-api-access-token-using-client-id-and-client-secret.html 


if (($ClientID) -and ($ClientSecret) -and ($TenantId) ) {
    #Create the body of the Authentication of the request for the OAuth Token
    $Body = @{client_id=$ClientID;client_secret=$ClientSecret;grant_type="client_credentials";scope="https://$MSGraphHost/.default";}
    #Get the OAuth Token 
    $OAuthReq = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" -Body $Body
    #Set your access token as a variable
    $global:AccessToken = $OAuthReq.access_token
} else {
    if (!($DelegateClientID))
    {
        Write-Host -ForegroundColor Red "You must specify a clientID which has the correct delegate permissions and URI Re-write configuration "
        break
    }
    $global:AccessToken = Connect-AzAD_Token -DelegateID $DelegateClientID
}

IF (!($Import)) {
    $FormattedOutputFolder = "$OutputFolder\$(Get-Date -Format yyyyMMdd_HH-mm-ss)"

    IF (!(Test-Path $FormattedOutputFolder)){
        try {
            mkdir $FormattedOutputFolder -ErrorAction Stop | Out-Null
        }
        catch {
            Write-Host -ForegroundColor Red "Failed to create $FormattedOutputFolder"
            $Error[0]
            break
        }
        
    }

    Invoke-RestMethod -Method GET -Uri "https://$MSGraphHost/$MsGraphVersion/identity/conditionalAccess/policies" -Headers @{Authorization = "Bearer $AccessToken"} -ContentType "application/json" | Select-Object -ExpandProperty "Value" | %{
       $_ | ConvertTo-Json -Depth 10 | Out-File "$FormattedOutputFolder\$($_.displayname).json"
    } 
}elseif ($Import) {
    $JSON = Get-Content $ImportJSON | ConvertFrom-Json | Select-Object -Property * -ExcludeProperty Version,modifiedDateTime,CreatedDateTime,id,sessionControls | ConvertTo-Json -Depth 10
  
    Invoke-RestMethod -Method POST -Uri "https://$MSGraphHost/$MsGraphVersion/identity/conditionalAccess/policies" -Headers @{Authorization = "Bearer $AccessToken"} -Body $JSON -ContentType "application/json"    
}