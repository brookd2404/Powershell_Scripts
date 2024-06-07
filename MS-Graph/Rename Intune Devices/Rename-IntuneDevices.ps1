[CmdletBinding()]
param (
    [Parameter()]
    [String]
    $namePrefix = "DRN-"
)

Connect-MGGraph -Scopes 'DeviceManagementManagedDevices.PrivilegedOperations.All'

$managedDevices = Get-MgBetaDeviceManagementManagedDevice

$macDevices = $managedDevices | Where-Object { ($_.OperatingSystem -eq "macOS") -and ($_.ManagedDeviceOwnerType -eq 'company') }
$windowsDevices = $managedDevices | Where-Object { ($_.OperatingSystem -eq "Windows") -and ($_.JoinType -eq 'azureADJoined') }

foreach ($mac in $macDevices)
{
    Write-Host "$($mac.DeviceName) will be renamed to SPX-$($mac.SerialNumber)"
    $deviceSplat = @{
        deviceName = $namePrefix + $mac.SerialNumber
    }

    Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/beta/deviceManagement/managedDevices('$($mac.id)')/setDeviceName" -Method POST -Body $deviceSplat
}

foreach ($windows in $windowsDevices)
{

    if ($windows.Model -eq "Virtual Machine")
    {
        $tempDeviceName = $namePrefix + $windows.SerialNumber.Replace("-", "")
    }
    else
    {
        $tempDeviceName = $namePrefix + $windows.SerialNumber
    }
    
    #Ensure the device name is max 15 characters
    if ($tempDeviceName.Length -gt 15)
    {
        $newDeviceName = $tempDeviceName.Substring(0, 15)
    }
    ELSE
    {
        $newDeviceName = $tempDeviceName
    }
    
    IF ($windows.DeviceName -eq $newDeviceName)
    {
        Write-Host "$($windows.DeviceName) is already named correctly"
        continue
    }
    else
    {
        Write-Host "$($windows.DeviceName) will be renamed to $($newDeviceName)"

        $deviceSplat = @{
            deviceName = $newDeviceName
        }

        Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/beta/deviceManagement/managedDevices('$($windows.id)')/setDeviceName" -Method POST -Body $deviceSplat
    }
}