$rKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint"

[hashtable]$rValues = @{
    NoWarningNoElevationOnInstall = 0
    UpdatePromptSettings = 0
}

$rOutput = @()

FOREACH ($rValue in $rValues.Keys) {
    $cItem = Get-ItemProperty -Path $rKey -Name $rValue -ErrorAction SilentlyContinue
    IF (-not($cItem)){
        $rOutput += 'Complaint'
    } ELSE {
        IF ($cItem.$rValue -eq $rValues[$rValue]){
            $rOutput += 'Complaint'
        } ELSE {
            $rOutput += 'NonComplaint'
        }
    }

}
