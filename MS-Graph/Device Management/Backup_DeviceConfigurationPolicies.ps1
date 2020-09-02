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
    $OutputFolder = ".\ConfigurationProfileBackup"
)
# Web page used to help with getting the access token 
#https://morgantechspace.com/2019/08/get-graph-api-access-token-using-client-id-and-client-secret.html 

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


if (($ClientID) -and ($ClientSecret) -and ($TenantId) ) {
    #Create the body of the Authentication of the request for the OAuth Token
    $Body = @{client_id=$ClientID;client_secret=$ClientSecret;grant_type="client_credentials";scope="https://$MSGraphHost/.default";}
    #Get the OAuth Token 
    $OAuthReq = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" -Body $Body
    #Set your access token as a variable
    $global:AccessToken = $OAuthReq.access_token

    Invoke-RestMethod -Method GET -Uri "https://$MSGraphHost/$MsGraphVersion/deviceManagement/deviceConfigurations" -Headers @{Authorization = "Bearer $AccessToken"} | Select-Object -ExpandProperty "Value" | %{
        $_ | ConvertTo-Json | Out-File "$FormattedOutputFolder\$($_.displayname).json"        
    }
} else {
    Write-Host -ForegroundColor Cyan "Attempting to Import the Microsoft.Graph.Intune Module"
    $module = Import-Module Microsoft.Graph.Intune -PassThru -ErrorAction Ignore
    if (-not $module) {
        Write-Host -ForegroundColor Red "Microsoft.Graph.Intune Module not installed"
        try {
            Write-Host -ForegroundColor Cyan "Installing the Microsoft.Graph.Intune module"
            Install-Module Microsoft.Graph.Intune -ErrorAction Stop -Force
        }
        catch {
            Write-Host -ForegroundColor Red "Failed to install the Microsoft.Graph.Intune module"
            $Error[0]
            break
        }
        
    }
    Import-Module Microsoft.Graph.Intune
    Write-Host -ForegroundColor Green "Microsoft.Graph.Intune Module Imported"
    $graph = Connect-MSGraph
    Write-Host "Connected to tenant $($graph.TenantId)"
    
    Get-DeviceManagement_DeviceConfigurations | % {
        $_ | ConvertTo-Json | Out-File "$FormattedOutputFolder\$($_.displayname).json"
    }

}

