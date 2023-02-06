<#
.SYNOPSIS
    This script will assist in gathering the required Image Option information for AIB Templates.
.DESCRIPTION
    This script will assist in gathering the required Image Option information for AIB Templates.
    It's sole purpose is to aid in providing the right information to AIB Templates.
.NOTES
    Image Publishers can be Identified by running `Get-AzVMImagePublisher -Location <Region>'

    Common Image Publisher used for AVD, Windows 365 etc. is MicrosoftWindowsDesktop
.EXAMPLE
    Get-ImageOptions.ps1 -SubscriptionId <Subid> -geoLocation "UKSouth" -imagePublisher "MicrosoftWindowsDesktop"
#>


[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [String]
    $SubscriptionId, #Subscription to check
    [Parameter(Mandatory = $true)]
    [String]
    $geoLocation,
    [Parameter(Mandatory = $true)]
    [String]
    $imagePublisher
)

#Check that the correct subscription is currently being used
$AzContext = Get-AzContext

if ($AzContext.Subscription.Id -ne $SubscriptionId) {
    Write-Output "Updating Subscription context"
    try {
        Select-AzSubscription -SubscriptionId $SubscriptionId -ErrorAction Stop
    }
    catch {
        Write-Output "Unable to select subscription $SubscriptionId, Forcing new login"
        Login-AzAccount -SubscriptionId $SubscriptionId -ErrorAction Stop
    }
}

$Offers = Get-AzVMImageOffer -Location $geoLocation -PublisherName $imagePublisher -ErrorAction Stop

foreach ($Offer in $Offers) {
    $SKUs = Get-AzVMImageSku -Location $geoLocation -PublisherName $imagePublisher -Offer $Offer.Offer
    Write-Output $Offer.Offer
    foreach ($SKU in $SKUs) {
        $Versions = Get-AzVMImage -Location $geoLocation -PublisherName $imagePublisher -Offer $Offer.Offer -Skus $SKU.Skus
        if ($null -ne $Versions) {
            Write-Output "`t$($SKU.Skus)"
        }
    }
}
