<#
.SYNOPSIS
Compile an Azure DevOps pipeline YAML and return the result.

.DESCRIPTION
Sends a YAML pipeline to the Azure DevOps REST API for compilation and validation.
Returns a Run object on success or an error object on failure.

Handles all REST API interaction, authentication, error handling, and remediation.

.PARAMETER YamlContent
The YAML pipeline content as a string.

.PARAMETER Parameters
Optional pipeline parameters as a hashtable.

.PARAMETER Organization
Azure DevOps organization name (defaults to framework config).

.PARAMETER Project
Azure DevOps project name (defaults to framework config).

.PARAMETER PipelineId
Pipeline ID to compile against (defaults to framework config).

.EXAMPLE
$result = Test-CompileYaml -YamlContent $yaml
$result = Test-CompileYaml -YamlContent $yaml -Parameters @{ env = "prod" }

.RETURNS
On SUCCESS: [PSObject] Run object with properties like id, name, state, result, url, etc.
On FAILURE: [PSObject] Error object with success=$false and detailed error information.

See: https://learn.microsoft.com/en-us/rest/api/azure/devops/pipelines/runs/run-pipeline
#>
function Test-CompileYaml
{
  [CmdletBinding()]
  param (
    [Parameter(Mandatory, ValueFromPipeline)]
    [ValidateNotNullOrEmpty()]
    [string]
    $YamlContent,

    [Parameter()]
    [hashtable]
    $Parameters = @{ },

    [Parameter()]
    [string]
    $Organization,

    [Parameter()]
    [string]
    $Project,

    [Parameter()]
    [int]
    $PipelineId,

    [Parameter()]
    [string]
    $ApiVersion = "7.1-preview.1"
  )

  # Get base params from framework if not provided
  if (-not $script:TestState) {
    throw @"
Framework is not loaded. Please load the test framework first:

  `$config = & (Join-Path `$frameworkRoot "TestConfig.ps1")
  . (Join-Path `$frameworkRoot "Core.ps1") -Config `$config
"@
  }

  # Use framework defaults if parameters not provided
  if ([string]::IsNullOrWhiteSpace($Organization)) {
    $Organization = $script:TestState.AzDO.Organization
  }
  if ([string]::IsNullOrWhiteSpace($Project)) {
    $Project = $script:TestState.AzDO.Project
  }
  if ($PipelineId -eq 0) {
    $PipelineId = $script:TestState.AzDO.PipelineId
  }

  # =========================================================================
  # INVOKE PIPELINE COMPILE - REST API CALL
  # =========================================================================

  try {
    Write-Verbose "Compiling YAML for: Organization=$Organization | Project=$Project | Pipeline=$PipelineId"

    # Validate YAML content
    if ($YamlContent.Trim().Length -eq 0) {
      throw "YamlContent cannot be empty or whitespace"
    }

    # Prepare request body
    Write-Verbose "Preparing compilation request body..."
    $bodyObject = @{
      yamlOverride = $YamlContent
      previewRun = $true
    }

    if ($Parameters -and $Parameters.Count -gt 0) {
      Write-Verbose "Adding $($Parameters.Count) argument(s) to compilation request"
      $bodyObject.templateParameters = $Parameters
    }

    $bodyJson = $bodyObject | ConvertTo-Json -Depth 10
    Write-Verbose "Request body size: $($bodyJson.Length) bytes"

    $headers = @{
      Authorization = "Bearer $($script:TestState.AccessToken)"
      "Content-Type" = "application/json"
    }

    # Build URI
    $uri = "https://dev.azure.com/$Organization/$Project/_apis/pipelines/$PipelineId/runs?api-version=$ApiVersion"
    Write-Verbose "Target URI: $uri"

    # Send request
    Write-Verbose "Sending compilation request to Azure DevOps REST API..."
    $response = Invoke-RestMethod -Uri $uri `
      -Method Post `
      -Headers $headers `
      -Body $bodyJson `
      -TimeoutSec 300

    # Validate response
    if ($null -eq $response) {
      throw "Received null response from Azure DevOps API"
    }

    Write-Verbose "Pipeline YAML compilation succeeded. Run ID: $($response.id)"

    return $response
  }
  catch {
    $errorMessage = $_.Exception.Message
    $statusCode = $_.Exception.Response.StatusCode.Value__

    Write-Verbose "Pipeline YAML compilation failed: $errorMessage"

    if ($statusCode) {
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
    if ($_.ErrorDetails.Message) {
      try {
        $errorJson = $_.ErrorDetails.Message | ConvertFrom-Json
        $errorObject.error.apiMessage = $errorJson.message
        $errorObject.error.apiResponse = $errorJson

        if ($errorJson.customProperties) {
          $errorObject.error.customProperties = $errorJson.customProperties
          Write-Verbose "Error Details: $($errorJson.customProperties | ConvertTo-Json)"
        }
      }
      catch {
        $errorObject.error.rawResponse = $_.ErrorDetails.Message
        Write-Verbose "Raw API Response: $($_.ErrorDetails.Message)"
      }
    }

    # Provide remediation guidance based on error type
    switch ($statusCode) {
      400 {
        Write-Verbose "Bad Request - Check YAML syntax, parameter names/types, required parameters, template paths"
        $errorObject.error.remediation = "Check YAML syntax, parameter names/types, required parameters, template paths"
        break
      }
      401 {
        Write-Verbose "Unauthorized - Verify you are logged in with 'az login' and have the required Build (read & execute) scope"
        $errorObject.error.remediation = "Verify you are logged in with 'az login' and have the required Build (read & execute) scope"
        break
      }
      403 {
        Write-Verbose "Forbidden - Verify your Azure CLI login has project permissions and required access"
        $errorObject.error.remediation = "Verify your Azure CLI login has project permissions and required access"
        break
      }
      404 {
        Write-Verbose "Not Found - Verify pipeline ID ($PipelineId), organization ($Organization), and project ($Project)"
        $errorObject.error.remediation = "Verify pipeline ID ($PipelineId), organization ($Organization), and project ($Project)"
        break
      }
      500 {
        Write-Verbose "Internal Server Error - Retry operation or check Azure DevOps service status"
        $errorObject.error.remediation = "Retry operation or check Azure DevOps service status"
        break
      }
      default {
        Write-Verbose "Unexpected error - Review error message and Azure DevOps API documentation"
        $errorObject.error.remediation = "Review error message and Azure DevOps API documentation"
      }
    }

    Write-Verbose "Error details: $($errorObject | ConvertTo-Json -Depth 10)"

    return $errorObject
  }
}
