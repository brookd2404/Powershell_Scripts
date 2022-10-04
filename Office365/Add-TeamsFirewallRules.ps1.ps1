#Get User profiles excluding defaultuser, Public and Administrator
$Users = Get-ChildItem "$env:SystemDrive\Users" -Exclude 'Defaultuser0','Public','Administrator' | Select-Object -ExpandProperty Name

#For Each user who has an account, Check if they have a firewall rule. If not Create One
ForEach ($user in $Users) {
    if (Get-NetFirewallRule -Direction Inbound | Where-Object { $_.DisplayName -like "Teams.exe for user $($User)*"}) {
        Write-Host "No Action Needed for user $($User)"
    } ELSE {
        $Splat =@{
            DisplayName = "Teams.exe for user $($User)"
            Program = "C:\Users\$($User)\AppData\Local\Microsoft\Teams\Current\Teams.exe"
            Action = "Allow"
            Profile = "Public","Private"
            Direction = "Inbound"

        }
        New-NetFirewallRule @Splat
    }
}