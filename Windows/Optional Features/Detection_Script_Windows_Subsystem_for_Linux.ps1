<#
.SYNOPSIS
  This script is used to Detect the Windows Subsystem for Linux from MEMCM or Intune
.DESCRIPTION
  This script is used to Detect the Windows Subsystem for Linux from MEMCM or Intune
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
#>

IF ( Get-WmiObject -Class Win32_OptionalFeature | Where-Object {($_.Name -Match "Microsoft-Windows-Subsystem-Linux") -and ($_.InstallState -eq 1)} ){
  $True
}