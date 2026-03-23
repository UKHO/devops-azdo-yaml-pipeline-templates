# ============================================================================
# TEST FRAMEWORK - UTILITIES
# ============================================================================
# Path resolution and helper functions.

function Get-RepositoryRoot {
  <#
  .SYNOPSIS
    Get the repository root directory.
  #>
  return $script:TestState.RepositoryRoot
}

function Get-RepositoryPath {
  <#
  .SYNOPSIS
    Resolve a path relative to the repository root.
  #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string] $RelativePath
  )

  return Join-Path $script:TestState.RepositoryRoot $RelativePath
}

function Get-FrameworkRoot {
  <#
  .SYNOPSIS
    Get the test framework root directory.
  #>
  return $script:TestState.FrameworkRoot
}

