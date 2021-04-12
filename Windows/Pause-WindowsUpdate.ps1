$TagFile = "$ENV:SystemRoot\Updates_DisaabledDuringESP.tag"
$CCMEXE = "$ENV:SystemRoot\CCM\CCMEXEC.EXE"
if ((-Not (Test-Path $TagFile)) -and (-Not (Test-Path $CCMEXE))) {
    $TMR = (Get-Date (Get-Date).AddDays(1) -Format yyyy-MM-ddTHH:MM:ss) + "Z"
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name 'PauseUpdatesExpiryTime' -Value $TMR -Force
    Write-Output "Disabeld on $(Get-Date -Format yyyy-MM-ddTHH:MM:ss)Z until $TMR" | Out-File $TagFile
} ELSE {
    "CCM Is installed or this script has already been run"
}

