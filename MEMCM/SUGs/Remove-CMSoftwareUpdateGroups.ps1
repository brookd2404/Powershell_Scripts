Param (
    [String]
    $SiteCode,
    [String]
    $ProviderMachineName,
    [String]
    $DisplayNameFilter = "Windows Server 2019",
    [String]
    $LogOutputLocation = "C:\Temp"
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
$lastestSUG,$SugFilter = ($sugs | Where-Object {($_.LocalizedDisplayName -like ($DisplayNameFilter + "*")) -and ($_.DateCreated.ToString('MM-yyyy') -notmatch "$(Get-Date -Format MM-yyyy)")} | Sort-Object -Descending DateCreated)

#Disable the Fast Method Not used Check for the commands below
$CMPSSuppressFastNotUsedCheck = $true

#Set a place holder for the export info
$ExportInfo = @()

#forEach SUG in the Filtered SUG List (Excluding the one you are using to merge into), Process the following
ForEach ($SUG in $sugfilter)
{
    try {
        Write-host "Processing Software Update Group" $($SUG.LocalizedDisplayName)
        Write-Output "Removing $($SUG.LocalizedDisplayName)"
        #Gather Info to export a list of the updates
        $RMSUGinfo = New-Object PSObject
        $RMSUGinfo | Add-Member -MemberType NoteProperty -Name "SUG" -Value $SUG.LocalizedDisplayName
        $ExportInfo += $RMSUGinfo

        Remove-CMSoftwareUpdateGroup -Id $SUG.CI_ID -Force -ErrorAction Stop
       } catch {
        Write-Output "Failed to remove $($Sug.LocalizedDisplayName)"
    }
}

$ExportInfo | Export-CSV -NoTypeInformation "$LogOutputLocation\$(Get-Date -Format yyyy-MM-dd)-$DisplayNameFilter.csv"