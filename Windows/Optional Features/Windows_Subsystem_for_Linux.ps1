<#
.SYNOPSIS
  This script is used to Enable and Disable the Windows Subsystem for Linux Depending on the command line switch it is called with
.DESCRIPTION
  This script is used to Enable and Disable the Windows Subsystem for Linux Depending on the command line switch it is called with
.PARAMETER Enable
    Enables the Windows Subsystem for Linux
.PARAMETER Disable
    Disables the Windows Subsystem for Linux
.INPUTS
  None
.OUTPUTS
  None
.NOTES
  Version:        1.0
  Author:         David Brook
  Creation Date:  13/08/2020
  Purpose/Change: Initial script creation
  
.EXAMPLE
  Windows_SubSystem_for_Linux.ps1 -Enable
#>

param (
    [switch]
    $Enable,
    [switch]
    $Disable,
    [switch]
)

IF ($Enable) {
    Enable-WindowsOptionalFeature -Online -FeatureName "Microsoft-Windows-Subsystem-Linux" -All -NoRestart
}

IF ($Disable) {
    Disable-WindowsOptionalFeature -Online -FeatureName "Microsoft-Windows-Subsystem-Linux" -NoRestart
}