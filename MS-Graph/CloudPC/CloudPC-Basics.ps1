[CmdletBinding()]
param (
    [Parameter(DontShow = $true)]
    [Array]
    $ModuleNames = @("Microsoft.Graph", "MSAL.PS"),
    [Parameter(DontShow = $true)]
    [String]
    $RedirectURI = "urn:ietf:wg:oauth:2.0:oob",
    [Parameter(DontShow = $true)]
    [array]
    $Scopes = @("CloudPC.ReadWrite.All"),
    # This is the Microsoft PowerShell App Registration within AzureAD
    [Parameter(DontShow = $true)]
    [String]
    $ClientID = "d1ddf0e4-d672-4dae-b554-9d5bdfd93547",
    [Parameter(DontShow = $true)]
    [String]
    $graphEndpoint = "https://graph.microsoft.com/beta"
)

#For Each Module in the ModuleNames Array, Attempt to install them
FOREACH ($Module in $ModuleNames) {
    IF (!(Get-Module -ListAvailable -Name $Module)) {
        try {
            Write-Output "Attempting to install $Module Module for the Current Device"
            Install-Module -Name $Module -Force -AllowClobber
        }
        catch {
            Write-Output "Attempting to install $Module Module for the Current User"
            Install-Module -Name $Module -Force -AllowClobber -Scope CurrentUser
        }
    }  
}

#region MSAL Access Token

#############################################
#                MSAL Auth                  #
#############################################

$Token = Get-MsalToken -ClientId $ClientID -Scopes $Scopes -RedirectUri $RedirectURI

#############################################
#                First Call                 #
#              List Cloud PCs               #
#############################################
#Build up the Restmethod Parameters
$GraphParams = @{
    Method  = "GET" #Perform a GET Action
    URI     = "$graphEndpoint/deviceManagement/virtualEndpoint/cloudPCs" #Against this Endpoint
    Headers = @{
        Authorization = "Bearer $($Token.AccessToken)" 
        Accept = "application/json"
    } #Using the Token as the Authorisation header, and accept only a JSON object in return
}
#Invoke the request
$GraphRequest = Invoke-RestMethod @GraphParams -ErrorAction Stop
#View Values
$GraphRequest.value

#############################################
#             Handle NextLinks              #
#############################################

#Build up the Restmethod Parameters
$GraphParams = @{
    Method  = "GET" #Perform a GET Action
    URI     = "$graphEndpoint/deviceManagement/virtualEndpoint/cloudPCs" #Against this Endpoint
    Headers = @{
        Authorization = "Bearer $($Token.AccessToken)" 
        Accept = "application/json"
    } #Using the Token as the Authorisation header, and accept only a JSON object in return
}
#Invoke the request
$GraphRequest = Invoke-RestMethod @GraphParams -ErrorAction Stop
$All_GraphRequests = @() #Create a blank array
$All_GraphRequests += $GraphRequest #Add the original request results
#While there is a NextLink Available, loop though and append the array.
while ($GraphRequest.'@odata.nextLink') {
    $GraphRequest_NextLink = @{
        Method      = "GET"
        URI         = $GraphRequest.'@odata.nextLink'
        Headers = @{
            Authorization = "Bearer $($Token.AccessToken)" 
            Accept = "application/json"
        } 
    }
    $GraphRequest = Invoke-RestMethod @GraphRequest_NextLink -ErrorAction Stop
    $All_GraphRequests += $GraphRequest
}
$All_GraphRequests.Value #View Results


#############################################
#        Create Provisioning Policy         #
#############################################

#region get the gallery image
$GraphParams = @{
    Method  = "GET" 
    URI     = "$graphEndpoint/deviceManagement/virtualEndpoint/galleryImages" 
    Headers = @{
        Authorization = "Bearer $($Token.AccessToken)" 
        Accept = "application/json"
    } 
}

#Invoke the request
$GraphRequest = Invoke-RestMethod @GraphParams -ErrorAction Stop
#View Values
$galleryImage = $GraphRequest.value | Where-Object {($_.RecommendedSku -EQ "heavy") -and ($_.DisplayName -match "11") -and ($_.SkuDisplayName -eq "22H2")}
#endregion get the gallery image

#region Create Provisioning Policy
$params = @{
	DisplayName = "PowerShell Demo"
	Description = ""
	ImageId = $galleryImage.id
	ImageType = "gallery"
	MicrosoftManagedDesktop = @{
		Type = "notManaged"
	}
	DomainJoinConfiguration = @{
		Type = "azureADJoin"
		RegionName = "automatic"
		RegionGroup = "usWest"
	}
}
$GraphParams = @{
    Method  = "POST" 
    URI     = "$graphEndpoint/deviceManagement/virtualEndpoint/provisioningPolicies" 
    Headers = @{
        Authorization = "Bearer $($Token.AccessToken)" 
        Accept = "application/json"
    }
    ContentType = "application/json"
    Body = ($params | ConvertTo-Json -Depth 5)
}

#Invoke the request
$GraphRequest = Invoke-RestMethod @GraphParams -ErrorAction Stop
#View Values
$provisioningPolicyID = $GraphRequest.id
#endregion Create Provisioning Policy

#region Add policy assignment
$assignmentParams = @{
	Assignments = @(
		@{
			Target = @{
                GroupId = "<GroupID>"
			}
		}
	)
}

$GraphParams = @{
    Method  = "POST" 
    URI     = "$graphEndpoint/deviceManagement/virtualEndpoint/provisioningPolicies/$($provisioningPolicyID)/assign" 
    Headers = @{
        Authorization = "Bearer $($Token.AccessToken)" 
        Accept = "application/json"
    }
    ContentType = "application/json"
    Body = ($assignmentParams | ConvertTo-Json -Depth 5)
}

#Invoke the request
$GraphRequest = Invoke-RestMethod @GraphParams -ErrorAction Stop

#endregion Add Policy Assignment
#endregion MSAL Access Token

#region Microsoft.Graph

#############################################
#               Graph Auth                  #
#############################################

Connect-MgGraph -Scopes $Scopes

#############################################
#                First Call                 #
#              List Cloud PCs               #
#############################################
#The first port of call is change the graph profile to beta
Select-MgProfile -Name beta

#Return a list of machines
Get-MgDeviceManagementVirtualEndpointCloudPC 

#Handling Next NextLinks
Get-MgDeviceManagementVirtualEndpointCloudPC -All

#############################################
#        Create Provisioning Policy         #
#############################################

$galleryImage = Get-MgDeviceManagementVirtualEndpointGalleryImage | Where-Object {($_.RecommendedSku -EQ "heavy") -and ($_.DisplayName -match "11") -and ($_.SkuDisplayName -eq "22H2")}

$params = @{
	DisplayName = "PowerShell Demo1"
	Description = ""
	ImageId = $galleryImage.id
	ImageType = "gallery"
	MicrosoftManagedDesktop = @{
		Type = "notManaged"
	}
	DomainJoinConfiguration = @{
		Type = "azureADJoin"
		RegionName = "automatic"
		RegionGroup = "usWest"
	}
}

$provisioningPolicy = New-MgDeviceManagementVirtualEndpointProvisioningPolicy -BodyParameter $params

$assignmentParams = @{
	Assignments = @(
		@{
			Target = @{
				GroupId = "<GroupID>"
			}
		}
	)
}

Set-MgDeviceManagementVirtualEndpointProvisioningPolicy -CloudPcProvisioningPolicyId $provisioningPolicy.id -BodyParameter $assignmentParams

#endregion Microsoft.Graph


