Param
(
$SiteCode,
$ProviderMachineName,
$DisplayNameFilter,
$LogOutputLocation
)

# Import the ConfigurationManager.psd1 module 
if((Get-Module ConfigurationManager) -eq $null) {
    Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1"
}

# Connect to the site's drive if it is not already present
if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName 
}

# Set the current location to be the site code.
Set-Location "$($SiteCode):\" 

#Get the software Update groups
Write-Warning "Getting Software Update Groups, This may take a while..."
$sugs = Get-CMSoftwareUpdateGroup 

#Filter the Sugs where displayname like a value and Month created was not the current month
$SugFilter = ($sugs | Where-Object {($_.LocalizedDisplayName -like ($DisplayNameFilter + "*")) -and ($_.DateCreated.ToString('MM-yyyy') -notmatch "$(Get-Date -Format MM-yyyy)")} | Sort-Object -Descending DateCreated)
#Set the latest SUG (excluding the current month) to merge the other SUGs Into
$SugDec = $sugfilter[0]
#Disable the Fast Method Not used Check for the commands below
$CMPSSuppressFastNotUsedCheck = $true

#Set a place holder for the export info
$ExportInfo = @()

#forEach SUG in the Filtered SUG List (Excluding the one you are using to merge into), Process the following
ForEach ($SUG in ($sugfilter | Where-Object {$_.LocalizedDisplayName -notmatch $SugDec.LocalizedDisplayName}))
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
                    write-output "Adding Item $($Update.CI_ID)-($($Update.LocalizedDisplayname)) to $($SugDec.CI_ID)-($($SugDec.LocalizedDisplayname))"
                    Add-CMSoftwareUpdateToGroup -SoftwareUpdateId $Update.CI_ID -SoftwareUpdateGroupId $sugDec.CI_ID -ErrorAction stop
                } catch {
                    Throw "Failed to Add Item $($Update.CI_ID)-($($Update.LocalizedDisplayname)) to $($SugDec.CI_ID)-($($SugDec.LocalizedDisplayname))"
                }
            
            }

       }
    } catch {
        Write-Output "Failed to perfom actions on $($Sug.LocalizedDisplayName)"
    }
}

$ExportInfo | Export-CSV -NoTypeInformation "$LogOutputLocation\$(Get-Date -Format yyyy-MM-dd)-$DisplayNameFilter.csv"