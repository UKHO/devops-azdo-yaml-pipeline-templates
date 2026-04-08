# ============================================================================
# TEST FRAMEWORK - COMPILE YAML
# ============================================================================
# Takes Yaml Content with Parameters, invokes Azure DevOps REST API to
# compile the pipeline, and returns the response.

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

  $Organization = $script:TestState.AzDO.Organization
  $Project = $script:TestState.AzDO.Project
  $PipelineId = $script:TestState.AzDO.PipelineId
  $TargetBranch = $script:TestState.TargetBranch

  # =========================================================================
  # INVOKE PIPELINE COMPILE - REST API CALL
  # =========================================================================

  try
  {
    Write-Verbose "Compiling YAML for: Organization=$Organization | Project=$Project | Pipeline=$PipelineId | TargetBranch=$TargetBranch"
    if ($TargetBranch)
    {
      Write-Verbose "Using target branch: $TargetBranch"
    }

    # Prepare request body
    Write-Verbose "Preparing compilation request body..."
    $bodyObject = @{
      yamlOverride = $YamlContent
      previewRun = $true
    }

    # Add source version if specified
    if ($TargetBranch)
    {
      $bodyObject.resources = @{
        repositories = @{
          self = @{
            refName = "refs/heads/$TargetBranch"
          }
        }
      }
    }

    if ($Parameters -and $Parameters.Count -gt 0)
    {
      Write-Verbose "Adding $( $Parameters.Count ) argument(s) to compilation request"

      # The Azure DevOps REST API templateParameters expects a flat Dictionary<string, string>.
      # Object/array parameter values must be serialised to JSON strings.
      $stringifiedParameters = @{ }
      foreach ($key in $Parameters.Keys)
      {
        $value = $Parameters[$key]
        if ($value -is [hashtable] -or $value -is [System.Collections.IDictionary] -or $value -is [array])
        {
          $stringifiedParameters[$key] = ($value | ConvertTo-Json -Depth 10 -Compress)
          Write-Verbose "Serialised object parameter '$key' to JSON string"
        }
        else
        {
          $stringifiedParameters[$key] = [string]$value
        }
      }

      $bodyObject.templateParameters = $stringifiedParameters
    }

    $bodyJson = $bodyObject | ConvertTo-Json -Depth 10
    Write-Verbose "Request body: $( $bodyJson )"

    $headers = @{
      Authorization = "Bearer $( $script:TestState.AccessToken )"
      "Content-Type" = "application/json"
    }

    # Build URI
    $apiVersion = "7.1-preview.1"
    $encodedOrganization = [uri]::EscapeDataString($Organization)
    $encodedProject = [uri]::EscapeDataString($Project)
    $uri = "https://dev.azure.com/$encodedOrganization/$encodedProject/_apis/pipelines/$PipelineId/runs?api-version=$apiVersion"
    Write-Verbose "Target URI: $uri"

    # Send request
    Write-Verbose "Sending compilation request to Azure DevOps REST API..."
    $response = Invoke-RestMethod -Uri $uri `
      -Method Post `
      -Headers $headers `
      -Body $bodyJson `
      -TimeoutSec 300

    # Validate response
    if ($null -eq $response)
    {
      throw [System.NullReferenceException]::new("Received null response from Azure DevOps API")
    }

    Write-Verbose "Pipeline YAML compilation succeeded. Run ID: $( $response.id )"

    return $response
  }
  catch [System.NullReferenceException]
  {
    Write-Verbose "Null response received from Azure DevOps API"
    throw
  }
  catch
  {
    if ($null -eq $_.Exception.Message -or $null -eq $_.Exception.Response)
    {
      throw
    }

    $errorMessage = $_.Exception.Message
    $statusCode = $_.Exception.Response.StatusCode.Value__

    Write-Verbose "Pipeline YAML compilation failed: $errorMessage"

    if ($statusCode)
    {
      Write-Verbose "HTTP Status Code: $statusCode"
    }

    # Build error response object
    $errorObject = @{
      success = $false
      error = @{
        message = $errorMessage
        statusCode = $statusCode
      }
    }

    # Try to extract detailed error from response body
    if ($_.ErrorDetails.Message)
    {
      try
      {
        $errorJson = $_.ErrorDetails.Message | ConvertFrom-Json
        $errorObject.error.apiMessage = $errorJson.message
        $errorObject.error.apiResponse = $errorJson
      }
      catch
      {
        Write-Verbose "Failed to parse error details from response body: $_"
      }
    }

    Write-Verbose "Error details: $( $errorObject | ConvertTo-Json -Depth 10 )"

    return $errorObject
  }
}
