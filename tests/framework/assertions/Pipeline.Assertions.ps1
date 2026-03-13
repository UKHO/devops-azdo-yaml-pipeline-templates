<#
.SYNOPSIS
Custom Pester assertions for pipeline compilation validation.

.DESCRIPTION
Provides reusable assertion functions for validating Azure DevOps pipeline
YAML compilation results.
#>

<#
.SYNOPSIS
Assert that a pipeline compilation succeeded.

.PARAMETER Result
The result object returned from Test-CompileYaml.

.EXAMPLE
$result | Assert-PipelineCompilationSuccess
#>
function Assert-PipelineCompilationSuccess
{
  [CmdletBinding()]
  param (
    [Parameter(Mandatory, ValueFromPipeline)]
    [ValidateNotNull()]
    [psobject]
    $Result
  )

  if ($null -eq $Result)
  {
    throw "Compilation result is null. The pipeline compilation script did not return a valid response."
  }

  if ($Result.success -eq $false)
  {
    $errorMessage = "Pipeline compilation failed unexpectedly.`n"
    $errorMessage += "Error: $($Result.error.message)`n"
    $errorMessage += "Status Code: $($Result.error.statusCode)"

    if ($Result.error.customProperties)
    {
      $errorMessage += "`nDetails: $($Result.error.customProperties | ConvertTo-Json -Depth 3)"
    }

    throw $errorMessage
  }

  if ([string]::IsNullOrWhiteSpace($Result.id))
  {
    throw "Pipeline compilation succeeded but no Run ID was returned. Expected a valid Run ID in the response."
  }
}

<#
.SYNOPSIS
Assert that a pipeline compilation failed with expected error details.

.PARAMETER Result
The result object returned from Test-CompileYaml.

.PARAMETER ExpectedStatusCode
The HTTP status code expected (e.g., 400, 401, 403, 404, 500).

.PARAMETER ExpectedMessage
A string that should be contained in the error message.

.PARAMETER ExpectedErrorDetail
A string that should be contained in the error details (customProperties).

.EXAMPLE
$result | Assert-PipelineCompilationFailure `
  -ExpectedStatusCode 400 `
  -ExpectedMessage "Invalid key"
#>
function Assert-PipelineCompilationFailure
{
  [CmdletBinding()]
  param (
    [Parameter(Mandatory, ValueFromPipeline)]
    [ValidateNotNull()]
    [psobject]
    $Result,

    [Parameter()]
    [ValidateRange(400, 599)]
    [int]
    $ExpectedStatusCode,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]
    $ExpectedMessage,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]
    $ExpectedErrorDetail
  )

  if ($null -eq $Result)
  {
    throw "Compilation result is null. Expected a failure response object."
  }

  if ($Result.success -ne $false)
  {
    throw "Expected pipeline compilation to fail, but it succeeded with Run ID: $($Result.id). The YAML was accepted when it should have been rejected."
  }

  # Validate status code if specified
  if ($PSBoundParameters.ContainsKey('ExpectedStatusCode'))
  {
    if ($Result.error.statusCode -ne $ExpectedStatusCode)
    {
      throw "Expected HTTP status code $ExpectedStatusCode but got $($Result.error.statusCode)."
    }
  }

  # Validate error message if specified
  if ($PSBoundParameters.ContainsKey('ExpectedMessage'))
  {
    $errorMessageToCheck = $Result.error.apiMessage ?? $Result.error.message ?? ""

    if ($errorMessageToCheck -notlike "*$ExpectedMessage*")
    {
      throw "Expected error message to contain '$ExpectedMessage' but got: '$errorMessageToCheck'"
    }
  }

  # Validate error details if specified
  if ($PSBoundParameters.ContainsKey('ExpectedErrorDetail'))
  {
    $errorDetailsJson = if ($Result.error.customProperties)
    {
      $Result.error.customProperties | ConvertTo-Json -Depth 10
    }
    else
    {
      ""
    }

    if ($errorDetailsJson -notlike "*$ExpectedErrorDetail*")
    {
      throw "Expected error details to contain '$ExpectedErrorDetail' but got: '$errorDetailsJson'"
    }
  }
}

