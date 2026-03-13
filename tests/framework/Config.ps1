# ============================================================================
# TEST FRAMEWORK CONFIGURATION
# ============================================================================
# This file contains environment-specific configuration settings that may
# need to be changed based on the deployment environment or Azure DevOps setup.

$script:TestFrameworkConfiguration = @{
  # Pipeline compilation settings
  # These settings are used to compile YAML templates in the context of
  # a specific Azure DevOps organization, project, and pipeline.
  # Update these values to match your Azure DevOps environment.
  CompileBaseParams = @{
    Organization = "ukhydro"
    Project = "DevOps Chapter"
    PipelineId = 1576
  }

  # Validation settings
  # These control environment validation behavior during framework initialization
  Validation = @{
    # Check if Azure DevOps CLI is installed
    CheckAzDevOpsCli = $true

    # Check if user is authenticated with Azure (az account)
    CheckAzAuthentication = $true

    # Check if configuration values are not null/empty
    CheckConfigValues = $true

    # Fail on validation error (if $false, only warnings are shown)
    FailOnValidationError = $true
  }
}

return $script:TestFrameworkConfiguration

