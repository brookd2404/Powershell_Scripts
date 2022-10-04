Param (
    [string]
    $GraphBaseURL = "https://graph.microsoft.com/",
    [string]
    $GraphVersion = "beta",
    [string]
    $GraphURL = $GraphBaseURL + $GraphVersion,
    [String]
    $TenantID,
    [String]
    $ClientID,
    [String]
    $ClientSecret
)
Import-Module "$PSScriptRoot\Connect-AZADToken.psm1"
#Import-Module Connect-AzAD_Token
$ConnectParams = @{}
IF ($TenantID) {$ConnectParams.Add('Tenant',$TenantID)}
IF ($ClientID) {$ConnectParams.Add('ClientID',$ClientID)}
IF ($ClientSecret) {$ConnectParams.Add('ClientSecret',$ClientSecret)}

$global:AccessToken = Connect-AzAD_Token @ConnectParams
$global:Intune_Headers =  @{Authorization = "Bearer $AccessToken"}

$IntuneWindowsDevices = @{
    Method = "GET"
    URI = "$GraphURL/devicemanagement/managedDevices?filter=operatingSystem eq 'Windows'"
    Headers = $Intune_Headers
    ContentType = "Application/JSON"
}

$DevicesFromIntune = Invoke-RestMethod @IntuneWindowsDevices
$global:All_DevicesFromIntune = @()
$All_DevicesFromIntune += $DevicesFromIntune
$Count = 1
while($DevicesFromIntune.'@odata.nextLink' -ne $null) {
    Write-Host -ForegroundColor Green "Querying Azure AD Devices @od$ata.next link NO: $($Count)..."
    $DevicesFromIntune = Invoke-RestMethod -Method Get -Uri $DevicesFromIntune.'@odata.nextLink' -Headers @{Authorization = "Bearer $AccessToken"} -ContentType "application/json"
    $All_DevicesFromIntune += $DevicesFromIntune
    $Count++
}

$Intune_DetectedApps_Params = @{
    Method = "GET"
    URI = "$GraphURL/devicemanagement/detectedApps"
    Headers = $Intune_Headers
    ContentType = "Application/JSON"
} 

$Intune_DetectedApps = Invoke-RestMethod @Intune_DetectedApps_Params
$global:All_DetectedApps = @()
$All_DetectedApps += $Intune_DetectedApps.Value
$Count = 1
while($Intune_DetectedApps.'@odata.nextLink' -ne $null) {
    Write-Host -ForegroundColor Green "Querying Azure AD Devices @odata.next link NO: $($Count)..."
    $Intune_DetectedApps = Invoke-RestMethod -Method Get -Uri $Intune_DetectedApps.'@odata.nextLink' -Headers @{Authorization = "Bearer $AccessToken"} -ContentType "application/json"
    $All_DetectedApps += $Intune_DetectedApps.Value
    $Count++
}

$All_DetectedApps | ConvertTO-JSON -Depth 5 | Out-File .\DetectedApps.json

$ExportInfo = @()
$device_detectedApps = @()
foreach ($Device in $All_DevicesFromIntune.value) {
    $PerDeviceSplat = @{
        Method = "GET"
        URI = "$GraphURL/devicemanagement/managedDevices('$($Device.id)')/detectedApps?`$select=id,displayName"
        Headers = $Intune_Headers
        ContentType = "Application/JSON"
    }

    $Device_Expanded_Info = Invoke-RestMethod @PerDeviceSplat

    $JsonOutput = @{}
    $JsonOutput.Device = @{}
    $JsonOutput.Device.ID = $Device.id 
    $JsonOutput.Device.Name = $Device.deviceName
    $JsonOutput.Device.Apps = $Device_Expanded_Info.Value
    
    $device_detectedApps += $JsonOutput

    foreach ($app in $Device_Expanded_Info.value) {
        $DeviceAppInfo = New-Object PSObject
        $DeviceAppInfo | Add-Member -MemberType NoteProperty -Name "DeviceName" -Value $Device.deviceName
        $DeviceAppInfo | Add-Member -MemberType NoteProperty -Name "DeviceID" -Value $Device.id
        $DeviceAppInfo | Add-Member -MemberType NoteProperty -Name "AppID" -Value $app.id
        $DeviceAppInfo | Add-Member -MemberType NoteProperty -Name "AppName" -Value $app.displayName

        $ExportInfo += $DeviceAppInfo  
    }

}

$ExportInfo | Export-CSV -NoTypeInformation ".\$(Get-Date -Format yyyy-MM-dd)-Test.csv"

#$device_detectedApps | ConvertTo-Json -Depth 5 | Out-File .\deivce_DetectedApps.json
