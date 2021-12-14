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
    #The Azure AD Group Object ID
    [string]
    $GroupID,
    #The name of the User
    [string]
    $InputUser = (whoami /upn)
)

#Create the body of the Authentication of the request for the OAuth Token
$Body = @{client_id=$ClientID;client_secret=$ClientSecret;grant_type="client_credentials";scope="https://$MSGraphHost/.default";}
#Get the OAuth Token 
$OAuthReq = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" -Body $Body
#Set your access token as a variable
$global:AccessToken = $OAuthReq.access_token

$GroupMembers = Invoke-RestMethod -Method Get -uri "https://$MSGraphHost/$MsGraphVersion/groups/$GroupID/members" -Headers @{Authorization = "Bearer $AccessToken"} | Select-Object -ExpandProperty Value

$User = Invoke-RestMethod -Method Get -uri "https://$MSGraphHost/$MSGraphVersion/users?`$filter=startswith(userPrincipalName,'$InputUser')" -Headers @{Authorization = "Bearer $AccessToken"} | Select-Object -ExpandProperty Value | %{ 

    if ($GroupMembers.ID -contains $_.id) {
        Write-Host -ForegroundColor Yellow "$($_.DisplayName) ($($_.ID)) is in the Group"   
    } else {
        Write-Host -ForegroundColor Green "Adding $($_.DisplayName) ($($_.ID)) To The Group"
        $BodyContent = @{
            "@odata.id"="https://graph.microsoft.com/v1.0/users/$($_.id)"
        } | ConvertTo-Json
        Invoke-RestMethod -Method POST -uri "https://$MSGraphHost/$MsGraphVersion/groups/$GroupID/members/`$ref" -Headers @{Authorization = "Bearer $AccessToken"; 'Content-Type' = 'application/json'} -Body $BodyContent
    }
}
