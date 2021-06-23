using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Interact with query parameters or the body of the request.
$uri = [Uri]::new($Request.Url)
$httpHost = $Request.Headers["Host"]
$identity = $Request.Params.identity

Write-Host "Generating Request Page for " $identity

$page = @"
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <title>Manage Forwarding</title>
  </head>
  <body>
    <form method="POST" action="$($uri.Scheme)://${httpHost}/api/ParseResponse">
      <input type="hidden" name="identity" value="${identity}"/>
      <input type="tel" name="target" autofocus="" />
      <input type="submit" value="Set Forwarding"/>
    </form>
  </body>
</html>
"@

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $page
    ContentType = "text/xml"
})
