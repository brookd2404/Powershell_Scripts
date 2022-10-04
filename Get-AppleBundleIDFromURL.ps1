$baseURL = "https://itunes.apple.com/lookup?id="
$CountrySuffix = "&country=gb"
$Apps = Import-Csv -Path '.\OneDrive\Desktop\Apps3.csv'

$Object = @()

FOREACH ($App in $Apps) {
    $ID = $App.URL -replace '\D+(\d+)','$1'
    $URL = $baseURL + $ID + $CountrySuffix

    $Result = Invoke-WebRequest -UseBasicParsing -Uri $URl
    $ResultContent = $Result.Content | ConvertFrom-Json | Select-Object -ExpandProperty Results | Select-Object -ExpandProperty bundleId

    "$($App.Name),$ResultContent" | Out-File -FilePath '.\OneDrive - PowerONPlatforms\Desktop\Apps4.csv' -Append 
}
