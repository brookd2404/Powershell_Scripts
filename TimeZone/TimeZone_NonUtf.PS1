<#
 # David Brook - PowerON Platforms - 20/04/2021
 #>

 [CmdletBinding()]
 param (
     [Parameter()]
     [String]
     $BingAPIKey = "",
     [String]
     $LogPath = "$env:SystemDrive\Windows\Logs"
 )
 
 $LogFile = "$Logpath\$(Get-Date -format yyyy.MM.dd)_TimezoneUpdate.Log"
 
 Start-Transcript -Path $LogFile
 
 $MapsURIPrefix = "https://dev.virtualearth.net/REST/v1/TimeZone/"
 $MapsURIQuery = "?&key=$BingAPIKey"
 
 $LocationAccessKeys = @("HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location","HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location")
 
 $CurrentLocationRegValues = @{}
 foreach ($key in $LocationAccessKeys) {
     IF(-Not(Test-Path -Path $key)){
         Write-Host "$Key does not exist, Will Create"
         try {
             New-Item -ItemType Directory -Path $key -Force -ErrorAction Stop
             New-ItemProperty -Path $key -Name "value" -Value "Allow" -Force
             $CurrentLocationRegValues.Add($key,"Delete")
         }
         catch {
             Throw "Failed to create $Key"
         }
     } ELSE {
         try {
             $CurrentValue = (Get-ItemProperty -Path $key -Name value).value
             Write-Host "Backing up the current value of $($CurrentValue) for $key"
             $CurrentLocationRegValues.Add($key,$CurrentValue)
             IF(-Not($CurrentValue -match "Allow")) {
                 Write-Host "Updating the value to Allow from $CurrentValue"
                 Set-ItemProperty -Path $Key -Name Value -Value "Allow" -Force
             }
         }
         catch {
             Throw "Failed to update the value for $Key"
         }
     }
 }
 
 try {
     Write-Host "Obtaining Current Latitude and Longitude"
     Add-Type -AssemblyName System.Device #Required to access System.Device.Location namespace
     $GeoWatcher = New-Object System.Device.Location.GeoCoordinateWatcher #Create the required object
     $GeoWatcher.Start() #Begin resolving current locaton
     while (($GeoWatcher.Status -ne 'Ready') -and ($GeoWatcher.Permission -ne 'Denied')) {
         Start-Sleep -Milliseconds 100 #Wait for discovery.
     }
     if ($GeoWatcher.Permission -eq 'Denied'){
         Write-Error 'Access Denied for Location Information'
     } else {
         $GeoWatcher.Position.Location | Select Latitude,Longitude #Select the relevent results.
     }
 } catch {
     throw "Unable to obtain Latitude and Longitude"
 }
 
 try {
     Write-Host "Attempting to get the Timezone from Bing"
     $BingRestParms = @{
         Method = "GET"
         URI = $MapsURIPrefix + "$($GeoWatcher.Position.Location.Latitude),$($GeoWatcher.Position.Location.Longitude)" + $MapsURIQuery
         ContentType = "application/JSON"
     }
     $TimezoneForLocation = (Invoke-RestMethod @BingRestParms -ErrorAction Stop ).resourceSets.resources.timeZone.windowsTimeZoneId
 
     Write-Host "$TimezoneForLocation selected from the Bing API"
 
     $CurrentTimezone = Get-TimeZone | Select-Object -ExpandProperty StandardName
 
     IF (-not ($CurrentTimezone -match $TimezoneForLocation)) {
         Write-Host "Updating Timezone from $CurrentTimezone to $TimeZoneForLocation"
         Set-TimeZone -Name $TimezoneForLocation -ErrorAction Stop
     } else {
         write-host "Your current Timezone is $CurrentTimezone, which is matches the one found from Bing"
     }
 } catch {
     $Error[0]
     Throw "Unable to update your Timezone"
 }
 
 try {
     Write-Host "Reverting Location Services back to the Original Settings"
     foreach ($key in $CurrentLocationRegValues.Keys) {
         $CurSetting = (Get-ItemProperty -Path $Key -Name "Value").Value
         IF (-Not($CurSetting -match $CurrentLocationRegValues[$key])) {
             IF ($CurrentLocationRegValues[$key] -match "Delete") {
                 Write-Host "Removing Value from $Key, this did not exist at the start of execution"
                 Remove-ItemProperty -Path $Key -Name "Value" -Force
             } ELSE {
                 Write-Host "Setting the the property Value in $Key to $($CurrentLocationRegValues[$key])"
                 Set-ItemProperty -Path $key -Name "Value" -Value $CurrentLocationRegValues[$Key] -Force
             }
         }
     }
 }
 catch {
     Throw "Failed to remediate keys to original values"
 }
 
 Stop-Transcript
