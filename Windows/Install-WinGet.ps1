$OutputPath = "$env:TEMP\winget\"
function Test-WingetInstall
{
    $TestWinget = Get-AppxProvisionedPackage -Online | Where-Object DisplayName -eq "Microsoft.DesktopAppInstaller"
    $script:WingetVer = $TestWinget.Version

    If ($TestWinget)
    {
        #Remove WinGet MSIXBundle
        If (Test-Path "./$latestWingetMsixBundle")
        {
            Remove-Item -Path "./$latestWingetMsixBundle" -Force -ErrorAction SilentlyContinue
        }
        return $true
    }
    Else
    {
        return $false
    }  
}

If (-not(Test-WingetInstall))
{
   
    #Install WinGet MSIXBundle
    Try
    {
        $progressPreference = 'silentlyContinue'
        $WebClient = New-Object System.Net.WebClient
        
        Write-Output "Installing VC Libraries"
        $WebClient.DownloadFile("https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx","$($OutputPath)Microsoft.VCLibs.x64.14.00.Desktop.appx")
        Add-AppxProvisionedPackage -PackagePath "$($OutputPath)Microsoft.VCLibs.x64.14.00.Desktop.appx" -Online -SkipLicense

        Write-Output "Installing UI XAML 2.7.3"
        $WebClient.DownloadFile("https://www.nuget.org/api/v2/package/Microsoft.UI.Xaml/2.7.3","$($OutputPath)microsoft.ui.xaml.2.7.3.zip")
        Expand-Archive "$($OutputPath)microsoft.ui.xaml.2.7.3.zip" -DestinationPath "$($OutputPath)microsoft.ui.xaml.2.7.3" -Force
        Add-AppxProvisionedPackage -PackagePath "$($OutputPath)microsoft.ui.xaml.2.7.3\tools\AppX\x64\Release\Microsoft.UI.Xaml.2.7.appx" -Online -SkipLicense

        #If you are running in Windows Sandbox, you need to install the following packages
        IF (Get-Service 'cexecsvc')
        {
            $WebClient.DownloadFile('https://filedn.com/lOX1R8Sv7vhpEG9Q77kMbn0/Files/StoreApps/Microsoft.NET.Native.Framework.1.6_1.6.24903.0_x64__8wekyb3d8bbwe.Appx',"$($OutputPath)Microsoft.NET.Native.Framework.1.6_1.6.24903.0_x64__8wekyb3d8bbwe.Appx")
            Add-AppxPackage "$($OutputPath)Microsoft.NET.Native.Framework.1.6_1.6.24903.0_x64__8wekyb3d8bbwe.Appx"

            $WebClient.DownloadFile('https://filedn.com/lOX1R8Sv7vhpEG9Q77kMbn0/Files/StoreApps/Microsoft.NET.Native.Runtime.1.6_1.6.24903.0_x64__8wekyb3d8bbwe.Appx',"$($OutputPath)Microsoft.NET.Native.Runtime.1.6_1.6.24903.0_x64__8wekyb3d8bbwe.Appx")
            Add-AppxPackage "$($OutputPath)Microsoft.NET.Native.Runtime.1.6_1.6.24903.0_x64__8wekyb3d8bbwe.Appx"
        
            $WebClient.DownloadFile('https://filedn.com/lOX1R8Sv7vhpEG9Q77kMbn0/Files/StoreApps/Microsoft.WindowsStore_11809.1001.713.0_neutral_~_8wekyb3d8bbwe.AppxBundle',"$($OutputPath)Microsoft.WindowsStore_11809.1001.713.0_neutral_~_8wekyb3d8bbwe.AppxBundle")
            Add-AppxPackage "$($OutputPath)Microsoft.WindowsStore_11809.1001.713.0_neutral_~_8wekyb3d8bbwe.AppxBundle"
                        
        }

        Write-Output "Installing Desktop App Installer (WinGet)"
        $latestWingetMsixBundleUri = $(Invoke-RestMethod https://api.github.com/repos/microsoft/winget-cli/releases/latest).assets.browser_download_url | Where-Object { $_.EndsWith(".msixbundle") }
        $script:latestWingetMsixBundle = $latestWingetMsixBundleUri.Split("/")[-1]
        $WebClient.DownloadFile($latestWingetMsixBundleUri, "$($OutputPath)$latestWingetMsixBundle")
        Add-AppxProvisionedPackage -PackagePath (Join-Path $OutputPath $latestWingetMsixBundle) -Online -SkipLicense

        If (Test-WingetInstall)
        {
            Write-Output "Installed WinGet"
            Write-Output "Version: $WingetVer"
        }
        else
        {
            Write-Output "Failed to install WinGet"
        }
    }
    Catch
    {
        Write-Output "FAILURE: Failed to install MSIXBundle for Winget Installer!"
        Write-Error $_
    } 
}
else
{
    Write-Output "Winget already installed [$WingetVer] skipping"
}

$ResolveWingetPath = Resolve-Path "$env:ProgramFiles\WindowsApps\Microsoft.DesktopAppInstaller_*_*__8wekyb3d8bbwe" | Sort-Object { [version]($_.Path -replace '^[^\d]+_((\d+\.)*\d+)_.*', '$1') }
if ($ResolveWingetPath)
{
    #If multiple versions, pick last one
    $WingetPath = $ResolveWingetPath[-1].Path
}
if (Test-Path "$WingetPath\winget.exe")
{
    $Script:Winget = "$WingetPath\winget.exe"
    #Get Settings path for system or current user
    if ([System.Security.Principal.WindowsIdentity]::GetCurrent().IsSystem)
    {
        $SettingsPath = "$Env:windir\System32\config\systemprofile\AppData\Local\Microsoft\WinGet\Settings\settings.json"
    }
    else
    {
        $SettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState\settings.json"
    }

    #Check if setting file exist, if not create it
    if (Test-Path $SettingsPath)
    {
        $ConfigFile = Get-Content -Path $SettingsPath | Where-Object { $_ -notmatch '//' } | ConvertFrom-Json
    }

    if (!$ConfigFile)
    {
        $ConfigFile = @{}
    }

    if ($ConfigFile.installBehavior.preferences)
    {
        Add-Member -InputObject $ConfigFile.installBehavior.preferences -MemberType NoteProperty -Name 'scope' -Value 'Machine' -Force
    }
    else
    {
        $Scope = New-Object PSObject -Property $(@{scope = 'Machine' })
        $Preference = New-Object PSObject -Property $(@{preferences = $Scope })
        Add-Member -InputObject $ConfigFile -MemberType NoteProperty -Name 'installBehavior' -Value $Preference -Force
    }
    $ConfigFile | ConvertTo-Json | Out-File $SettingsPath -Encoding utf8 -Force
}
else
{
    Write-Output "Winget not installed or detected !"
}
