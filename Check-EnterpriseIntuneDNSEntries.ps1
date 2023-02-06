[CmdletBinding()]
param (
    [Parameter(DontShow = $true)]
    [array]
    $endpoints = @('enterpriseEnrollment-s.manage.microsoft.com', 'enterpriseRegistration.windows.net'),
    # Array of Domains
    [Parameter()]
    [array]
    $domains = @("example.com","sub.example.com")
)

Function Test-DNSEntries {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]
        $domains
    )
    FOREACH ($domain in $domains) {
        foreach ($endpoint in $endpoints) {
            $endpointName = $endpoint.Split('.')[0] -replace "-s", $null
            $cnameEndpoint = "$endpointName.$domain"
            $dnsQuery = Resolve-DnsName -Type CNAME -DnsOnly $cnameEndpoint
            $outObj = [PSCustomObject]@{
                Name                = $cnameEndpoint
                CurrentValue        = $dnsQuery.NameHost
                ExpectedValue       = $endpoint
                ConfiguredforTenant = $null
            }
            switch ($dnsQuery) {
                { ($PSItem.Name -match $cnameEndpoint) -and ($PSItem.NameHost -match $endpoint) } { 
                    $outObj.ConfiguredforTenant += $true 
                }
                { -not($PSItem.NameHost -match $endpoint) } { 
                    $outObj.ConfiguredforTenant += $false
                }
            }
            $outObj
        }
    }
}

Test-DNSEntries -domains $domains 
