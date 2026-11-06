# ============================================================================
# TEST: Terraform Build Stage Template
# ============================================================================
# Tests for stages/terraform_build.yml: TerraformBuildConfig and the deprecated parameters are passed
# through to jobs/terraform_build.yml. Field validation is tested by the job and schema tests.
#
# Branch coverage (stages/terraform_build.yml): no conditional branches.
# The stage only passes its parameters through to jobs/terraform_build.yml, which has its own tests.

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
      'job: TerraformBuild_TerraformArtifact',
      'inputs:*TerraformVersion:* 1.14.0'
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
    Description = "deprecated parameters are passed through to the job, which logs a warning"
    Parameters = @{
      ArtifactName = "InfraArtifact"
      RelativePathToTerraformFiles = "infra/terraform"
      TerraformVersion = "1.6.0"
      AdditionalFilesToPackage = @(
        @{
          SourceDirectory = "scripts"
          FilesPattern = "**/*.ps1"
          TargetSubdirectoryName = "scripts"
        }
      )
      # stepList parameters are passed as YAML text; a JSON value is rejected as 'not a valid StepList'
      TerraformBuildInjectionSteps = "- script: echo injected-step"
    }
    ExpectedYaml = @(
      "displayName: Build 'InfraArtifact' Terraform",
      "inputs:*TerraformVersion:* 1.6.0",
      'value: $(RepositoryDirectory)/infra/terraform',
      "echo injected-step",
      "artifact: InfraArtifact",
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
  },
  @{
    Description = "deprecated TerraformBuildInjectionSteps is not a step list"
    Parameters = @{
      TerraformBuildInjectionSteps = "- notAStep: value"
    }
    ErrorMessage = "TerraformBuildInjectionSteps"
  }
)

# ============================================================================
# RUN TESTS
# ============================================================================

Run-Tests `
  -YamlPath "stages/terraform_build.yml" `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases
