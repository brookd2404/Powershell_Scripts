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
    [Parameter()]
    [string]
    $OutputFolder = ".\ConfigurationProfileBackup",
    [switch]
    $Import,
    [string]
    $importJSON
)


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
    $AADLogin = Connect-AzureAD
    $global:AccessToken = (Get-AuthToken -User $AADLogin.Account).Authorization
    Write-Host "Connected to tenant $($graph.TenantId)"
}

if ($Import)
{
    IF ($ImportJSON){
        #$JSON = GET-Content $ImportJSON
        $JSON = Get-Content $ImportJSON | ConvertFrom-Json | Select-Object -Property * -ExcludeProperty Version,LastModifiedTime,CreatedDateTime,id,supportsScopeTags | ConvertTo-Json
        
        Invoke-RestMethod -Method POST -Uri "https://$MSGraphHost/$MsGraphVersion/deviceManagement/deviceConfigurations" -Headers @{Authorization = "Bearer $AccessToken"} -Body $JSON -ContentType "application/json"    
    } else {
        Write-Host -ForegroundColor RED "You must specify an a JSON file using the -ImportJSON parameter"
    }

} else {
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

    Invoke-RestMethod -Method GET -Uri "https://$MSGraphHost/$MsGraphVersion/deviceManagement/deviceConfigurations" -Headers @{Authorization = "Bearer $AccessToken"} | Select-Object -ExpandProperty "Value" | %{
        $_ | ConvertTo-Json | Out-File "$FormattedOutputFolder\$($_.displayname).json"        
    }    
}


