Param (
    [string]
    $Tenant,
    [Parameter(Mandatory = $true)]
    [string]
    $OutputPath
)

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
        [string]$Tenant
    )
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

$global:AccessToken = Connect-AzAD_Token -Tenant $Tenant

Write-Host -ForegroundColor Green "Querying Azure AD Devices..."
$DeviceRequest = Invoke-RestMethod -Method GET -Uri "$GraphURI/devices" -Headers @{Authorization = "Bearer $AccessToken"} #| Select -ExpandProperty Value

#$AuditLogRequest = Invoke-RestMethod -Uri $Uri -Headers $Header -Method Get -ContentType "application/json"

$DeviceReturn = @()
$DeviceReturn += $DeviceRequest.value

$Count = 1

while($DeviceRequest.'@odata.nextLink' -ne $null) {
    Write-Host -ForegroundColor Green "Querying Azure AD Devices @odata.next link NO: $($Count)..."
    $DeviceRequest = Invoke-RestMethod -Method Get -Uri $DeviceRequest.'@odata.nextLink' -Headers @{Authorization = "Bearer $AccessToken"} -ContentType "application/json"
    $DeviceReturn += $DeviceRequest.value
    $Count++
}

Write-Host -ForegroundColor Green "Filtering Objects..."
$FilteredObjects = $DeviceReturn | Where-Object {($_.onPremisesSyncEnabled -match "true")}

Write-Host -ForegroundColor Green "Exporting Objects to $($OutputPath)..."
$FilteredObjects | Export-CSV -Path $OutputPath -NoTypeInformation