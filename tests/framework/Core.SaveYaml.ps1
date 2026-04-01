# ============================================================================
# TEST FRAMEWORK - SAVE COMPILED YAML
# ============================================================================
# Saves compiled YAML output to disk for inspection and debugging.

function Save-CompiledYamlToFile
{
  <#
  .SYNOPSIS
    Saves compiled YAML output to disk in an organized directory structure.

  .DESCRIPTION
    When enabled, saves the compiled YAML from Azure DevOps API to disk in
    a template-specific folder adjacent to the test file. This is useful for
    debugging complex templates, version control tracking, or regression testing.

  .PARAMETER TestFilePath
    The full path to the test file (PS1) that is running. Used to determine
    the output directory location.

  .PARAMETER TemplateName
    The name of the template being tested. Used as the output folder name.
    Example: "windows_test", "terraform_build"

  .PARAMETER TestCaseDescription
    The description of the test case. Used as the filename (sanitized).
    Example: "with default parameters"

  .PARAMETER CompiledYaml
    The compiled YAML content returned from Azure DevOps API.

  .EXAMPLE
    Save-CompiledYamlToFile -TestFilePath "C:\repo\tests\windows_test.ps1" `
      -TemplateName "windows_test" `
      -TestCaseDescription "with default parameters" `
      -CompiledYaml $result.finalYaml
  #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $TestFilePath,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $TemplateName,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $TestCaseDescription,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $CompiledYaml
  )

  try
  {
    # Get the directory containing the test file
    $outputFolderName = "$TemplateName-compiled-yaml"
    $outputDirectoryPath = Join-Path $TestFilePath $outputFolderName

    # Sanitize the description for use as a filename
    # Replace invalid filename characters with underscores
    $sanitizedDescription = $TestCaseDescription -replace '[<>:"/\\|?*]', '_'
    # Also replace spaces and multiple underscores for cleaner names
    $sanitizedDescription = $sanitizedDescription -replace '\s+', '_'
    $sanitizedDescription = $sanitizedDescription -replace '_+', '_'
    $sanitizedDescription = $sanitizedDescription -replace '^_|_$', ''  # Trim leading/trailing underscores

    $filename = "$sanitizedDescription.yml"
    $outputFilePath = Join-Path $outputDirectoryPath $filename

    # Create output directory if it doesn't exist
    if (-not (Test-Path -Path $outputDirectoryPath -PathType Container))
    {
      New-Item -ItemType Directory -Path $outputDirectoryPath -Force | Out-Null
      Write-Verbose "Created output directory: $outputDirectoryPath"
    }

    # Write the compiled YAML to file
    $CompiledYaml | Out-File -FilePath $outputFilePath -Encoding UTF8 -Force

    Write-Verbose "Saved compiled YAML to: $outputFilePath"
  }
  catch
  {
    Write-Warning "Failed to save compiled YAML: $_"
  }
}
