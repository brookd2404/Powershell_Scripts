$LocalGroup = "Hyper-V Administrators"
IF (Get-LocalGroup $LocalGroup ) {
    $true
}
