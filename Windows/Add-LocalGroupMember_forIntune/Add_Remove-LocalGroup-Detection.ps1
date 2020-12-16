$LocalGroup = "Hyper-V Administrators"
$Users = Get-CimInstance -ClassName Win32_LoggedOnUser -ErrorAction SilentlyContinue
ForEach ($User in ($Users | Where-Object {$_.Antecedent.Domain -notlike $Env:COMPUTERNAME}).Antecedent.Name) {
    IF (Get-LocalGroupMember -Group $LocalGroup | Where-Object {$_.Name -Like "*$User"}) {
        $true
    }
}