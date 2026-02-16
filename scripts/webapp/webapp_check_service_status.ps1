param (
	[Parameter(
    Mandatory = $true,
    HelpMessage = "The health endpoint to poll."
  )]
  [ValidateNotNullOrEmpty()]
  [string]$HealthEndpointUrl,

  [Parameter(
    Mandatory = $true,
    HelpMessage = "The maximum length of time to wait for a successful response."
  )]
  [ValidateRange(1, 30)]
  [int]$WaitTimeInMinutes
)

$sleepTimeInSeconds = 15
$isServiceActive = $false
$stopWatch = New-Object -TypeName System.Diagnostics.Stopwatch
$timeSpan = New-TimeSpan -Minutes $WaitTimeInMinutes
$stopWatch.Start()

do {
  Write-Host "Polling $HealthEndpointUrl..."

  try {
    $httpRequest  = [System.Net.WebRequest]::Create("$HealthEndpointUrl")
    $httpResponse = $httpRequest.GetResponse()
    $httpStatus   = $httpResponse.StatusCode
    Write-Host "Status code is $httpStatus"

    If ($httpStatus -eq 200 ) {
      Write-Host "Service is healthy - stopping polling..."
      $isServiceActive = $true
      break
    } else {
      Write-Host "Service not yet healthy. Status code is $httpStatus. Re-checking in $sleepTimeInSeconds seconds..."
    }
  }
  catch [System.Net.WebException] {
    $httpStatus = $_.Exception.Response.StatusCode
    Write-Host "Service not yet healthy. Status code is $httpStatus. Re-checking in $sleepTimeInSeconds seconds..."
  }

  Start-Sleep -Seconds $sleepTimeInSeconds
} until ($stopWatch.Elapsed -ge $timeSpan)

if ($httpResponse -ne $null) {
  $httpResponse.Close()
}

if ($isServiceActive -eq $true ) {
  Write-Host "Health check successful"
} else {

  if ($WaitTimeInMinutes -eq 1) {
    Write-Error "Health check unsuccessful after $WaitTimeInMinutes minute"
  } else {
    Write-Error "Health check unsuccessful after $WaitTimeInMinutes minutes"
  }

  throw "Error"
}
