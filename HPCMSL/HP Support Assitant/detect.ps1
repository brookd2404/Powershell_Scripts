$AppPackage = Get-AppPackage | Where-Object { $_.Name -Like "*HPSupportAssistant*" }

IF ($AppPackage -ne $null)
{
    Exit 0
}
ELSE
{
    Exit 1
}