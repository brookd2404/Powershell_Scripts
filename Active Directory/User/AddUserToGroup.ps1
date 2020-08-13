[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    $USN,
    [Parameter(Mandatory = $true)]
    [String]
    $GroupName
)
Import-Module ActiveDirectory

try {
    Write-Host "Adding $($USN) to $($GroupName)"
    Add-ADGroupMember -Identity $GroupName -Members $USN -ErrorAction Stop
    Write-Host -ForegroundColor Green "Sucessfully Added $($USN) to $($GroupName)"
}
catch {
    Write-Host -ForegroundColor Red "Failed to Add $($USN) to $($GroupName)"
}