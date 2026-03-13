<#
.SYNOPSIS
Wrapper around Invoke-PipelineCompile that uses script-scoped base parameters.

.DESCRIPTION
This is a lightweight wrapper that reduces boilerplate in test code by
automatically using $script:CompileBaseParams (set in Initialize-TestEnvironment).

.PARAMETER YamlContent
The YAML pipeline content to compile.

.PARAMETER Arguments
Optional pipeline arguments/variables as a hashtable.

.EXAMPLE
$result = Test-CompileYaml -YamlContent $yaml
$result = Test-CompileYaml -YamlContent $yaml -Arguments @{ env = "prod" }
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
    $Arguments = @{ }
  )

  # Validate that base parameters are set
  if (-not $script:CompileBaseParams)
  {
    throw @"
`$script:CompileBaseParams is not set. Please call Initialize-TestEnvironment first.

In your test file BeforeAll block:
  . (Join-Path (Get-TestFrameworkRoot) "Core.ps1")
  Initialize-TestEnvironment -TestFilePath `$PSScriptRoot
"@
  }

  if (-not $script:InvokePipelineCompilePath)
  {
    throw "`$script:InvokePipelineCompilePath is not set. Call Initialize-TestEnvironment first."
  }

  # Invoke the compilation with base params + provided arguments
  & $script:InvokePipelineCompilePath `
    -YamlContent $YamlContent `
    -Arguments $Arguments `
    @script:CompileBaseParams
}

