$LocalGroup = "Hyper-V Administrators"
$Users = Get-ChildItem C:\Users -Exclude "Adminstrator","Public","Default","Defaultuser0"
ForEach ($User in ($Users).Name) {
    IF (Get-LocalGroupMember -Group $LocalGroup | Where-Object {$_.Name -Like "*$User"}) {
        $true
    }
}