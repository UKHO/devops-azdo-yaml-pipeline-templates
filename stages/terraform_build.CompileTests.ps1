# ============================================================================
# TEST: Terraform Build Stage Template
# ============================================================================
# Tests for stages/terraform_build.yml: TerraformBuildConfig and the deprecated parameters are passed
# through to jobs/terraform_build.yml. Field validation is tested by the job and schema tests.

# Load framework (only if not already loaded)
if (-not (Get-Command -Name 'Run-Tests' -ErrorAction SilentlyContinue))
{
  $repoRoot = git rev-parse --show-toplevel 2> $null
  . (Join-Path $repoRoot "tests" "framework" "Core.ps1")
}

# ============================================================================
# DEFINE TEST CASES
# ============================================================================

$validTestCases = @(
  @{
    Description = "with default parameters"
    Parameters = @{ }
    ExpectedYaml = @(
      'stage: Build_Terraform',
      "displayName: Build 'TerraformArtifact' Terraform",
      'job: TerraformBuild_TerraformArtifact'
    )
    UnexpectedYaml = @(
      'DeprecatedParametersWarning'
    )
  },
  @{
    Description = "TerraformBuildConfig is passed to the job, including Checks"
    Parameters = @{
      TerraformBuildConfig = @"
ArtifactName: StageArtifact
RelativePathToTerraformFiles: infra
Checks:
  - Check: TerraformFormat
"@
    }
    ExpectedYaml = @(
      "displayName: Build 'StageArtifact' Terraform",
      'job: TerraformBuild_StageArtifact',
      'value: $(RepositoryDirectory)/infra',
      'name: TerraformTask_fmt'
    )
    UnexpectedYaml = @(
      'DeprecatedParametersWarning'
    )
  },
  @{
    Description = "deprecated parameters are passed to the job, which logs a warning"
    Parameters = @{
      ArtifactName = 'LegacyStageArtifact'
      RelativePathToTerraformFiles = 'infra'
    }
    ExpectedYaml = @(
      "displayName: Build 'LegacyStageArtifact' Terraform",
      'value: $(RepositoryDirectory)/infra',
      "'ArtifactName' is deprecated.",
      "'RelativePathToTerraformFiles' is deprecated."
    )
  }
)

$invalidTestCases = @(
  @{
    Description = "with a field set both in TerraformBuildConfig and as a deprecated parameter"
    Parameters = @{
      RelativePathToTerraformFiles = 'old'
      TerraformBuildConfig = "RelativePathToTerraformFiles: new"
    }
    ErrorMessage = "use either 'RelativePathToTerraformFiles' (deprecated) or 'TerraformBuildConfig.RelativePathToTerraformFiles', not both."
  }
)

# ============================================================================
# RUN TESTS
# ============================================================================

Run-Tests `
  -YamlPath "stages/terraform_build.yml" `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases
