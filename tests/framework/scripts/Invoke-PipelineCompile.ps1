# This script compiles and validates an Azure DevOps pipeline YAML with arguments.
# It sends the YAML to the Azure DevOps REST API for compilation and validates the result.
# Returns the compilation response as a Run object or an error object on failure.
#
# See: docs/developers/10-azure-devops-rest-api-pipeline-yaml.md
# See: https://learn.microsoft.com/en-us/rest/api/azure/devops/pipelines/runs/run-pipeline?view=azure-devops-rest-7.1#run
#
# RETURNS:
# ========
# SUCCESS: [PSObject] Run object with the following properties:
#   - id: The ID of the run
#   - name: The name of the run
#   - pipeline: The pipeline reference
#   - state: The state of the run (e.g., 'inProgress')
#   - result: The result of the run (null for in-progress runs)
#   - createdDate: When the run was created
#   - finishedDate: When the run completed (null if in-progress)
#   - url: The URL to the run
#   - And other properties as documented in the Microsoft API reference
#
# FAILURE: [PSObject] Error object with debug information:
#   - success: Always $false for error objects
#   - error.message: The PowerShell exception message
#   - error.statusCode: HTTP status code (e.g., 400, 401, 403, 404, 500)
#   - error.apiMessage: The Azure DevOps API error message (if available)
#   - error.apiResponse: The full parsed API response (if available)
#   - error.customProperties: Detailed validation errors from YAML parsing (if available)
#   - error.rawResponse: Raw API response body (if JSON parsing failed)
#   - error.remediation: Suggested remediation steps based on error type
#
# USAGE EXAMPLES:
# ===============
#
# Example 1: Basic usage with simple YAML content
#   $yaml = @"
#   trigger:
#     - main
#   pool:
#     vmImage: 'ubuntu-latest'
#   steps:
#     - script: echo Hello, world!
#   "@
#
#   .\Invoke-PipelineCompile.ps1 `
#     -YamlContent $yaml `
#     -Organization "myorg" `
#     -Project "myproject" `
#     -PipelineId 1
#
# Example 2: With pipeline arguments/variables
#   $yaml = @"
#   parameters:
#     - name: environment
#       type: string
#       default: 'dev'
#   trigger:
#     - main
#   pool:
#     vmImage: 'ubuntu-latest'
#   steps:
#     - script: echo Deploying to ${{ parameters.environment }}
#   "@
#
#   $args = @{
#     "environment" = "production"
#   }
#
#   .\Invoke-PipelineCompile.ps1 `
#     -YamlContent $yaml `
#     -Arguments $args `
#     -Organization "myorg" `
#     -Project "myproject" `
#     -PipelineId 1 `
#     -Verbose
#
# Example 3: Loading YAML from a file
#   $yaml = Get-Content -Path ".\pipelines\my-pipeline.yml" -Raw
#
#   .\Invoke-PipelineCompile.ps1 `
#     -YamlContent $yaml `
#     -Organization "myorg" `
#     -Project "myproject" `
#     -PipelineId 1
#
# Example 4: Capture and use the returned Run object
#   $yaml = Get-Content -Path ".\pipelines\my-pipeline.yml" -Raw
#
#   $runObject = .\Invoke-PipelineCompile.ps1 `
#     -YamlContent $yaml `
#     -Organization "myorg" `
#     -Project "myproject" `
#     -PipelineId 1
#
#   # Access Run object properties
#   Write-Host "Run ID: $($runObject.id)"
#   Write-Host "Run State: $($runObject.state)"
#   Write-Host "Run Result: $($runObject.result)"
#   Write-Host "Run URL: $($runObject.url)"
#   Write-Host "Created: $($runObject.createdDate)"
#   Write-Host "Full Run Object: $($runObject | ConvertTo-Json -Depth 10)"
#
# Example 5: Handle success and error responses
#   $yaml = Get-Content -Path ".\pipelines\my-pipeline.yml" -Raw
#
#   $result = .\Invoke-PipelineCompile.ps1 `
#     -YamlContent $yaml `
#     -Organization "myorg" `
#     -Project "myproject" `
#     -PipelineId 1
#
#   if ($result.success -eq $false) {
#     # Handle error - contains debug information about YAML issues
#     Write-Host "Compilation failed: $($result.error.message)"
#     Write-Host "Status Code: $($result.error.statusCode)"
#     Write-Host "Remediation: $($result.error.remediation)"
#
#     # If YAML parsing errors exist, they'll be in customProperties
#     if ($result.error.customProperties) {
#       Write-Host "YAML Errors:"
#       $result.error.customProperties | ConvertTo-Json | Write-Host
#     }
#
#     # Access full API response for detailed debugging
#     if ($result.error.apiResponse) {
#       Write-Host "Full API Response: $($result.error.apiResponse | ConvertTo-Json -Depth 10)"
#     }
#   }
#   else {
#     # Success - normal Run object
#     Write-Host "Run created: $($result.id)"
#   }
#
# REQUIREMENTS:
# =============
# - Azure CLI installed and authenticated: az login
# - Access to the Azure DevOps REST API with Build (read & execute) scope

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
    previewRun = $true
  }

  if ($Arguments -and $Arguments.Count -gt 0) {
    Write-Verbose "Adding $($Arguments.Count) argument(s) to compilation request"
    $bodyObject.variables = $Arguments
    Write-Verbose "Arguments: $($Arguments | ConvertTo-Json)"
  }

  $bodyJson = $bodyObject | ConvertTo-Json -Depth 10
  Write-Verbose "Request body size: $($bodyJson.Length) bytes"

  # Get access token from Azure CLI logged-in context
  Write-Verbose "Retrieving access token from Azure CLI logged-in context..."
  try {
    $accessToken = az account get-access-token --query accessToken -o tsv
    if (-not $accessToken) {
      throw "Failed to retrieve access token from Azure CLI"
    }
  }
  catch {
    throw "Unable to get access token from Azure CLI. Ensure you are logged in with 'az login' and have the required permissions."
  }

  $headers = @{
    Authorization = "Bearer $accessToken"
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

  # Provide remediation guidance based on error type (verbose only)
  Write-Verbose "Remediation guidance for status code $statusCode"
  switch ($statusCode) {
    400 {
      Write-Verbose "Bad Request - Check YAML syntax, parameter names/types, required parameters, template paths"
      $errorObject.error.remediation = "Check YAML syntax, parameter names/types, required parameters, template paths"
    }
    401 {
      Write-Verbose "Unauthorized - Verify you are logged in with 'az login' and have the required Build (read & execute) scope"
      $errorObject.error.remediation = "Verify you are logged in with 'az login' and have the required Build (read & execute) scope"
    }
    403 {
      Write-Verbose "Forbidden - Verify your Azure CLI login has project permissions and required access"
      $errorObject.error.remediation = "Verify your Azure CLI login has project permissions and required access"
    }
    404 {
      Write-Verbose "Not Found - Verify pipeline ID ($PipelineId), organization ($Organization), and project ($Project)"
      $errorObject.error.remediation = "Verify pipeline ID ($PipelineId), organization ($Organization), and project ($Project)"
    }
    500 {
      Write-Verbose "Internal Server Error - Retry operation or check Azure DevOps service status"
      $errorObject.error.remediation = "Retry operation or check Azure DevOps service status"
    }
    default {
      Write-Verbose "Unexpected error - Review error message and check 10-azure-devops-rest-api-pipeline-yaml.md"
      $errorObject.error.remediation = "Review error message and check 10-azure-devops-rest-api-pipeline-yaml.md"
    }
  }

  Write-Verbose "Error details: $($errorObject | ConvertTo-Json -Depth 10)"

  return $errorObject
}

