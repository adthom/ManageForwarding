using namespace System.Net
using namespace System.Web

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

$ContentType = $Request.Headers["Content-Type"]
$fReq = [PSCustomObject]@{
    Target   = $null
    Identity = $null
}

if ($ContentType -eq "application/x-www-form-urlencoded") {
    $formData = [HttpUtility]::ParseQueryString($Request.Body)
    $fReq.Target = $formData["target"]
    $fReq.Identity = $formData["identity"]
}

$htmlTemplate = @"
<html xmlns=`"http://www.w3.org/1999/xhtml`">
  <head>
    <title>Manage Forwarding</title>
  </head>
  <body>
    <p>{0}</p>
  </body>
</html>
"@

if (![string]::IsNullOrEmpty($fReq.Identity)) {
    $rBody = ConvertTo-Json -InputObject $fReq -Compress
    Write-Host $rBody
    $responseMessage = if ([string]::IsNullOrEmpty($fReq.Target)) {
        "Your forwarding settings will be reset."
    }
    else {
        "Your phone will be set to forward to $($fReq.Target)."
    }

    Push-OutputBinding -Name jobData -Value $rBody
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::OK
            Body       = $htmlTemplate -f $responseMessage
            ContentType = "text/xml"
        })
}
else {
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::BadRequest
            Body       = $htmlTemplate -f "Your request was malformed"
            ContentType = "text/xml"
        })
}