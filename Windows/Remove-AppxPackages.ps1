#BlackList of apps to remove 
$AppsList = "Microsoft.SkypeApp", # Get Skype
"microsoft.windowscommunicationsapps", # Mail & Calendar
"Microsoft.People", # People
"Microsoft.XboxApp", # Xbox
"Microsoft.Xbox.TCUI", # Xbox TCUI
"Microsoft.XboxGamingOverlay", # Xbox Companion
"Microsoft.XboxGameOverlay", # Microsoft Xbox Game Overlay
"Microsoft.XboxSpeechToTextOverlay", # Xbox Speech to Text
"Microsoft.XboxIdentityProvider", # Microsoft Xbox Identity Provider
"Microsoft.XboxGameCallableUI", #Xbox App W11 
"Microsoft.WindowsFeedbackHub", # Feedback App
"Microsoft.StorePurchaseApp", # Microsoft Store Purchase
"Microsoft.GetHelp", # Get Help
"Microsoft.Wallet",
"Microsoft.YourPhone",
"Microsoft.OneConnect",
"Clipchamp.Clipchamp", # Windows 11, ClipChamp Video Editor
"Microsoft.BingNews", # Bing News
"Microsoft.Getstarted", # Getting Started
"Microsoft.MicrosoftSolitaireCollection",
"MicrosoftCorporationII.MicrosoftFamily" #Family App

# Work through list

ForEach ($App in $AppsList) {
	$AppPackageFullName = Get-AppxPackage -Name $App | Select-Object -ExpandProperty PackageFullName
    $AppProvisioningPackageName = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like $App } | Select-Object -ExpandProperty PackageName

    # Attempt to remove AppxPackage
    try {
        Write-Host "Removing application package: $($AppPackageFullName)"
		Remove-AppxPackage -Package $AppPackageFullName -AllUsers -ErrorAction Stop
        }
        catch [System.Exception] {
            # Write-Warning -Message $_.Exception.Message
			Write-Host "Unable to find package: $App"
        }
		# Attempt to remove AppxProvisioningPackage
    if ($AppProvisioningPackageName -ne $null) {
        try {
            Write-Host "Removing application provisioning package: $($AppProvisioningPackageName)"
			Remove-AppxProvisionedPackage -PackageName $AppProvisioningPackageName -Online -ErrorAction Stop
            }
            catch [System.Exception] {
                # Write-Warning -Message $_.Exception.Message
				Write-Host "Unable to find provisioned package: $App" 
            }
		}
	}
