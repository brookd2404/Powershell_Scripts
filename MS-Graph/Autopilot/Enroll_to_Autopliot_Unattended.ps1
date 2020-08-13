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
    $Hash,
    [string]
    $GroupTag
)

Begin
{
    #Create the body of the Authentication of the request for the OAuth Token
    $Body = @{client_id=$ClientID;client_secret=$ClientSecret;grant_type="client_credentials";scope="https://$MSGraphHost/.default";}
    #Get the OAuth Token 
    $OAuthReq = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" -Body $Body
    #Set your access token as a variable
    $global:AccessToken = $OAuthReq.access_token
}
Process
{
    if(!$Hash) {
        $session = New-CimSession
        # Get the common properties.
        Write-Verbose "Checking $comp"
        $serial = (Get-CimInstance -CimSession $session -Class Win32_BIOS).SerialNumber
        # Get the hash (if available)
        $devDetail = (Get-CimInstance -CimSession $session -Namespace root/cimv2/mdm/dmmap -Class MDM_DevDetail_Ext01 -Filter "InstanceID='Ext' AND ParentID='./DevDetail'")
        if ($devDetail)
        {
            $hash = $devDetail.DeviceHardwareData
        }
        else
        {
            $hash = ""
        }
        Remove-CimSession $session
    }
}
End
{
    if(!($GroupTag)) {
        $PostData = @{
            'hardwareIdentifier' = "$hash"
        } | ConvertTo-Json
    } else {
        $PostData = @{
            'hardwareIdentifier' = "$hash"
            'groupTag' = "$GroupTag"
        } | ConvertTo-Json
    }

    $Post =  Invoke-RestMethod -Method POST -Uri "https://$MSGraphHost/$MsGraphVersion/devicemanagement/importedWindowsAutopilotDeviceIdentities" -Headers @{Authorization = "Bearer $AccessToken"; 'Content-Type' = 'application/json'} -Body $PostData
    DO {
        Write-Host "Waiting for device import"
        Start-Sleep 10
    }
    UNTIL ((Invoke-RestMethod -Method Get -Uri "https://$MsGraphHost/$MsGraphVersion/Devicemanagement/importedwindowsautopilotdeviceidentities/$($Post.ID)" -Headers @{Authorization = "Bearer $AccessToken"} | Select-Object -ExpandProperty State) -NOTmatch "unknown")
    Invoke-RestMethod -Method Get -Uri "https://$MsGraphHost/$MsGraphVersion/Devicemanagement/importedwindowsautopilotdeviceidentities/$($Post.ID)" -Headers @{Authorization = "Bearer $AccessToken"} | Select-Object -ExpandProperty State
}
