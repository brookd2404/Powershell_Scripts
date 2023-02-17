[CmdletBinding()]
param (
    [Parameter(DontShow = $true)]
    [Array]
    $ModuleNames = @("Microsoft.Graph", "AzureAD"),
    [Parameter(Mandatory = $true)]
    [string]
    $aadGroupID,
    [Parameter(Mandatory = $true)]
    [string]
    $audienceId
)

FOREACH ($Module in $ModuleNames) {
    IF (!(Get-Module -ListAvailable -Name $Module)) {
        try {
            Write-Output "Attempting to install $Module Module for the Current Device"
            Install-Module -Name $Module -Force -AllowClobber
        }
        catch {
            Write-Output "Attempting to install $Module Module for the Current User"
            Install-Module -Name $Module -Force -AllowClobber -Scope CurrentUser
        }
    }  
}

#Connect to Required Modules
Connect-MgGraph -Scopes "Group.Read.All", "WindowsUpdates.ReadWrite.All" -ContextScope CurrentUser 
Select-MgProfile beta
Connect-AzureAD

#Get Group Members IDs
$GroupMemberIDs = (Get-MgGroupMember -GroupId $aadGroupID -All).id
"$aadgroupID $($GroupMemberIDs.Count) members"

#Break the id's into chunks of 200
$chunks = [System.Collections.ArrayList]::new()
for ($i = 0; $i -lt $GroupMemberIDs.Count; $i += 200) {
    if (($GroupMemberIDs.Count - $i) -gt 199  ) {
        $chunks.add($GroupMemberIDs[$i..($i + 199)])
    }
    else {
        $chunks.add($GroupMemberIDs[$i..($GroupMemberIDs.Count - 1)])
    }
}

#Get the Update Audience
$updateAudienceMembers = Invoke-GetRequest `
    -Uri "https://graph.microsoft.com/beta/admin/windows/updates/deploymentAudiences('$audienceId')/members" -All

#For each chunk of devices, enrol and add them to an audience 
foreach ($chunk in $chunks) {
    $AzureDeviceIDs = @()
    $GroupMemberIDs | foreach-object {
        $DeviceID = (Get-AzureADDevice -ObjectID $_).DeviceID
        $AzureDeviceIDs += $DeviceID
    }

    $enrollParamBody = @{
        updateCategory = "driver"
        assets = @(
        )
    }

    $audienceParamBody = @{
        addMembers = @(
        )
    }
    foreach ($id in $azureDeviceIDs) {
            
        IF (-Not($updateAudienceMembers.id -contains $id)) {
            $memberObject = @{
                "@odata.type" = "#microsoft.graph.windowsUpdates.azureADDevice"
                id            = $id
            }
            $audienceParamBody.addMembers += $memberObject
        } 

        IF(-Not($updateAudienceMembers.id -contains $id) -or ($updateAudienceMembers | Where-Object {$_.id -match $id}).enrollments.updateCategory -notcontains "driver"){
            $memberObject = @{
                "@odata.type" = "#microsoft.graph.windowsUpdates.azureADDevice"
                id            = $id
            }
            $enrollParamBody.assets += $memberObject
        } 
    }

    #Explicitly Enrol Devices
    Invoke-MgGraphRequest `
        -Method POST `
        -Uri "https://graph.microsoft.com/beta/admin/windows/updates/updatableAssets/enrollAssets" `
        -Body $enrollParamBody 

    #Post Audience Members
    Invoke-MgGraphRequest `
        -Method POST `
        -Uri "https://graph.microsoft.com/beta/admin/windows/updates/deploymentAudiences('$audienceId')/updateAudience" `
        -Body ( $audienceParamBody | ConvertTo-Json -Depth 5)

}