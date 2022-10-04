[Array]$Values = @('RegisteredOwner','RegisteredOrganization')
[String]$RegLocation = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\"
[String]$RequiredValue = "<Your Company>"

FOREACH ($Value in $Values) {
    IF (-not ((Get-ItemProperty -Path $RegLocation -Name $Value -ErrorAction SilentlyContinue) -match $RequiredValue)) {
        Set-ItemProperty -Path $RegLocation -Name $Value -Value $RequiredValue -Force
        Write-Output "Updating Value for $Value to $RequiredValue"
    } Else {
         Write-Output "Value $Value Is Already $RequiredValue"
    }
}