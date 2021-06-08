param (
    [object]$WebhookData
)

<#
Payload examples:
{
  "identity": "user@contoso.com"
}
#>

$Credentials = Get-AutomationPSCredential -Name "ForwardingAdministrator"

# ensure we called from Webhook by checking for null
if ($WebhookData) {
    if (!$WebhookData.RequestBody) {
        $Payload = ConvertFrom-Json -InputObject $WebhookData
    } else {
        $Payload = ConvertFrom-Json -InputObject $WebhookData.RequestBody
    }
    # connect to Microsoft Teams PowerShell
    Connect-MicrosoftTeams -Credential $Credentials

    # ensure user exists:
    $UserToQuery = Get-CsOnlineUser -Identity $Payload.Identity
    if ($UserToQuery) {
        # set voicemail forwarding
        $ForwardingParams = @{
            Identity = $UserToQuery.UserPrincipalName
        }
        $Settings = Get-CsOnlineVoicemailUserSettings @ForwardingParams

        # we could update list/data service here with whatever settings are retrieved
        $Settings
    }
    # cleanup session
    Disconnect-MicrosoftTeams
} else {
    Write-Output "Runbook not called via webhook, exiting."
}
