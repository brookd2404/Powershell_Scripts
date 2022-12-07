$DownloadPath = Join-Path -Path "C:\buildArtifacts" -ChildPath "Chrome.msi"
$wc = New-Object System.Net.WebClient
$wc.DownloadFile('https://dl.google.com/chrome/install/googlechromestandaloneenterprise64.msi', $DownloadPath) 
Start-Process -FilePath msiexec.exe -ArgumentList  "/i `"$DownloadPath`" /log `"C:\buildArtifacts\ChromeInstall.log`" /qn" -Wait