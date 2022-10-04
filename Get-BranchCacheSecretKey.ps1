$key = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\PeerDist\SecurityManager\Restricted'
Get-Item $key | select -Expand property | % {
   $value = (Get-ItemProperty -Path $key -Name $_).$_
   $passphrase = [System.Text.Encoding]::Unicode.GetString($value)
}
Write-Host "The Server Secret is:" -NoNewline
Write-Host $passphrase -ForegroundColor Yellow