Param (
    [String]
    $SiteCode,
    [String]
    $ProviderMachineName,
    [String]
    $DisplayNameFilter = "Windows Server 2019",
    [String]
    $LogOutputLocation = "C:\Temp",
    [ValidateSet('Q1','Q2','Q3','Q4')]
    [String]
    $Quarter = "Q4"
)

# Import the ConfigurationManager.psd1 module 
if(-not(Get-Module ConfigurationManager)) {
    Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1"
}

# Connect to the site's drive if it is not already present
if(-not(Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue)) {
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName 
}

# Set the current location to be the site code.
Set-Location "$($SiteCode):\" 

#Get the software Update groups
Write-Warning "Getting Software Update Groups, This may take a while..."
$SUGS = Get-CMSoftwareUpdateGroup 

$RollupName = "$DisplayNameFilter - $Quarter Rollup"

IF($sugs | Where-Object {$_.LocalizedDisplayName -match $RollupName}) {
    $rollupSUG = $sugs | Where-Object {$_.LocalizedDisplayName -match $RollupName}
} ELSE {
    $rollupSUG = New-CMSoftwareUpdateGroup -Name "$DisplayNameFilter - $Quarter Rollup" -Description "$Quarter Rollup of $DisplayNameFilter SUGS`n$(Get-date)"
}

#Filter the Sugs where displayname like a value and Month created was not the current month
$fSUGS = ($sugs | Where-Object {($_.LocalizedDisplayName -like ($DisplayNameFilter + "*")) -and ($_.DateCreated.ToString('MM-yyyy') -notmatch "$(Get-Date -Format MM-yyyy)")} | Sort-Object -Descending DateCreated)
#Disable the Fast Method Not used Check for the commands below
$CMPSSuppressFastNotUsedCheck = $true

FUNCTION Merge-SUGS {

    #Set a place holder for the export info
    $ExportInfo = @()

    #forEach SUG in the Filtered SUG List (Excluding the one you are using to merge into), Process the following
    ForEach ($SUG in $fSUGS)
    {
        try {
            Write-host "Processing Software Update Group" $($SUG.LocalizedDisplayName)
            forEach ($Update in (Get-CMSoftwareUpdate -UpdateGroupName $($SUG.LocalizedDisplayName)))
            {
                #Gather Info to export a list of the updates
                $UpdateInfo = New-Object PSObject
                $UpdateInfo | Add-Member -MemberType NoteProperty -Name "SUG" -Value $SUG.LocalizedDisplayName
                $UpdateInfo | Add-Member -MemberType NoteProperty -Name "Updatename" -Value $Update.LocalizedDisplayName
                $UpdateInfo | Add-Member -MemberType NoteProperty -Name "UpdateDateCreated" -Value $Update.DateCreated
                $UpdateInfo | Add-Member -MemberType NoteProperty -Name "UpdateCI_ID" -Value $Update.CI_ID
                $UpdateInfo | Add-Member -MemberType NoteProperty -Name "UpdateIsExpired" -Value $Update.IsExpired
                $UpdateInfo | Add-Member -MemberType NoteProperty -Name "UpdateSuperseded" -Value $Update.IsSuperseded
                $ExportInfo += $UpdateInfo

                If($Update.IsSuperseded -eq $false)
                {
                    try {
                        write-output "Adding Item $($Update.CI_ID)-($($Update.LocalizedDisplayname)) to $($rollupSUG.CI_ID)-($($rollupSUG.LocalizedDisplayname))"
                        Add-CMSoftwareUpdateToGroup -SoftwareUpdateId $Update.CI_ID -SoftwareUpdateGroupId $rollupSUG.CI_ID -ErrorAction stop
                    } catch {
                        Throw "Failed to Add Item $($Update.CI_ID)-($($Update.LocalizedDisplayname)) to $($rollupSUG.CI_ID)-($($rollupSUG.LocalizedDisplayname))"
                    }
            
                }

           }
        } catch {
            Write-Output "Failed to perfom actions on $($Sug.LocalizedDisplayName)"
        }
    }

    $latestSUGDeployments = Get-CMSoftwareUpdateGroup -Id ($fSUGS[0]).CI_ID | Get-CMUpdateGroupDeployment

    FOREACH ($Deployment in $latestSUGDeployments) {

    $DeploymentSplat = @{
        DeploymentName = $Deployment.AssignmentName
        SoftwareUpdateGroupid = $rollupSUG.CI_ID
        CollectionID = $Deployment.TargetCollectionID
        DeploymentType = "Required"
        VerbosityLevel = "OnlySuccessAndErrorMessages"
        AvailableDateTime = $Deployment.StartTime
        DeadlineDateTime = $Deployment.EnforcementDeadline
        UserNotification = "DisplaySoftwareCenterOnly"
        SoftwareInstallation = $true
        PersistOnWriteFilterDevice = $Deployment.PersistOnWriteFilterDevices
        RequirePostRebootFullScan = $Deployment.RequirePostRebootFullScan
        DeployWithNoPackage = $true
        UseBranchCache = $Deployment.UseBranchCache
        UnprotectedType = "UnprotectedDistributionPoint"
        DownloadFromMicrosoftUpdate = $true
        ProtectedType = "RemoteDistributionPoint"
        
    }

       New-CMSoftwareUpdateDeployment @DeploymentSplat

    }

    $ExportInfo | Export-CSV -NoTypeInformation "$LogOutputLocation\$(Get-Date -Format yyyy-MM-dd)-$DisplayNameFilter.csv"
}

Merge-SUGS