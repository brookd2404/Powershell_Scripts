<#
.SYNOPSIS
    This script is to be used to install the required Windows Features for the Intune SCEP Certificate Connector.
.DESCRIPTION
    This script will install the required Windows Features for the Intune SCEP Certificate Connector.
    The script will install the following Windows Features:
    - ADCS-Device-Enrollment
    - Web-Server
    - Web-WebServer
    - Web-Common-Http
    - Web-Default-Doc
    - Web-Dir-Browsing
    - Web-Http-Errors
    - Web-Static-Content
    - Web-Http-Redirect
    - Web-Health
    - Web-Http-Logging
    - Web-Log-Libraries
    - Web-Request-Monitor
    - Web-Http-Tracing
    - Web-Performance
    - Web-Stat-Compression
    - Web-Security
    - Web-Filtering
    - Web-Windows-Auth
    - Web-App-Dev
    - Web-Net-Ext
    - Web-Net-Ext45
    - Web-Asp-Net
    - Web-Asp-Net45
    - Web-ISAPI-Ext
    - Web-ISAPI-Filter
    - Web-Mgmt-Tools
    - Web-Mgmt-Console
    - Web-Mgmt-Compat
    - Web-Metabase
    - Web-WMI
    - NET-Framework-Features
    - NET-Framework-Core
    - NET-HTTP-Activation
    - NET-Framework-45-Features
    - NET-Framework-45-Core
    - NET-Framework-45-ASPNET
    - NET-WCF-Services45
    - NET-WCF-HTTP-Activation45
    - NET-WCF-TCP-PortSharing45
    - RSAT-ADCS-Mgmt
    - WAS
    - WAS-Process-Model
    - WAS-NET-Environment
    - WAS-Config-APIs

.NOTES
    This script is intended to be run on Windows Server operating systems.
    Ensure you have administrative privileges before running this script.
.LINK
    https://docs.microsoft.com/en-us/mem/intune/protect/certificates-scep-configure
.EXAMPLE
    .\Install-SCEPConnectorFeatures.ps1 -Verbose
    This will install all the required Windows Features for the Intune SCEP Certificate Connector with verbose output.
.NOTES
    File Name      : Install-SCEPConnectorFeatures.ps1
    Author         : David Brook
    Prerequisite   : Windows Server operating system
    Date           : 29/12/2024
    Version        : 1.0
#>

$featureSplat = @{
    Name = @(
        "ADCS-Device-Enrollment",
        "Web-Server",
        "Web-WebServer",
        "Web-Common-Http",
        "Web-Default-Doc",
        "Web-Dir-Browsing",
        "Web-Http-Errors",
        "Web-Static-Content",
        "Web-Http-Redirect",
        "Web-Health",
        "Web-Http-Logging",
        "Web-Log-Libraries",
        "Web-Request-Monitor",
        "Web-Http-Tracing",
        "Web-Performance",
        "Web-Stat-Compression",
        "Web-Security",
        "Web-Filtering",
        "Web-Windows-Auth",
        "Web-App-Dev",
        "Web-Net-Ext",
        "Web-Net-Ext45",
        "Web-Asp-Net",
        "Web-Asp-Net45",
        "Web-ISAPI-Ext",
        "Web-ISAPI-Filter",
        "Web-Mgmt-Tools",
        "Web-Mgmt-Console",
        "Web-Mgmt-Compat",
        "Web-Metabase",
        "Web-WMI",
        "NET-Framework-Features",
        "NET-Framework-Core",
        "NET-HTTP-Activation",
        "NET-Framework-45-Features",
        "NET-Framework-45-Core",
        "NET-Framework-45-ASPNET",
        "NET-WCF-Services45",
        "NET-WCF-HTTP-Activation45",
        "NET-WCF-TCP-PortSharing45",
        "RSAT-ADCS-Mgmt",
        "WAS",
        "WAS-Process-Model",
        "WAS-NET-Environment",
        "WAS-Config-APIs"
    )
}

Add-WindowsFeature @featureSplat