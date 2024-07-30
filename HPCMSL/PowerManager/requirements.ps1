[CmdletBinding()]
param (
    [Parameter()]
    [array]
    #Get chassis types from https://learn.microsoft.com/en-us/windows/win32/cimwin32prov/win32-systemenclosure
    $chassisTypes = ("8", "9", "10", "11", "12", "14", "18", "21", "30", "31"),
    [Parameter(DontShow = $true)]
    [bool]
    $meetsRequirements = $false
)

#Get the system information
$win32Baseboard = Get-WmiObject -Class Win32_BaseBoard
#Check if the system is an HP
IF ($win32Baseboard.Manufacturer -in ('HP', 'Hewlett-Packard', 'Hewlett'))
{
    #Get the system information
    $win32SystemEnclosure = Get-WmiObject -Class Win32_SystemEnclosure
    #Check if the system is a laptop
    IF ($win32SystemEnclosure.ChassisTypes -in $chassisTypes)
    {
        $meetsRequirements = $true
    }
}

return $meetsRequirements