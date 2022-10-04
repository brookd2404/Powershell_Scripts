param (
    [ValidateNotNullOrEmpty()]
    [String]
    $GroupName,
    [String]
    $Username,
    [string]
    $Password,
    [string]
    $compname = $env:COMPUTERNAME
)

$ScriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

#PSCred Help: "https://purple.telstra.com/blog/using-saved-credentials-securely-in-powershell-scripts"
$securePassword = $Password | ConvertTo-SecureString 
$Cred = New-Object System.Management.Automation.PSCredential $Username, $securePassword 

$ADModule = "$ScriptDir\Microsoft.ActiveDirectory.Management.dll"
Import-Module $ADModule


$Comp = $compname + "`$"

Add-ADGroupMember -Identity $GroupName -Members $Comp -Credential $cred
