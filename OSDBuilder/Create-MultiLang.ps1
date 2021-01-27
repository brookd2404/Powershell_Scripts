[CmdletBinding()]
param (
    #[Parameter(Mandatory = $True)]
    [String]
    $OSIso = "C:\OSDBuilder\_20h2\en-gb_windows_10_business_editions_version_20h2_x64_dvd_0837542f.iso",
    [Parameter()]
    [string]
    $OSDBuilderPath = "C:\OSDBuilder\20H2 - Multi",
    #[Parameter(Mandatory = $true)]
    [string]
    $ImageName = 'Windows 10 Enterprise',
    [array]
    $Languages = @('es-ES','pt-PT','en-GB','en-US','fr-FR'),
    [ValidateScript({Test-Path $_})]
    [String]
    $FODDirectory = "C:\OSDBuilder\_20h2\Windows10_2004_FOD_Disk1",
    [ValidateScript({Test-Path $_})]
    [String]
    $LIPDirectory = "C:\OSDBuilder\_20h2\Windows10_2004-MultiLang-LangPackAll_LIP",
    [ValidateScript({Test-Path $_})]
    [String]
    $FODdestPath = "$OSDBuilderPath\Content\IsoExtract\Windows 10 2009 FOD x64",
    [ValidateScript({Test-Path $_})]
    [String]
    $LIPDestPath = "$OSDBuilderPath\Content\IsoExtract\Windows 10 2009 Language",
    [string]
    $TaskName = "Windows 10 20H2 x64 Multi"

)

#Import/Install the Module Required
$OSDBMod = Get-Module -Name "OSDBuilder" -ListAvailable
if (!($OSDBMod)) {
    $ModuleName = "OSDBuilder"
    Write-Host -ForegroundColor Yellow "$ModuleName module not found"
    try {
        Write-Host -ForegroundColor Cyan "Attempting to Install the $ModuleName module as system..."
        Install-Module $ModuleName -Force -ErrorAction Stop
    }
    catch {
        Write-Host -ForegroundColor Cyan "Attempting to Install the $ModuleName module as logged on user..."
        Install-Module $ModuleName -Force -Scope CurrentUser -ErrorAction Stop
    } finally {
        Write-Verbose "Failed to install as system, so Installed as user"
    } 
}

Import-Module $ModuleName
#Create OSDBuilder Package
Get-OSBuilder -SetPath $($OSDBuilderPath.Trim('\')) -CreatePaths
Mount-DiskImage $OSIso
#Import the OS Wims from a mounted or instered driver
Import-OSMedia -ImageName $ImageName -SkipGrid 
#Dismount-DiskImage $OSIso
#Update the OSMedia
Update-OSMedia -Download -Execute

FOREACH ($Language in $Languages) {

    Write-Host "Copying $Language FOD Files"
    $FODsourcePath = "$($FODDirectory.Trim('\'))\"
    Get-ChildItem $FODsourcePath -Recurse -Include "*$Language*" | Foreach-Object `
    {
        $destDir = Split-Path ($_.FullName -Replace [regex]::Escape($FODsourcePath), "$($FODDestPath.Trim('\'))\")
        if (!(Test-Path $destDir))
        {
            New-Item -ItemType directory $destDir | Out-Null
        }
        Copy-Item $_ -Destination $destDir -Force
    }
    
    Write-Host "Copying $Language LIP Files"
    $LIPsourcePath = "$($LIPDirectory.Trim('\'))\"
    Get-ChildItem $LIPsourcePath -Recurse -Include "*$Language*" | Foreach-Object `
    {
        $destDir = Split-Path ($_.FullName -Replace [regex]::Escape($LIPsourcePath), "$($LIPDestPath.Trim('\'))\")
        if (!(Test-Path $destDir))
        {
            New-Item -ItemType directory $destDir | Out-Null
        }
        Copy-Item $_ -Destination $destDir -force
    }
}

New-OSBuildTask -TaskName $TaskName -ContentLanguagePackages

New-OSBuildTask -TaskName $TaskName -SourcesLanguageCopy

New-OSBuild -Execute

New-OSBuildMultiLang