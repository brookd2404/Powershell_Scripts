[CmdletBinding()]
param (
    [String]
    $global:Capability = "QuickAssist",
    [ValidateSet('Check','Remove')]
    $Mode = "Remove"
)

function Get-InstallStatus {
    IF ((Get-WindowsCapability -Online | Where {$_.Name -like "*$Capability*"}).State -eq "Installed") {
        $true
    }
}
function Remove-Capability {
    IF ((Get-WindowsCapability -Online | Where {$_.Name -like "*$Capability*"}).State -eq "Installed") {
        Get-WindowsCapability -Online | Where {$_.Name -like "*$Capability*"} | Remove-WindowsCapability -Online
    }
}

switch ($Mode) {
    Remove { Remove-Capability -Capability $Capability }
    Check { Get-InstallStatus -Capability $Capability }
}
