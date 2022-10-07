[CmdletBinding()]
param (
    [Parameter(DontShow = $true)]
    [Array]
    $ModuleNames = @("Microsoft.Graph"),
    [String]
    $LogOutputLocation = "C:\Temp"
)

#TeamsAdmin and Groups admin Required

FOREACH ($Module in $ModuleNames) {
    IF (!(Get-Module -ListAvailable -Name $Module)) {
        try {
            Write-Output "Attempting to install $Module Module for the Current Device"
            Install-Module -Name $Module -Force -AllowClobber
        }
        catch {
            Write-Output "Attempting to install $Module Module for the Current User"
            Install-Module -Name $Module -Force -AllowClobber -Scope CurrentUser
        }
    }  
}

IF (-NOT(Test-Path -Path $LogOutputLocation)){
    New-Item -ItemType Directory -Path $LogOutputLocation | Out-Null
}

Import-Module Microsoft.Graph.DeviceManagement

Select-MgProfile -Name Beta
Connect-MgGraph -Scopes "DeviceManagementServiceConfig.ReadWrite.All"
$GraphDevices = Get-MgDeviceManagementWindowAutopilotDeviceIdentity -All

$ExportData = @()
FOREACH ($Device in $GraphDevices) {
    $dInfo = New-Object PSObject
    $dInfo | Add-Member -MemberType NoteProperty -Name "DeviceSerial" -Value $Device.SerialNumber
    switch ($Device) {
        {-NOT($null -match $PSItem.DisplayName)} {
            $dInfo | Add-Member -MemberType NoteProperty -Name "DisplayNameSet" -Value $true
            $dInfo | Add-Member -MemberType NoteProperty -Name "DisplayNameValue" -Value $PSItem.DisplayName
            Write-Output "$($PSItem.SerialNumber) has the display name of $($PSItem.DisplayName)"
            try {
                $params = @{
                    DisplayName = ""
                }
                Update-MgDeviceManagementWindowAutopilotDeviceIdentityDeviceProperty -WindowsAutopilotDeviceIdentityId $PSItem.id -BodyParameter $params
                $dInfo | Add-Member -MemberType NoteProperty -Name "DisplayNameRemoved" -Value $true

            }
            catch {
                $dInfo | Add-Member -MemberType NoteProperty -Name "DisplayNameRemoved" -Value "ERROR"

            }
        }
        default {
            $dInfo | Add-Member -MemberType NoteProperty -Name "DisplayNameSet" -Value $false
            $dInfo | Add-Member -MemberType NoteProperty -Name "DisplayNameRemoved" -Value "NotRequired"
        }
    }
    $ExportData += $dInfo
}

$ExportData | Export-CSV -NoTypeInformation "$LogOutputLocation\$(Get-Date -Format yyyy-MM-dd)-WindowsAutopilotDeviceProperties.csv"