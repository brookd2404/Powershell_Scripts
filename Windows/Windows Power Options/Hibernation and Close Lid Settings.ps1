function Start-Log {
    Param (
        [Parameter(Mandatory = $true)]
        [string]$LogName
    )
    try {
        If (Test-Path $env:SystemRoot\CCM) {
            $LogPath = "$env:SystemRoot\CCM\Logs" # places the logfile in with all the other ConfigMgr logs
        }
        Else {
            If (!(Test-Path $env:SystemRoot\Logs\Software)) {
                New-Item $env:SystemRoot\Logs\Software -ItemType Directory -Force | Out-Null
            }
            $LogPath = "$env:SystemRoot\Logs\Software" # places the logfile in the ProgramData\PowerON\Logs
        }

        ## Set the global variable to be used as the FilePath for all subsequent Write-Log calls in this session
        If ($LogName -notlike "*.log") {
            $LogName = $LogName + '.log'
        }
        $global:ScriptLogFilePath = "$LogPath\$LogName"
        Write-Verbose "Log set to: $ScriptLogFilePath"

        If (!(Test-Path $ScriptLogFilePath)) {
            Write-Verbose "Creating new log file."
            New-Item -Path "$ScriptLogFilePath" -ItemType File | Out-Null
        }
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
        [string]$ComponentName,

        [Parameter()]
        [ValidateSet(1, 2, 3, 'Information', 'Warning', 'Error')]
        [string]$LogLevel = 1
    )

    switch ($LogLevel) {
        'Information' { [int]$LogLevel = 1 }
        'Warning' { [int]$LogLevel = 2 }
        'Error' { [int]$LogLevel = 3 }
        Default { [int]$LogLevel = $LogLevel }
    }

    If ([string]::IsNullOrEmpty($ComponentName)) {
        Write-Debug "No ComponentName param specified, setting to log name"
        $ComponentName = (Split-Path $ScriptLogFilePath -Leaf)
    }

    Write-Verbose $Message
    $TimeGenerated = "$(Get-Date -Format HH:mm:ss).$((Get-Date).Millisecond)+000"
    $Line = '<![LOG[{0}]LOG]!><time="{1}" date="{2}" component="{3}" context="" type="{4}" thread="" file="">'
    $LineFormat = $Message, $TimeGenerated, (Get-Date -Format MM-dd-yyyy), "$ComponentName`:$($MyInvocation.ScriptLineNumber)", $LogLevel
    $Line = $Line -f $LineFormat
    Try {
        Add-Content -Value $Line -Path $ScriptLogFilePath -Encoding 'utf8'
    }
    catch {
        Write-Verbose "Warning: Unable to append to log file - Retrying"
        Try {
            Add-Content -Value $Line -Path $ScriptLogFilePath -Encoding 'utf8'
        }
        catch {
            Write-Verbose "Error: Failed to append to log file"
        }
    }
}

Start-Log -LogName 'Set-PowerOptions'

Try {
    #Find selected power scheme guid
    [regex]$regex = "(\{){0,1}[a-fA-F0-9]{8}-([a-fA-F0-9]{4}-){3}[a-fA-F0-9]{12}(\}){0,1}"
    $guid = ($regex.Matches((Get-CimInstance -ClassName Win32_PowerPlan -Namespace 'root\cimv2\power' -Filter "IsActive = TRUE").InstanceID)).Value -replace '{|}', ''

    #Do not sleep when closing lid on AC
    Write-Log "Setting Option: No action when closing lid on AC."
    Start-Process PowerCfg -ArgumentList "/SETACVALUEINDEX $guid SUB_BUTTONS LIDACTION 000" -Wait
    Write-Log "Setting Option: Hibernate after 180 Minutes on AC."
    Start-Process PowerCFG -ArgumentList "/SETACVALUEINDEX $guid SUB_SLEEP HIBERNATEIDLE 10800" -Wait
    Write-Log "Setting Option: Hibernate after 180 Minutes on DC."
    Start-Process PowerCFG -ArgumentList "/SETDCVALUEINDEX $guid SUB_SLEEP HIBERNATEIDLE 3600" -Wait
    Exit 0
}
catch {
    Write-Log "Failed to set Lid Action." -LogLevel Error
    Exit 1
}
