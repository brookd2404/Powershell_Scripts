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
    $ClientSecret = "<YourClientSecret>",
    #Your Azure Tenent ID
    [string]
    $TenantId = "<YourTenent>"
)
# Web page used to help with getting the access token 
#https://morgantechspace.com/2019/08/get-graph-api-access-token-using-client-id-and-client-secret.html 

#Create the body of the Authentication of the request for the OAuth Token
$Body = @{client_id=$ClientID;client_secret=$ClientSecret;grant_type="client_credentials";scope="https://$MSGraphHost/.default";}
#Get the OAuth Token 
$OAuthReq = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" -Body $Body
#Set your access token as a variable
$global:AccessToken = $OAuthReq.access_token

Invoke-RestMethod -Method GET -Uri "https://$MSGraphHost/$MsGraphVersion/deviceManagement/deviceConfigurations" -Headers @{Authorization = "Bearer $AccessToken"} | Select-Object -ExpandProperty "Value" | %{
    New-Object PSOBject @{
        DisplayName = $_.DisplayName
    } | Out-Null
    Write-Host "$Displayname Has the following Assignments"
    Invoke-RestMethod -Method GET -Uri "https://$MSGraphHost/$MsGraphVersion/deviceManagement/deviceConfigurations/$($_.id)/Assignments" -Headers @{Authorization = "Bearer $AccessToken"} | Select-Object -ExpandProperty "Value" | Select-Object -ExpandProperty Target | Select-Object -ExpandProperty groupID | % {
        Write-Host "$($_)"
    }     
}