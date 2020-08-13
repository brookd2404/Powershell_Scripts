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

)
# Web page used to help with getting the access token 
#https://morgantechspace.com/2019/08/get-graph-api-access-token-using-client-id-and-client-secret.html 

#Create the body of the Authentication of the request for the OAuth Token
$Body = @{client_id=$ClientID;client_secret=$ClientSecret;grant_type="client_credentials";scope="https://$MSGraphHost/.default";}
#Get the OAuth Token 
$OAuthReq = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" -Body $Body
#Set your access token as a variable
$global:AccessToken = $OAuthReq.access_token

Invoke-RestMethod -Method GET -Uri "https://$MSGraphHost/$MsGraphVersion/deviceManagement/windowsAutopilotDeviceIdentities" -Headers @{Authorization = "Bearer $AccessToken"} | Select-Object -ExpandProperty "Value" | %{
    try {
        IF ($($_.ManagedDeviceid) -notmatch "00000000-0000-0000-0000-000000000000" ) {
            Invoke-RestMethod -Method GET -Uri "https://$MSGraphHost/$MsGraphVersion/deviceManagement/managedDevices/$($_.ManagedDeviceid)" -Headers @{Authorization = "Bearer $AccessToken"} | Select-Object ID, DeviceName, lastsyncdatetime,OperatingSystem,osVersion,azureADDeviceId,model,manufacturer,serialNumber,enrolledDateTime,userPrincipalName
            #Breakdown date and time 
            #Date: $($($APDevMan.enrolledDateTime).Split("T")[0]).SubString(0,10)
            #Time: $($($APDevMan.enrolledDateTime).Split("T")[1]).SubString(0,8)
        }
    }
    catch {
        Write-Host -ForegroundColor Red "Error Accessing Device Information: $($Error[0].Exception)"
    }    
}