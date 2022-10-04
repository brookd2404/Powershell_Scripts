Param (
    $LogPath = "$env:PROGRAMDATA\Temp\WU-Cleanup.log"
)

function Start-Log {
    [CmdletBinding()]
    param (
        [ValidateScript( { Split-Path $_ -Parent | Test-Path })]
        [string]$FilePath
    )

    If ([string]::IsNullOrWhiteSpace($MyInvocation.ScriptName)) {
        Write-Output "Enforced Component Name"
        $Global:ComponentName = "WaaS-Cleanup"
    }
    Else {
        Write-Output "MyInvocation.ScriptName - $($MyInvocation.ScriptName | Split-Path -Leaf)"
        $Global:ComponentName = "$($MyInvocation.ScriptName | Split-Path -Leaf)"
    }

    try {
        if (!(Test-Path $FilePath)) {
            New-Item $FilePath -Type File | Out-Null
        }

        ## Set the global variable to be used as the FilePath for all subsequent Write-Log
        ## calls in this session
        $global:ScriptLogFilePath = $FilePath
    }
    catch {
        Write-Error $_.Exception.Message
    }
}

function Write-Log {
    Param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter()]
        [ValidateSet(1, 2, 3)]
        [int]$LogLevel = 1
    )

    Write-Output $Message
    $TimeGenerated = "$(Get-Date -Format HH:mm:ss).$((Get-Date).Millisecond)+000"
    $Line = '<![LOG[{0}]LOG]!><time="{1}" date="{2}" component="{3}" context="" type="{4}" thread="" file="">'
    $LineFormat = $Message, $TimeGenerated, (Get-Date -Format MM-dd-yyyy), "$ComponentName`:$($MyInvocation.ScriptLineNumber)", $LogLevel
    $Line = $Line -f $LineFormat
    Add-Content -Value $Line -Path $ScriptLogFilePath
}

#Start/Create the LogFile 
Start-Log -FilePath $LogPath
 
Write-Log "Stopping required services"
$Services = @('wuauserv', 'cryptSvc', 'bits', 'msiserver')
foreach ($Service in $Services) {
    Write-Log "Stopping service [$Service]"
    try {
        Stop-Service -Name $Service -Force
    }
    catch {
        Write-Log "Unable to stop service [$Service]"
    }
}

 
Write-Log "Clearing Software Distirbution and Catroot2 files"
try {
    $folder = 'SoftwareDistribution'
    If (Test-Path $env:SystemRoot\$folder`.old) {
        Remove-Item -Path $env:SystemRoot\$folder`.old -Force -Recurse
    }
    If (Test-Path $env:SystemRoot\$folder) {
        Write-Log "Renaming $env:SystemRoot\$folder to $folder.old"
        Rename-Item -Path $env:SystemRoot\$folder -NewName $folder`.old -Force -ErrorAction Stop
    }
}
catch {
    Write-Log "Unable to rename $folder"
}

$folder = 'catroot2'
try {
    If (Test-Path $env:SystemRoot\System32\$folder`.old) {
        Remove-Item -Path $env:SystemRoot\System32\$folder`.old -Force -Recurse
    }
    If (Test-Path $env:SystemRoot\System32\$folder) {
        Write-Log "Renaming  $env:SystemRoot\System32\$folder $folder.old"
        Rename-Item -Path $env:SystemRoot\System32\$folder -NewName $folder`.old -Force -ErrorAction Stop
    }
}
catch {
    Write-Log "Unable to rename $folder"
}

Write-Log "Renaming the Windows Update Logs Folder"
try {
    Rename-Item -Path "$env:windir\Logs\WindowsUpdate" -NewName "WindowsUpdate-$(Get-Date -Format yyyyMMdd-HHmmss)" -Force -ErrorAction Stop
}
catch {
    Write-Log "Unable to Rename C:\Windows\Logs\WindowsUpdate"
}

Write-Log "Starting Windows Update services"
foreach ($Service in $Services) {
    try {
        Write-Log "Starting service [$Service]"
        Start-Service -Name $Service
    }
    catch {
        Write-Log "Unable to start service [$Service]"
    }
}