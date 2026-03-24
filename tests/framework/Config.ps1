# ============================================================================
# TEST FRAMEWORK CONFIGURATION
# ============================================================================
# This file contains all environment-specific configuration that may
# need to be changed based on the deployment environment or Azure DevOps setup.
#
# All paths are relative to the repository root.
# All settings are loaded into a hashtable that's passed to the test runner.

[CmdletBinding()]
param()

$config = @{
  AzureDevOps = @{
    Organization = "ukhydro"
    Project = "DevOps Chapter"
    PipelineId = 1576
  }

  TestDiscovery = @{
    Pattern = "tests/**/*.Tests.ps1"
  }

  TestExecution = @{
    ShowVerboseOutput = $false
  }
}

return $config

