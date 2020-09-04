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
    $OutputFolder = ".\ConditionalAccessPolicyBackup",
    [switch]
    $Import,
    [string]
    $ImportJSON

)#


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
    Write-Host -ForegroundColor Red "Required Information Not Provided (ClientID, ClientSecret and TenantID)"
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

    Invoke-RestMethod -Method GET -Uri "https://$MSGraphHost/$MsGraphVersion/identity/conditionalAccess/policies" -Headers @{Authorization = "Bearer $AccessToken"} | Select-Object -ExpandProperty "Value" | %{
       $_ | ConvertTo-Json | Out-File "$FormattedOutputFolder\$($_.displayname).json"
    } 
}elseif ($Import) {
    $JSON = Get-Content $ImportJSON | ConvertFrom-Json | Select-Object -Property * -ExcludeProperty Version,LastModifiedTime,CreatedDateTime,id | ConvertTo-Json
    $Context = '{
    "@odata.context":  "https://graph.microsoft.com/beta/$metadata#identity/conditionalAccess/policies",
    "roleScopeTagIds":  [
                            "0"
                        ],'
    
    $Json = $Context + $Json.TrimStart("{")
    Invoke-RestMethod -Method POST -Uri "https://$MSGraphHost/$MsGraphVersion/deviceManagement/deviceCompliancePolicies" -Headers @{Authorization = "Bearer $AccessToken"} -Body $JSON -ContentType "application/json"    
}