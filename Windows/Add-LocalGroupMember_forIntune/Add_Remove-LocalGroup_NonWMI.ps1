[CmdletBinding()]
param (
    [Parameter(Mandatory = $True)]
    [String]
    [ValidateSet("Add","Remove")]
    $Action,
    [Parameter(Mandatory = $True)]
    [String]
    $LocalGroup
)

IF((Get-LocalGroup).Name | Where-Object {$_ -match $LocalGroup} ){
    $Users = Get-ChildItem C:\Users -Exclude "Adminstrator","Public","Default","Defaultuser0"
    switch ($Action) {
        Add { 
            ForEach ($User in ($Users).Name) {
                IF(!(Get-LocalGroupMember -Group $LocalGroup | Where-Object {$_.Name -Like "*$User"})) {
                    Write-Output "$User is in not in the $LocalGroup group - Adding"
                    Add-LocalGroupMember -Group $LocalGroup -Member $User 
                    Write-Output "$User added to the $LocalGroup group"
                } ELSE {
                    Write-Output "$User is already in the $LocalGroup group"
                }
            }
        }
        Remove {
            ForEach ($User in ($Users).Name) {
                IF(Get-LocalGroupMember -Group $LocalGroup | Where-Object {$_.Name -Like "*$User"}) {
                    Write-Output "$User is in the $LocalGroup group - Removing"
                    Remove-LocalGroupMember -Group $LocalGroup -Member $User -ErrorAction Stop
                    Write-Output "$User removed from the $LocalGroup group"
                } ELSE {
                    Write-Output "$User is not in the $LocalGroup group"
                }
            }
        }
    }
} else {
    Write-Output "$LocalGroup Does Not exist as a local group" 
}