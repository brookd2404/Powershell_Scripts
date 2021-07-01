[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [ValidateScript({
        Test-Path -Path $_
    })]
    $CSV,
    [String]
    $TenantID,
    [String]
    $ClientID,
    [String]
    $ClientSecret
)

$ADTokenMod = Get-Module -Name "Connect-AzAD_Token" -ListAvailable

if (!($ADTokenMod)) {
    Write-Warning "Connect-AZAD_Token PowerShell module not found, Installing"
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -ErrorAction Stop | Out-Null
    Install-Module "Connect-AzAD_Token" -Force -ErrorAction Stop
}

$ConnectParams = @{}
IF ($TenantID) {$ConnectParams.Add('Tenant',$TenantID)}
IF ($ClientID) {$ConnectParams.Add('ClientID',$ClientID)}
IF ($ClientSecret) {$ConnectParams.Add('ClientSecret',$ClientSecret)}
$AccessToken = (Connect-AZAD_Token @ConnectParams).AccessToken
$GraphHeader = @{Authorization = "Bearer $AccessToken)"}

$ImportedCSV = Import-CSV -Path $CSV

$ImportObject = @{}
$ImportObject.importedDeviceIdentities = @()
$ImportObject.overwriteImportedDeviceIdentities = "false"

$InvalidDevices = @()

FOREACH ($Item in $ImportedCSV) {
    $itemObject = @{}
    $WarningCount = 0
    #$item.imei = $item.imei.Trim()

    IF ((-Not([String]::IsNullOrEmpty($Item.serial))) -or (-Not([String]::IsNullOrEmpty($Item.imei)))) {
        if (($Item.serial) -and ($Item.imei)) {
            $itemObject.Add("importedDeviceIdentityType","serialNumber")
            $itemObject.Add("importedDeviceIdentifier",$Item.serial)
        } elseif ($item.serial) {
            $itemObject.Add("importedDeviceIdentityType","serialNumber")
            $itemObject.Add("importedDeviceIdentifier",$Item.serial)
        } elseif ($item.imei) {
            IF((($item.imei).Length -eq 15)) {
                $itemObject.Add("importedDeviceIdentityType","imei")
                $itemObject.Add("importedDeviceIdentifier",$Item.imei)
            } else {
                $WarningCount += 1
                Write-Warning "Invalid IMEI specified, Unable to continue with this ($($item.name)) device" 
            }
        }
    } ELSE {
        $WarningCount += 1
        Write-Warning "No Serial or IMEI specified, Unable to continue with this ($($item.name)) device" 
    }


    IF (-Not([String]::IsNullOrEmpty($Item.platform))) {

        Switch ($Item.Platform) {
            ios {
                $itemObject.Add("platform","ios")
            }

            android {
                $itemObject.Add("platform","android")
            }
        }
    } ELSE {
        $WarningCount += 1
        Write-Warning "No platform specified, Unable to continue with this ($($item.name)) device" 
    }

    $itemObject.Add("@odata.type","#microsoft.graph.importedDeviceIdentity")

    IF (-Not([String]::IsNullOrEmpty($Item.description))) {
        $itemObject.Add("description",$item.description)
    }

    "Warning count is $WarningCount"
    if ($WarningCount -le 0) {
        $ImportObject.importedDeviceIdentities += $ItemObject  
    } else {
        $InvalidDevices += $Item
    }
}

$PostRequest = @{
    Method = "POST"
    URI = "https://graph.microsoft.com/beta/deviceManagement/importedDeviceIdentities/importDeviceIdentityList"
    BODY = ($ImportObject | ConvertTo-Json -Depth 10)
    Headers = $GraphHeader
    CONTENTTYPE = "application/Json"
}


#($ImportObject | ConvertTo-Json -Depth 10) | Set-Clipboard

Invoke-RestMethod @PostRequest

$InvalidDevices | Export-Csv -NoClobber -NoTypeInformation .\InvalidDevices.CSV