using namespace System.Net

# Input bindings are passed in via param block.
param($jobData, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell Queue Item trigger function processed a request."

Import-Module -Name MicrosoftTeams

$ConnectionTimeoutSeconds = 300
$UserName = $env:TEAMS_ADMIN_USER
$Password = $env:TEAMS_ADMIN_PASSWORD

$Credential = [System.Management.Automation.PSCredential]::new($UserName, ($Password | ConvertTo-SecureString -Force -AsPlainText))

# Add an option to remove the machine profile
$SessionOption = New-PSSessionOption -NoMachineProfile


# connect to Microsoft Teams PowerShell
$SW = [Diagnostics.Stopwatch]::StartNew()

do {
    try {
        $CsSession = [Microsoft.Teams.ConfigApi.Cmdlets.TrpsSessionPsCmds]::new().NewSession($Credential, '', '', $SessionOption)
        Import-PSSession -Session $CsSession -AllowClobber | Out-Null
    }
    catch {
        if ( $_.Exception.InnerException.ErrorCode -ne 0x803381A5 ) {
            Write-Error "Could not connect to Microsoft Teams PowerShell: $($_.Exception.Message)"
        }
        else {
            Write-Warning "Maximum admin sessions in use, retrying for next $($ConnectionTimeoutSeconds - $sw.Elapsed.TotalSeconds) seconds"
        }
    }
} while ($null -eq $CsSession -and $SW.Elapsed.TotalSeconds -lt $ConnectionTimeoutSeconds)
$SW.Stop()

if ($CsSession) {
    Write-Host "Session created in $($SW.Elapsed.TotalSeconds) seconds."
    # ensure user exists:
    $UserToUpdate = Get-CsOnlineUser -Identity $jobData.Identity
    if ($UserToUpdate) {
        # set voicemail forwarding
        $ForwardingParams = @{
            Identity       = $UserToUpdate.UserPrincipalName
            TransferTarget = $jobData.Target
            CallAnswerRule = if ($jobData.Target) { "PromptOnlyWithTransfer" } else { "RegularVoicemail" }
            # DefaultGreetingPromptOverwrite = ""
            # DefaultOofGreetingPromptOverwrite = ""
        }
        Set-CsOnlineVoicemailUserSettings @ForwardingParams
    }
    else {
        Write-Warning "User $($jobData.Identity) not found!"
    }
    $CsSession | Remove-PSSession
}
else {
    Write-Error "Could not connect to Microsoft Teams PowerShell"
}
