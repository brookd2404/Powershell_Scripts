[CmdletBinding()]
param (
    [Parameter(DontShow = $true)]
    [Array]
    $ModuleNames = @("Microsoft.Graph.Teams"),
    # Teams Channel Name
    [Parameter(Mandatory = $true)]
    [String]
    $ChannelName
)

#TeamsAdmin and Groups admin Required


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
    Import-Module $Module
}

$params = @{
	"Template@odata.bind" = "https://graph.microsoft.com/beta/teamsTemplates('standard')"
	Visibility = "Private"
	DisplayName = $ChannelName
	Description = "This Teams Channel will be used for collaboration."
	Channels = @(
		@{
			DisplayName = "General"
			IsFavoriteByDefault = $true
			Description = "This channel will be used for communication purposes"
			Tabs = @(
                @{
					"TeamsApp@odata.bind" = "https://graph.microsoft.com/v1.0/appCatalogs/teamsApps('com.microsoft.teamspace.tab.web')"
					DisplayName = "Microsoft Endpoint Manager"
					Configuration = @{
						ContentUrl = "https://endpoint.microsoft.com"
					}
				}
			)
		},
        @{
			DisplayName = "Service Announcements"
			IsFavoriteByDefault = $true
			Description = "This tab will be used for things like Third Party Patching and other Service Related Alerts"
		}
	)
	MemberSettings = @{
		AllowCreateUpdateChannels = $true
		AllowDeleteChannels = $true
		AllowAddRemoveApps = $true
		AllowCreateUpdateRemoveTabs = $true
		AllowCreateUpdateRemoveConnectors = $true
	}
	GuestSettings = @{
		AllowCreateUpdateChannels = $true
		AllowDeleteChannels = $true
	}
	FunSettings = @{
		AllowGiphy = $true
		AllowStickersAndMemes = $true
		AllowCustomMemes = $true
	}
	MessagingSettings = @{
		AllowUserEditMessages = $true
		AllowUserDeleteMessages = $true
		AllowOwnerDeleteMessages = $true
		AllowTeamMentions = $true
		AllowChannelMentions = $true
	}
	DiscoverySettings = @{
		ShowInTeamsSearchAndSuggestions = $true
	}
	InstalledApps = @(
		@{
			"TeamsApp@odata.bind" = "https://graph.microsoft.com/v1.0/appCatalogs/teamsApps('com.microsoft.teamspace.tab.web')"
		}
		@{
            #The invoke webhook
			"TeamsApp@odata.bind" = "https://graph.microsoft.com/v1.0/appCatalogs/teamsApps('203a1e2c-26cc-47ca-83ae-be98f960b6b2')"
		}
	)
}

$Team = Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/beta/teams" -Body $params -Method POST -OutputType HttpResponseMessage

#Wait while the team is created, this below link tracks the job. 
while ((Invoke-MGGraphRequest -URI "https://graph.microsoft.com/beta$($Team.Headers.Location.OriginalString)").status -ne "succeeded") {
    Start-Sleep 60
    "Awaiting the team creation to complete..."
}

#Get the Teams ID from the Output of the header
$TeamID = (Select-String -Pattern "\'([^\']*)\'" -InputObject $Team.Content.Headers.ContentLocation.OriginalString).Matches.Groups[1].Value
#Get the Teams Channels for the new Team
$TeamChannels = Get-MgTeamChannel -TeamId $TeamID

#For Each of the Channels, remove the Wiki Tab and ensure they are all set to show by default
ForEach ($Channel in $TeamChannels) {
    $wikiTab = (Get-MgTeamChannelTab -ChannelId $Channel.id -TeamId $TeamID | Where-Object {$_.DisplayName -eq "Wiki"}).id

    Remove-MGTeamChannelTab -TeamId $TeamID -ChannelID $Channel.id -TeamsTabId $wikiTab

    Update-MGTeamChannel -TeamId $TeamID -ChannelID $Channel.id -IsFavoriteByDefault 
}

