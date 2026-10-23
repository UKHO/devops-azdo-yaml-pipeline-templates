# ============================================================================
# TEST FRAMEWORK - COMPILE YAML
# ============================================================================
# Takes Yaml Content with Parameters, invokes Azure DevOps REST API to
# compile the pipeline (preview run), and returns the response.
#
# Requests are sent concurrently (bounded by TestExecution.MaxConcurrentRequests)
# over a single shared HttpClient so that connections are reused across test
# files in the same PowerShell session.

function script:Get-CompileHttpClient
{
  if ($null -eq $global:AzDOCompileTestHttpClient)
  {
    $handler = [System.Net.Http.SocketsHttpHandler]::new()
    $handler.PooledConnectionLifetime = [TimeSpan]::FromMinutes(5)
    $handler.MaxConnectionsPerServer = 64
    $client = [System.Net.Http.HttpClient]::new($handler)
    $client.Timeout = [TimeSpan]::FromSeconds(300)
    $global:AzDOCompileTestHttpClient = $client
  }
  return $global:AzDOCompileTestHttpClient
}

function script:Get-CompileUri
{
  $apiVersion = "7.1-preview.1"
  $encodedOrganization = [uri]::EscapeDataString($script:TestState.AzDO.Organization)
  $encodedProject = [uri]::EscapeDataString($script:TestState.AzDO.Project)
  return "https://dev.azure.com/$encodedOrganization/$encodedProject/_apis/pipelines/$( $script:TestState.AzDO.PipelineId )/runs?api-version=$apiVersion"
}

function script:New-CompileRequestBody
{
  param(
    [string]
    $YamlContent,

    [hashtable]
    $Parameters
  )

  $bodyObject = @{
    yamlOverride = $YamlContent
    previewRun = $true
  }

  if ($script:TestState.TargetBranch)
  {
    $bodyObject.resources = @{
      repositories = @{
        self = @{
          refName = "refs/heads/$( $script:TestState.TargetBranch )"
        }
      }
    }
  }

  if ($Parameters -and $Parameters.Count -gt 0)
  {
    # The Azure DevOps REST API templateParameters expects a flat Dictionary<string, string>.
    # Object/array parameter values must be serialised to JSON strings.
    $stringifiedParameters = @{ }
    foreach ($key in $Parameters.Keys)
    {
      $value = $Parameters[$key]
      if ($value -is [hashtable] -or $value -is [System.Collections.IDictionary] -or $value -is [array])
      {
        $stringifiedParameters[$key] = ($value | ConvertTo-Json -Depth 10 -Compress)
      }
      else
      {
        $stringifiedParameters[$key] = [string]$value
      }
    }
    $bodyObject.templateParameters = $stringifiedParameters
  }

  return ($bodyObject | ConvertTo-Json -Depth 10)
}

function script:Send-CompileRequest
{
  param(
    [string]
    $Uri,

    [string]
    $Body
  )

  $message = [System.Net.Http.HttpRequestMessage]::new([System.Net.Http.HttpMethod]::Post, $Uri)
  $message.Headers.Authorization = [System.Net.Http.Headers.AuthenticationHeaderValue]::new("Bearer", $script:TestState.AccessToken)
  $message.Content = [System.Net.Http.StringContent]::new($Body, [System.Text.Encoding]::UTF8, "application/json")
  return (script:Get-CompileHttpClient).SendAsync($message)
}

function script:New-CompileErrorObject
{
  param(
    [string]
    $Message,

    $StatusCode,

    [string]
    $ApiMessage,

    $ApiResponse
  )

  return @{
    success = $false
    error = @{
      message = $Message
      statusCode = $StatusCode
      apiMessage = $ApiMessage
      apiResponse = $ApiResponse
    }
  }
}

