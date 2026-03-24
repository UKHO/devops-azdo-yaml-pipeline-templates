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

  # =========================================================================
  # INVOKE PIPELINE COMPILE - REST API CALL
  # =========================================================================

  try
  {
    Write-Verbose "Compiling YAML for: Organization=$Organization | Project=$Project | Pipeline=$PipelineId"

    # Validate YAML content
    if ($YamlContent.Trim().Length -eq 0)
    {
      throw "YamlContent cannot be empty or whitespace"
    }

    # Prepare request body
    Write-Verbose "Preparing compilation request body..."
    $bodyObject = @{
      yamlOverride = $YamlContent
      previewRun = $true
    }

    if ($Parameters -and $Parameters.Count -gt 0)
    {
      Write-Verbose "Adding $( $Parameters.Count ) argument(s) to compilation request"
      $bodyObject.templateParameters = $Parameters
    }

    $bodyJson = $bodyObject | ConvertTo-Json -Depth 10
    Write-Verbose "Request body size: $( $bodyJson.Length ) bytes"

    $headers = @{
      Authorization = "Bearer $( $script:TestState.AccessToken )"
      "Content-Type" = "application/json"
    }

    # Build URI
    $apiVersion = "7.1-preview.1"
    $uri = "https://dev.azure.com/$Organization/$Project/_apis/pipelines/$PipelineId/runs?api-version=$apiVersion"
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
      throw "Received null response from Azure DevOps API"
    }

    Write-Verbose "Pipeline YAML compilation succeeded. Run ID: $( $response.id )"

    return $response
  }
  catch
  {
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
      $errorJson = $_.ErrorDetails.Message | ConvertFrom-Json
      $errorObject.error.apiMessage = $errorJson.message
      $errorObject.error.apiResponse = $errorJson
    }

    Write-Verbose "Error details: $( $errorObject | ConvertTo-Json -Depth 10 )"

    return $errorObject
  }
}
