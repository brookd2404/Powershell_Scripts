
[CmdletBinding()]
param (
    [Parameter()]
    [Array]
    $SubscriptionIDs = @('id1', 'id2'),
    [Parameter()]
    [String]
    $storage_Filter = 'profilesa',
    [String]
    $ExportPath = "$env:TEMP\AzureStorageFileShareExport",
    [Parameter(DontShow = $true)]
    $AzModuleName = "AzureRM" #Set the name of the Azure Module
)

#If the Export Path does not exist, Create it. 
if (-Not(Test-Path -Path $ExportPath)) {
    try {
        New-Item -ItemType Directory -Path $ExportPath | Out-Null
    }
    catch {
        Throw "Failed to create $exportPath Directory"    
    }
}

# A function for creating the IP Rules on the File Shares
function Configure-IPRules {
    param (
        [ValidateSet('Add','Remove','Check')]
        [Parameter(Mandatory = $true)]
        $Action,
        [Parameter(Mandatory = $true)]
        $StorageAccount,
        $IP
    )

    $currentIPRules = (Get-AzStorageAccountNetworkRuleSet -ResourceGroupName $StorageAccount.ResourceGroupName -Name $StorageAccount.StorageAccountName).IpRules | Where-Object {$_.Action -match "Allow"} | Select-Object -ExpandProperty IPAddressOrRange

    switch ($Action) {
        Add { 
            Add-AzStorageAccountNetworkRule -ResourceGroupName $StorageAccount.ResourceGroupName -Name $StorageAccount.StorageAccountName -IPAddressOrRange $IP
        }
        Remove {
            Remove-AzStorageAccountNetworkRule -ResourceGroupName $StorageAccount.ResourceGroupName -Name $StorageAccount.StorageAccountName -IPAddressOrRange $IP
        }
        Check {
            $currentIPRules = (Get-AzStorageAccountNetworkRuleSet -ResourceGroupName $StorageAccount.ResourceGroupName -Name $StorageAccount.StorageAccountName).IpRules | Where-Object {$_.Action -match "Allow"} | Select-Object -ExpandProperty IPAddressOrRange
            $currentIPRules
        }
    }
}


#If the Azure RM Module is not installed, Install it
$AzModule = Get-Module -Name $AzModuleName -ListAvailable -ErrorAction SilentlyContinue
IF (-not($AzModule)) {
    try {
        "Attempting to install Powershell Module ($AzModuleName) in the system context"
        Install-PackageProvider -Name
        Install-Module $AzModuleName
    }
    catch {
        "Attempting to install Powershell Module ($AzModuleName) in the current user context"
        Install-Module $AzModuleName -Scope CurrentUser -Force
        "Module Installed in the Current User Context"
    }
    Finally {
        "Unable to install the $AzModuleName Powershell Module"
    }
}

#Getting the External IP of your workstation
$extIP = (Invoke-WebRequest -Uri "http://ipinfo.io/ip").Content

Connect-AzAccount

FOREACH ($Subscription in $SubscriptionIDs) {
    "Setting Subscription to $Subscription"
    Set-AzContext -Subscription $Subscription | Out-Null
    
    "Getting the Profiles Storage Account"
    $saAccount = Get-AzStorageAccount | Where-Object {$_.StorageAccountName -like "*$storage_filter*"}

    
    "Checking if IP $extIP is in the Allowed List"
    $AllowedIPs = Configure-IPRules -Action Check -StorageAccount $saAccount

    IF (-Not($AllowedIPs -contains $extIP)) {
        "Adding $extIP to the File Share"
        Configure-IPRules -Action Add -StorageAccount $saAccount -IP $extIP | Out-Null
        "Waiting 30 seconds to allow the network rules to apply"
        #Allow time for the rule to Apply
        Start-Sleep 30
    }

    $saFolder = (Get-AzStorageFile -ShareName "fslogix" -Context $saAccount.Context).Name

    $SubFolders = (Get-AzStorageFile -ShareName "fslogix" -Context $saAccount.Context -Path $saFolder | Get-AzStorageFile).Name

    foreach ($folder in $Subfolders) {
        "Getting $folder sub directories"
        $fileshareFolders = Get-AzStorageFile -ShareName "fslogix" -Context $saAccount.Context -Path "$saFolder\$folder" | Get-AzStorageFile | Select-Object Name
        $expObj = @()
        foreach ($folder in $fileshareFolders) {
            $thisObj = New-Object PSObject
            $thisObj | Add-Member -MemberType NoteProperty -Name folderName -Value $folder.Name
            $thisObj | Add-Member -MemberType NoteProperty -Name userSID -Value $folder.Name.Split('_')[1]
            $expObj += $thisObj
        }

        $expObj | Export-Csv -NoTypeInformation -Path "$ExportPath\$(Get-Date -Format yyyyMMdd)_$($Subscription)_$($saFolder).csv"
      
    }

    "Removing IP $extIP from the File Share"
    Configure-IPRules -Action Remove -StorageAccount $saAccount -IP $extIP

}