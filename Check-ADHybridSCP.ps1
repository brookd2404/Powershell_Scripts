param (
    [string]
    $domainDN = "DC=<Domain>,DC=Lab"
)

##### Variables #####
$drcPath = "CN=Device Registration Configuration,CN=Services,CN=Configuration,$domainDN"
$tenanNameREX = [Regex]::new("(?<=azureADName:)([a-zA-Z0-9\.]*)")
$tenanidREX = [Regex]::new("(?<=azureADId:)([a-zA-Z0-9\-]*)")       
       

#Import the ActiveDirectory PowerShell Module
Import-Module ActiveDirectory
#Set Location to AD
Set-Location AD:
#Test if the Device Registration Configuration Exists, if it does set it to the current location
Switch(Test-Path -Path $drcPath) {
    true {
        Push-Location $drcPath
        Get-ChildItem | ForEach-Object {
        $_.DistinguishedName
            [PSCustomObject]@{
               tenantName = $tenanNameREX.Match((Get-ADObject $_.DistinguishedName -Properties Keywords).Keywords).Value
               tenantID = $tenanidREX.Match((Get-ADObject $_.DistinguishedName -Properties Keywords).Keywords).Value
               keywords = (Get-ADObject $_.DistinguishedName -Properties Keywords).Keywords

            } | Format-Table -Wrap
        }
        Pop-Location
    }
    false {
    Pop-Location
        throw "$drcpath Does not exist"
    }
}