function script:ConvertFrom-CompileResponse
{
  param(
    [System.Net.Http.HttpResponseMessage]
    $Response,

    [string]
    $Content
  )

  $statusCode = [int]$Response.StatusCode

  if ($Response.IsSuccessStatusCode)
  {
    $parsed = $null
    if (-not [string]::IsNullOrWhiteSpace($Content))
    {
      $parsed = $Content | ConvertFrom-Json
    }
    if ($null -eq $parsed)
    {
      return (script:New-CompileErrorObject -Message "Received null response from Azure DevOps API" -StatusCode $statusCode `
        -ApiMessage "Received null response from Azure DevOps API")
    }
    Write-Verbose "Pipeline YAML compilation succeeded. Run ID: $( $parsed.id )"
    return $parsed
  }

  $errorMessage = "Response status code does not indicate success: $statusCode ($( $Response.ReasonPhrase ))."
  $apiMessage = $null
  $apiResponse = $null
  if (-not [string]::IsNullOrWhiteSpace($Content))
  {
    try
    {
      $apiResponse = $Content | ConvertFrom-Json
      $apiMessage = $apiResponse.message
    }
    catch
    {
      Write-Verbose "Failed to parse error details from response body: $_"
    }
  }

  Write-Verbose "Pipeline YAML compilation failed: $errorMessage $apiMessage"
  return (script:New-CompileErrorObject -Message $errorMessage -StatusCode $statusCode -ApiMessage $apiMessage -ApiResponse $apiResponse)
}

<#
.SYNOPSIS
  Compile many YAML payloads concurrently.

.PARAMETER Requests
  Array of hashtables with keys YamlContent (string) and Parameters (hashtable).

.PARAMETER MaxConcurrency
  Maximum number of in-flight requests. Defaults to TestExecution.MaxConcurrentRequests.

.OUTPUTS
  Array of results, in the same order as Requests. Each result is either the
  parsed API response (has id / finalYaml) or an error object
  (@{ success = $false; error = @{ message; statusCode; apiMessage; apiResponse } }).
#>
function Invoke-CompileYamlBatch
{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [AllowEmptyCollection()]
    [array]
    $Requests,

    [Parameter()]
    [int]
    $MaxConcurrency = $script:TestState.MaxConcurrentRequests
  )

  $count = $Requests.Count
  $results = [object[]]::new($count)
  if ($count -eq 0)
  {
    return , $results
  }
  if ($MaxConcurrency -lt 1)
  {
    $MaxConcurrency = 1
  }

  $uri = script:Get-CompileUri
  $bodies = [string[]]::new($count)
  for ($i = 0; $i -lt $count; $i++)
  {
    $bodies[$i] = script:New-CompileRequestBody -YamlContent $Requests[$i].YamlContent -Parameters $Requests[$i].Parameters
  }

  $maxAttempts = 5
  $attempts = [int[]]::new($count)
  $queue = [System.Collections.Generic.Queue[int]]::new()
  for ($i = 0; $i -lt $count; $i++)
  {
    $queue.Enqueue($i)
  }
  $pending = [System.Collections.Generic.List[object]]::new()

  Write-Verbose "Compiling $count YAML payload(s) with concurrency $MaxConcurrency against $uri"

  while ($queue.Count -gt 0 -or $pending.Count -gt 0)
  {
    while ($queue.Count -gt 0 -and $pending.Count -lt $MaxConcurrency)
    {
      $index = $queue.Dequeue()
      $attempts[$index]++
      $pending.Add(@{ Index = $index; Task = (script:Send-CompileRequest -Uri $uri -Body $bodies[$index]) })
    }

    # Wait with a timeout so Ctrl+C remains responsive
    $tasks = [System.Threading.Tasks.Task[]]@($pending | ForEach-Object { $_.Task })
    $completed = [System.Threading.Tasks.Task]::WaitAny($tasks, 250)
    if ($completed -lt 0)
    {
      continue
    }

    $entry = $pending[$completed]
    $pending.RemoveAt($completed)
    $index = $entry.Index
    $task = $entry.Task

    if ($task.IsFaulted -or $task.IsCanceled)
    {
      $exceptionMessage = "Request timed out or was cancelled"
      if ($task.IsFaulted)
      {
        $exceptionMessage = $task.Exception.GetBaseException().Message
      }
      if ($attempts[$index] -lt $maxAttempts)
      {
        Write-Verbose "Request $index failed ($exceptionMessage); retrying"
        $queue.Enqueue($index)
        continue
      }
      $results[$index] = script:New-CompileErrorObject -Message $exceptionMessage -StatusCode $null -ApiMessage "Request failed: $exceptionMessage"
      continue
    }

    $response = $task.Result
    try
    {
      $statusCode = [int]$response.StatusCode
      if (($statusCode -eq 429 -or $statusCode -eq 503) -and $attempts[$index] -lt $maxAttempts)
      {
        $delay = [TimeSpan]::FromSeconds([Math]::Pow(2, $attempts[$index]))
        if ($response.Headers.RetryAfter -and $response.Headers.RetryAfter.Delta)
        {
          $delay = $response.Headers.RetryAfter.Delta
        }
        Write-Verbose "Request $index throttled ($statusCode); retrying after $( $delay.TotalSeconds )s"
        Start-Sleep -Milliseconds ([int]$delay.TotalMilliseconds)
        $queue.Enqueue($index)
        continue
      }

      $content = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
      $results[$index] = script:ConvertFrom-CompileResponse -Response $response -Content $content
    }
    finally
    {
      $response.Dispose()
    }
  }

  return , $results
}

<#
.SYNOPSIS
  Compile a single YAML payload. Thin wrapper around Invoke-CompileYamlBatch.
#>
function Test-CompileYaml
{
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $YamlContent,

    [Parameter()]
    [hashtable]
    $Parameters = @{ }
  )

  $results = Invoke-CompileYamlBatch -Requests @(@{ YamlContent = $YamlContent; Parameters = $Parameters }) -MaxConcurrency 1
  return $results[0]
}
