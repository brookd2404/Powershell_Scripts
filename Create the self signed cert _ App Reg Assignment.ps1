# Create the self signed cert
$currentDate = Get-Date
$endDate  = $currentDate.AddYears(1)
$notAfter  = $endDate.AddYears(1)
$pwd  = "estorepassword"
$thumb = (New-SelfSignedCertificate -CertStoreLocation cert:\localmachine\my -DnsName estore.digital.nhs.uk -KeyExportPolicy Exportable -Provider "Microsoft Enhanced RSA and AES Cryptographic Provider" -NotAfter $notAfter).Thumbprint
$pwd = ConvertTo-SecureString -String $pwd -Force -AsPlainText
Export-PfxCertificate -cert "cert:\localmachine\my\$thumb" -FilePath c:\temp\examplecert.pfx -Password $pwd

# Load the certificate
$cert  = New-Object System.Security.Cryptography.X509Certificates.X509Certificate("C:\temp\estoreSelfSigned.pfx", $pwd)
$keyValue = [System.Convert]::ToBase64String($cert.GetRawCertData())

New-AzureADApplicationKeyCredential -ObjectId "76aa0f3a-4e20-4248-9587-c55ccaf44315" -CustomKeyIdentifier "eStoreSelfSigned" -StartDate $currentDate -EndDate $endDate -Type AsymmetricX509Cert -Usage Verify -Value $keyValue
