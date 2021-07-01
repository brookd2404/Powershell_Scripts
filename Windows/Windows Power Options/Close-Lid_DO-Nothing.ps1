#Find selected power scheme guid
[regex]$regex = "(\{){0,1}[a-fA-F0-9]{8}-([a-fA-F0-9]{4}-){3}[a-fA-F0-9]{12}(\}){0,1}"
$guid = ($regex.Matches((Get-CimInstance -ClassName Win32_PowerPlan -Namespace 'root\cimv2\power' -Filter "IsActive = TRUE").InstanceID)).Value -replace '{|}', ''
#Do not sleep when closing lid on AC
Write-Output "Setting Option: No action when closing lid on AC."
Start-Process PowerCfg -ArgumentList "/SETACVALUEINDEX $guid SUB_BUTTONS LIDACTION 000" -Wait