param (
    [String]
    [Parameter(Mandatory = $true)]
    $OU,
    [String]
    [Parameter(Mandatory = $true)]
    $newUPNSuffix,
    [String]
    [Parameter(Mandatory = $true)]
    $currentUPNSuffix
)

Import-Module ActiveDirectory

$userList = Get-ADUser -Filter "userPrincipalName -like '*$currentUPNSuffix'" -SearchBase $OU

foreach ($user in $userList){
    Set-ADUser -Identity $user.SamAccountName -UserPrincipalName ($user.UserPrincipalName.Replace($currentUPNSuffix,$newUPNSuffix))
}