[CmdletBinding()]
param (
    [Parameter()]
    [String]$Tenant, # Tenant Name e.g. SmartyPants.com
    #[ValidateSet('Production','Pilot','Test')]
    #[string]
    #$CategoryName = "Production", # The Value you wish to set any unassigned devices to
    [Parameter(DontShow = $true)]
    [string]$MsGraphVersion = "beta",
    [Parameter(DontShow = $true)]
    [string]$MsGraphHost = "graph.microsoft.com",
    $GraphURI = "https://$MSGraphHost/$MsGraphVersion",
    [string]$TenantID,
    [string]$ClientID,
    [string]$ClientSecret
)


#If the script is called with the ClientID, ClientSecret and TenantID, Call for the OAuth token without a module. Otherwise connect with a GUI Prompt
IF (($ClientID) -and ($ClientSecret) -and ($TenantID)) {
    #Create the body of the Authentication of the request for the OAuth Token
    $Body = @{client_id=$ClientID;client_secret=$ClientSecret;grant_type="client_credentials";scope="https://$MSGraphHost/.default";}
    #Get the OAuth Token 
    $OAuthReq = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" -Body $Body
    #Return access token as a variable
    $AccessToken = @{}
    $AccessToken.AccessToken = $OAuthReq.access_token

} ELSE {
    #If the required Module is not installed, Attempt to install it.
    $RequireMod = Get-Module -Name "Connect-AzAD_Token" -ListAvailable
        if (!($RequireMod)) {
            try {
                Write-Warning "Connect-AzAD_Token Module Not Found`nAttempting to Install the Powershell module..."
                Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -ErrorAction Stop | Out-Null
                Install-Module "Connect-AzAD_token" -Force -ErrorAction Stop
                Write-Information -MessageData "Connect-AzAD_Token Module Installed"
            }
            catch {
                Throw "Failed to install the Connect-AzAD_Token PowerShell Module" 
            }   
        }
    #Return the Access token
    $AccessToken = Connect-AzAD_Token -Tenant $Tenant -ErrorAction Stop
}

$Graph_Headers =  @{Authorization = "Bearer $($AccessToken.AccessToken)"} #Create the Graph Authentication header

$d_CategorySplat = @{
    Method = "GET"
    URI = "$GraphURI/deviceManagement/deviceCategories"
    Headers = $Graph_Headers
    ContentType = "Application/JSON"
} # Create the Category Splat for the Post Rest Call

$d_Categories = Invoke-RestMethod @d_CategorySplat -ErrorAction Stop #Call for the information.
$d_CategoryID = ($d_Categories.value | Where-Object {$_.DisplayName -match $CategoryName}).id


$d_IntuneSplat = @{
    Method = "GET"
    URI = "$GraphURI/devicemanagement/managedDevices"
    Headers = $Graph_Headers
    ContentType = "Application/JSON"
}
$d_IntuneGraphResult = Invoke-RestMethod @d_IntuneSplat -ErrorAction Stop
$d_IntuneDevices = @()
$d_IntuneDevices += $d_IntuneGraphResult.value
$Count = 1
while(-not ([string]::IsNullOrEmpty($d_IntuneGraphResult.'@odata.nextLink'))) {
    Write-Output "Querying Azure AD Devices @odata.next link NO: $($Count)..."
    $d_IntuneGraphResult_NextLink = @{
        Method = "GET"
        URI = $d_IntuneGraphResult.'@odata.nextLink'
        Headers = $Graph_Headers
        ContentType = "application/JSON"
    }
    $d_IntuneGraphResult = Invoke-RestMethod @d_IntuneGraphResult_NextLink -ErrorAction Stop
    $d_IntuneDevices += $d_IntuneGraphResult.value
    $Count++
}

FOREACH ($Device in $d_IntuneDevices) {
    IF (($Device.operatingSystem -eq "Windows") -and -Not($Device.skuNumber -eq "175")) {
        if (([String]::IsNullOrEmpty($Device.deviceCategoryDisplayName)) -or ($Device.deviceCategoryDisplayName -Match "Unknown")){
            
            "Updating $($Device.deviceName) from $(
                if([String]::IsNullOrEmpty($Device.deviceCategoryDisplayName)){
                    "null"
                } else {
                    $Device.deviceCategoryDisplayName
                }
            ) category to $CategoryName"

            $UpdateCategorySplat = @{
                Method = "PUT"
                URI =  "$GraphURI/deviceManagement/managedDevices/$($Device.ID)/deviceCategory/`$ref"
                Headers = $Graph_Headers
                ContentType = "application/JSON"
                Body = @{ "@odata.id" = "https://graph.microsoft.com/beta/deviceManagement/deviceCategories/$d_CategoryID"} | ConvertTo-Json
            }

            Invoke-RestMethod @UpdateCategorySplat -ErrorAction Stop | Out-Null
        } 
        #Uncomment the below line to see all devices and categories 
        <#Else {
            "$($Device.deviceName) Has Category $($Device.deviceCategoryDisplayName)"

        }#>
    }
}