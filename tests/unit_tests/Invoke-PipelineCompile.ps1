# This script compiles and validates an Azure DevOps pipeline YAML with arguments.
# It sends the YAML to the Azure DevOps REST API for compilation and validates the result.
# Returns the compilation response or throws on failure.
#
# See: docs/developers/10-azure-devops-rest-api-pipeline-yaml.md

[CmdletBinding()]
param (
  [Parameter(Mandatory,
    ValueFromPipeline,
    HelpMessage = "The YAML pipeline content as a string.")]
  [ValidateNotNullOrEmpty()]
  [string] $YamlContent,

  [Parameter()]
  [hashtable] $Arguments = @{},

  [Parameter(Mandatory,
    HelpMessage = "Azure DevOps organization name.")]
  [ValidateNotNullOrEmpty()]
  [string] $Organization,

  [Parameter(Mandatory,
    HelpMessage = "Azure DevOps project name.")]
  [ValidateNotNullOrEmpty()]
  [string] $Project,

  [Parameter(Mandatory,
    HelpMessage = "Pipeline ID to compile against.")]
  [ValidateRange(1, [int]::MaxValue)]
  [int] $PipelineId,

  [Parameter(Mandatory,
    HelpMessage = "Azure DevOps Personal Access Token with Build (read & execute) scope.")]
  [ValidateNotNullOrEmpty()]
  [string] $PersonalAccessToken,

  [Parameter()]
  [ValidateNotNullOrEmpty()]
  [string] $ApiVersion = "7.1-preview.1"
)

try {
  Write-Verbose "Starting $($MyInvocation.MyCommand.Name) script"
  Write-Verbose "Organization: $Organization | Project: $Project | Pipeline ID: $PipelineId"

  # Validate inputs
  if ($YamlContent.Trim().Length -eq 0) {
    throw "YamlContent cannot be empty or whitespace"
  }

  Write-Verbose "YAML content length: $($YamlContent.Length) characters"

  # Prepare request body
  Write-Verbose "Preparing compilation request body..."
  $bodyObject = @{
    yamlOverride = $YamlContent
  }

  if ($Arguments -and $Arguments.Count -gt 0) {
    Write-Verbose "Adding $($Arguments.Count) argument(s) to compilation request"
    $bodyObject.variables = $Arguments
    Write-Verbose "Arguments: $($Arguments | ConvertTo-Json)"
  }

  $bodyJson = $bodyObject | ConvertTo-Json -Depth 10
  Write-Verbose "Request body size: $($bodyJson.Length) bytes"

  # Prepare authentication
  Write-Verbose "Preparing authentication..."
  $encodedToken = [Convert]::ToBase64String(
    [Text.Encoding]::ASCII.GetBytes(":$PersonalAccessToken")
  )

  $headers = @{
    Authorization = "Basic $encodedToken"
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

  Write-Error "Pipeline YAML compilation failed: $errorMessage"

  if ($statusCode) {
    Write-Verbose "HTTP Status Code: $statusCode"
  }

  # Try to extract detailed error from response body
  if ($_.ErrorDetails.Message) {
    try {
      $errorJson = $_.ErrorDetails.Message | ConvertFrom-Json
      Write-Verbose "API Error Message: $($errorJson.message)"

      if ($errorJson.customProperties) {
        Write-Verbose "Error Details: $($errorJson.customProperties | ConvertTo-Json)"
      }
    }
    catch {
      Write-Verbose "Raw API Response: $($_.ErrorDetails.Message)"
    }
  }

  # Provide remediation guidance based on error type (verbose only)
  Write-Verbose "Remediation guidance for status code $statusCode"
  switch ($statusCode) {
    400 {
      Write-Verbose "Bad Request - Check YAML syntax, parameter names/types, required parameters, template paths"
    }
    401 {
      Write-Verbose "Unauthorized - Verify PAT is valid, not expired, and has Build (read & execute) scope"
    }
    403 {
      Write-Verbose "Forbidden - Verify PAT has project permissions and service connection has repository access"
    }
    404 {
      Write-Verbose "Not Found - Verify pipeline ID ($PipelineId), organization ($Organization), and project ($Project)"
    }
    500 {
      Write-Verbose "Internal Server Error - Retry operation or check Azure DevOps service status"
    }
    default {
      Write-Verbose "Unexpected error - Review error message and check 10-azure-devops-rest-api-pipeline-yaml.md"
    }
  }

  throw
}
