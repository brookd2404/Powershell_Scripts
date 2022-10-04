$Group = [ADSI]"LDAP://cn=AD DLL Testing,OU=TEST,OU=Replace,dc=ME,dc=LOCAL"
$IsDeviceMember = $Group.Member | ForEach-Object {
    $Searcher = [adsisearcher]"(distinguishedname=$_)"
    $searcher.FindOne().Properties
} | Where-Object {$_.cn -like "*$($env:COMPUTERNAME)*"}

IF ($IsDeviceMember){
    $true
} else {}