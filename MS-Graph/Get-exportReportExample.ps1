<#
.SYNOPSIS
    This script connects to Microsoft Graph and generates a report for all applications.

.DESCRIPTION
    The script performs the following steps:
    1. Connects to Microsoft Graph.
    2. Creates the body of the request to generate the report.
    3. Creates the request parameters to generate the report.
    4. Sends a POST request to initiate the report generation.
    5. Waits for the report to be generated by periodically checking the report status.

.NOTES
    Author: David Brook
    Date: 01/01/2025
    Version: 1.0

#>

#Connect to the Microsoft Graph
Connect-MgGraph

#Create the body of the request to generate the report
$body = @{
    reportName = "AllAppsList"
}

#Create the request parameters to generate the report
$requestSplat = @{
    Method = 'POST'
    Uri    = 'https://graph.microsoft.com/beta/deviceManagement/reports/exportJobs'
    Body   = $body | ConvertTo-Json
}

#POST the initial report request
$reportRequest = Invoke-MgGraphRequest @requestSplat

#Wait for the report to be generated
do
{
    Start-Sleep -Seconds 5
    $checkReportSplat = @{
        Method = 'GET'
        Uri    = "https://graph.microsoft.com/beta/deviceManagement/reports/exportJobs('$($reportRequest.id)')"
    }
    $reportRequest = Invoke-MgGraphRequest @checkReportSplat
} while ($reportRequest.status -ne "completed")

#Download the report
$netClient = [System.Net.WebClient]::new()
$destination = "C:\temp\$($reportRequest.id).csv"

#If the folder does not exist, create it
if (-not (Test-Path (Split-Path $destination)))
{
    New-Item -ItemType Directory -Path (Split-Path $destination)
}

$netClient.DownloadFile($reportRequest.url, $destination)