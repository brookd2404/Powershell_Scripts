
## For ConfigMgr 2111 and onwards
[Flags()]Enum CoManagementworkloads {
    NotConfigured = 1
    compliancepolicies = 2
    ResourceAccesspolicies = 4
    Deviceconfiguration = 8
    Windowsupdatespolicies = 16
    Endpointprotection = 4128
    ClientApps = 64
    OfficeClicktoRunApps = 128
    CoManagementconfigured = 8193
}

[CoManagementworkloads]$CoManagementworkloads = 111

write-Output $CoManagementworkloads


## For ConfigMgr 2111 and below
[Flags()]Enum CoManagementworkloads2111 {
    CoManagementConfigured = 1
    compliancepolicies = 2
    ResourceAccesspolicies = 4
    Deviceconfiguration = 8
    Windowsupdatespolicies = 16
    Endpointprotection = 32
    ClientApps = 64
    OfficeClicktoRunApps = 128
}

[CoManagementworkloads2111]$CoManagementworkloads = 111

write-Output $CoManagementworkloads