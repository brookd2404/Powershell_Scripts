if(!(Test-Path "C:\Temp")) {
    mkdir "C:\Temp\"
}

$TranscriptPath = "C:\Temp\Portest" + (Get-Date -Format yyyyMMdd_HHmmss) + ".log"

Start-Transcript $TranscriptPath

[array]$Endpoints = "login.microsoftonline.com","officeconfig.msocdn.com","config.office.com","graph.windows.net","enterpriseregistration.windows.net","portal.manage.microsoft.com","m.manage.microsoft.com","sts.manage.microsoft.com","Manage.microsoft.com","i.manage.microsoft.com","r.manage.microsoft.com","a.manage.microsoft.com","p.manage.microsoft.com","EnterpriseEnrollment.manage.microsoft.com","EnterpriseEnrollment-s.manage.microsoft.com","portal.fei.msua01.manage.microsoft.com","m.fei.msua01.manage.microsoft.com","portal.fei.msua02.manage.microsoft.com","m.fei.msua02.manage.microsoft.com","portal.fei.msua04.manage.microsoft.com","m.fei.msua04.manage.microsoft.com","portal.fei.msua05.manage.microsoft.com","m.fei.msua05.manage.microsoft.com","portal.fei.amsua0502.manage.microsoft.com","m.fei.amsua0502.manage.microsoft.com","portal.fei.msua06.manage.microsoft.com","m.fei.msua06.manage.microsoft.com","portal.fei.amsua0602.manage.microsoft.com","m.fei.amsua0602.manage.microsoft.com","fei.amsua0202.manage.microsoft.com","portal.fei.amsua0202.manage.microsoft.com","m.fei.amsua0202.manage.microsoft.com","portal.fei.amsua0402.manage.microsoft.com","m.fei.amsua0402.manage.microsoft.com","portal.fei.amsua0801.manage.microsoft.com","portal.fei.msua08.manage.microsoft.com","m.fei.msua08.manage.microsoft.com","m.fei.amsua0801.manage.microsoft.com","portal.fei.msub01.manage.microsoft.com","m.fei.msub01.manage.microsoft.com","portal.fei.amsub0102.manage.microsoft.com","m.fei.amsub0102.manage.microsoft.com","fei.msub02.manage.microsoft.com","portal.fei.msub02.manage.microsoft.com","m.fei.msub02.manage.microsoft.com","portal.fei.msub03.manage.microsoft.com","m.fei.msub03.manage.microsoft.com","portal.fei.msub05.manage.microsoft.com","m.fei.msub05.manage.microsoft.com","portal.fei.amsub0202.manage.microsoft.com","m.fei.amsub0202.manage.microsoft.com","portal.fei.amsub0302.manage.microsoft.com","m.fei.amsub0302.manage.microsoft.com","portal.fei.amsub0502.manage.microsoft.com","m.fei.amsub0502.manage.microsoft.com","portal.fei.amsub0601.manage.microsoft.com","m.fei.amsub0601.manage.microsoft.com","portal.fei.msuc01.manage.microsoft.com","m.fei.msuc01.manage.microsoft.com","portal.fei.msuc02.manage.microsoft.com","m.fei.msuc02.manage.microsoft.com","portal.fei.msuc03.manage.microsoft.com","m.fei.msuc03.manage.microsoft.com","portal.fei.msuc05.manage.microsoft.com","m.fei.msuc05.manage.microsoft.com","portal.fei.amsud0101.manage.microsoft.com","m.fei.amsud0101.manage.microsoft.com","fef.msua01.manage.microsoft.com","fef.msua02.manage.microsoft.com","fef.msua04.manage.microsoft.com","fef.msua05.manage.microsoft.com","fef.msua06.manage.microsoft.com","fef.msub01.manage.microsoft.com","fef.msub05.manage.microsoft.com","fef.msuc03.manage.microsoft.com","fef.amsua0502.manage.microsoft.com","fef.amsua0602.manage.microsoft.com","fef.amsua0102.manage.microsoft.com","fef.amsua0702.manage.microsoft.com","fef.amsub0502.manage.microsoft.com","fef.msud01.manage.microsoft.com","Admin.manage.microsoft.com","wip.mam.manage.microsoft.com","mam.manage.microsoft.com","manage.microsoft.com","enterpriseregistration.hscic.gov.uk", "EnterpriseEnrollment.hscic.gov.uk"

[array]$ports = "80", "443"

[System.Collections.ArrayList]$failedEndpoints = @()

foreach ($Endpoint in $Endpoints) {
    foreach ($port in $ports) {
        try {
            Test-NetConnection $Endpoint -Port $port  -WarningAction Stop
            Write-Host -ForegroundColor Green -BackgroundColor Black "Connection to $Endpoint Succeded on Port $Port"
        }
        catch {
            Write-Host -ForegroundColor Red -BackgroundColor Black "Connection to $Endpoint Failed on Port $Port"
            $ConCatEPandPort = $Endpoint + ":" + $port 
            $failedEndpoints.Add($ConCatEPandPort) 
        }
    }
}

Write-Warning "Failed Endpoints are "
$FailedEndpoints | Format-List

Stop-Transcript