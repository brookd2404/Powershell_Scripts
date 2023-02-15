param (
    # The Update Policy ID
    [Parameter(Mandatory = $true)]
    [string]
    $updatePolicyID,
    # ISO8601 Timeformat for Deferral
    [Parameter(Mandatory = $true)]
    [string]
    $deferralTime
)
    

function Update-PatchDeferrals {
    <#
    .SYNOPSIS
        This function is to be used to update the Patch Deferral on Update Policies.
    .NOTES
        This has only been tested for the commercial driver and firmware updates.
    .EXAMPLE
        Update-PatchDeferrals -updatePolicyID <id> -deferralTime PT1D
        Explanation of the function or its result. You can include multiple The deferral time must be in the ISO8601 format. 
    #>
    [CmdletBinding()]
    param (
        # The Update Policy ID
        [Parameter(Mandatory = $true)]
        [string]
        $updatePolicyID,
        # ISO8601 Timeformat for Deferral
        [Parameter(Mandatory = $true)]
        [string]
        $deferralTime
    )
    
    begin {
        #The Base Object for the post Body
        $paramBody = @{
            "@odata.type"         = "#microsoft.graph.windowsUpdates.updatePolicy"
            complianceChangeRules = @()
        }
        # Create the param body base
        $complianceChangeRules = (Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/beta/admin/windows/updates/updatePolicies/$updatePolicyID" -Method GET).complianceChangeRules
    }
   
    process {
        
        $paramBody.complianceChangeRules += $complianceChangeRules
        $paramBody.complianceChangeRules | foreach-object {
            $_.durationBeforeDeploymentStart = $deferralTime
        }

    }
    
    end {

        Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/beta/admin/windows/updates/updatePolicies/$updatePolicyID" -Method PATCH -Body $paramBody
    }
}

Connect-MgGraph -Scopes "WindowsUpdates.ReadWrite.All" -ContextScope CurrentUser

Update-PatchDeferrals -updatePolicyID $updatePolicyID -deferralTime $deferralTime