param (
    [object]$WebhookData
)

<#
Payload examples:
    EV target:
    {
    "identity": "user@contoso.com",
    "target": "+15555551234"
    }

    or sip target:
    {
    "identity": "user@contoso.com",
    "target": "sip:user2@contoso.com"
    }

    or to clear transfer:
    {
    "identity": "user@contoso.com",
    "target": ""
    }
#>

$ConnectionTimeoutSeconds = 300

$Credentials = Get-AutomationPSCredential -Name "ForwardingAdministrator"

# ensure we called from Webhook by checking for null
if ($WebhookData) {
    if (!$WebhookData.RequestBody) {
        $Payload = ConvertFrom-Json -InputObject $WebhookData
    }
    else {
        $Payload = ConvertFrom-Json -InputObject $WebhookData.RequestBody
    }
    # connect to Microsoft Teams PowerShell
    Connect-MicrosoftTeams -Credential $Credentials

    $SW = [Diagnostics.Stopwatch]::StartNew()
    do {
        try {
            $Session = [Microsoft.Teams.ConfigApi.Cmdlets.TrpsSessionPsCmds]::new().GetSession()
        }
        catch {
            if ( $_.Exception.InnerException.ErrorCode -ne 0x803381A5 ) {
                Write-Error "Could not connect to Microsoft Teams PowerShell: $($_.Exception.Message)"
            }
        }
    } while ($null -eq $Session -and $SW.Elapsed.TotalSeconds -lt $ConnectionTimeoutSeconds)
    $SW.Stop()

    if ($Session) {
        # ensure user exists:
        $UserToUpdate = Get-CsOnlineUser -Identity $Payload.Identity
        if ($UserToUpdate) {
            # set voicemail forwarding
            $ForwardingParams = @{
                Identity       = $UserToUpdate.UserPrincipalName
                TransferTarget = $Payload.Target
                CallAnswerRule = if ($Payload.Target) { "PromptOnlyWithTransfer" } else { "RegularVoicemail" }
                # DefaultGreetingPromptOverwrite = ""
                # DefaultOofGreetingPromptOverwrite = ""
            }
            Set-CsOnlineVoicemailUserSettings @ForwardingParams
        }
        else {
            Write-Warning "User $($Payload.Identity) not found!"
        }
    }
    else {
        Write-Error "Could not connect to Microsoft Teams PowerShell"
    }
    # cleanup session
    Disconnect-MicrosoftTeams
}
else {
    Write-Output "Runbook not called via webhook, exiting."
}
