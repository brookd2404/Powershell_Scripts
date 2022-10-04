[CmdletBinding()]
param (
    [Parameter()]
    [String]
    $baseURL = "https://support.lenovo.com/us/en/api/v4/mse/getproducts?productId=",
    [String]
    [ValidateScript({Test-Path $_})]
    $ModelTextFile = "$env:SystemDrive\Temp\LenovoModels.txt",
    [String]
    $OutputCSV = "$env:SystemDrive\Temp\LenovoModels.csv"

)

$ModelIDs = Get-Content -Path $ModelTextFile

$mainObj = @()

FOREACH ($Model in $ModelIDs) {
    $URL = $baseURL + $Model
    $WebContent = (Invoke-Webrequest -Uri $URL -UseBasicParsing -ContentType 'Application/JSON' -ErrorAction SilentlyContinue).Content | ConvertFrom-JSON 
    IF ($WebContent) {
        $obj = New-Object psobject
        $obj | Add-Member -MemberType NoteProperty -Name ModelID -Value $Model
        $obj | Add-Member -MemberType NoteProperty -Name ModelName -Value $WebContent.Name
        $obj | Add-Member -MemberType NoteProperty -Name IsSupported -Value $WebContent.IsSupported

        $mainObj += $obj
    }
}

$mainObj | Export-Csv -Path $OutputCSV -NoTypeInformation

  