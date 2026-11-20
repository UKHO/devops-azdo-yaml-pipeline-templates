# ============================================================================
# TEST: Terraform Pipeline Template
# ============================================================================
# Tests for pipelines/terraform_pipeline.yml: the environment loop, and how the pipeline builds the
# Terraform artifact. TerraformBuildConfig (including Checks) is passed to the build, the pipeline's
# shared TerraformVersion is added to it, and the deprecated top-level build parameters still work.
#
# Branch coverage (pipelines/terraform_pipeline.yml):
#   each EnvironmentConfigs          -> "with one environment", "with two environments, in order"
#   if environmentConfig.Name empty  -> "environment without a Name" (entered), "with one environment" (not entered)
# Stage-level behaviour is tested in stages/terraform_build.CompileTests.ps1 and stages/terraform_deploy.CompileTests.ps1.
#
# EnvironmentConfigs is passed as YAML text. Passed as JSON, the 'each' loop hands each entry on as a
# value that cannot be converted back into a template token.

# Load framework (only if not already loaded)
if (-not (Get-Command -Name 'Run-Tests' -ErrorAction SilentlyContinue))
{
  $repoRoot = git rev-parse --show-toplevel 2> $null
  . (Join-Path $repoRoot "tests" "framework" "Core.ps1")
}

# ============================================================================
# DEFINE TEST CASES
# ============================================================================

function New-EnvironmentConfigYaml
{
  param(
    [string]$Name,
    [string]$DependsOn = "Build_Terraform"
  )
  $nameLine = if ($Name) { "- Name: $Name`n  " } else { "- " }
  return @"
${nameLine}Stage:
    DependsOn:
      - $DependsOn
    Condition: succeeded('$DependsOn')
  TerraformDeploymentConfig:
    AzDOEnvironmentName: compile-tests-only
    RunMode: PlanOnly
"@
}

# A minimal plan-only environment, so the pipeline compiles.
$environmentConfigs = New-EnvironmentConfigYaml -Name "dev"

$validTestCases = @(
  # --- Environments --------------------------------------------------------
  @{
    Description = "with one environment"
    Parameters = @{
      EnvironmentConfigs = $environmentConfigs
    }
    ExpectedYaml = @(
      "- stage: Build_Terraform"
      "- stage: Deploy_dev_Terraform"
    )
  },
  @{
    Description = "with two environments, in order"
    Parameters = @{
      EnvironmentConfigs = (New-EnvironmentConfigYaml -Name "dev") + "`n" + (New-EnvironmentConfigYaml -Name "prod" -DependsOn "Deploy_dev_Terraform")
    }
    ExpectedYaml = @(
      "- stage: Deploy_dev_Terraform*- stage: Deploy_prod_Terraform"
    )
  },
  @{
    Description = "TerraformVersion is passed to the build and deploy stages"
    Parameters = @{
      TerraformVersion = "1.6.0"
      EnvironmentConfigs = $environmentConfigs
    }
    ExpectedYaml = @(
      "- stage: Build_Terraform*TerraformVersion:* 1.6.0*- stage: Deploy_dev_Terraform*TerraformVersion:* 1.6.0"
    )
  },

  # --- Build: TerraformBuildConfig -----------------------------------------
  @{
    Description = "with no build parameters"
    Parameters = @{
      EnvironmentConfigs = $environmentConfigs
    }
    ExpectedYaml = @(
      'job: TerraformBuild_TerraformArtifact',
      'inputs:*TerraformVersion:**1.14.0'
    )
    UnexpectedYaml = @(
      'DeprecatedParametersWarning'
    )
  },
  @{
    Description = "TerraformBuildConfig with Checks, and the shared TerraformVersion added to it"
    Parameters = @{
      EnvironmentConfigs = $environmentConfigs
      TerraformVersion = '1.13.0'
      TerraformBuildConfig = @"
RelativePathToTerraformFiles: infra
Checks:
  - Check: TerraformFormat
"@
    }
    ExpectedYaml = @(
      'value: $(RepositoryDirectory)/infra',
      'name: TerraformTask_fmt',
      'inputs:*TerraformVersion:**1.13.0'
    )
    UnexpectedYaml = @(
      'DeprecatedParametersWarning'
    )
  },
  @{
    Description = "deprecated RelativePathToTerraformFiles still works and logs a warning"
    Parameters = @{
      EnvironmentConfigs = $environmentConfigs
      RelativePathToTerraformFiles = 'infra'
    }
    ExpectedYaml = @(
      'value: $(RepositoryDirectory)/infra',
      "'RelativePathToTerraformFiles' is deprecated."
    )
  }
)

$invalidTestCases = @(
  # --- Environments --------------------------------------------------------
  @{
    Description = "missing EnvironmentConfigs parameter"
    Parameters = @{ }
    ErrorMessage = "A value for the 'EnvironmentConfigs' parameter must be provided."
  },
  @{
    Description = "environment without a Name"
    Parameters = @{
      EnvironmentConfigs = (New-EnvironmentConfigYaml)
    }
    ErrorMessage = "an environment name is not properly defined and is a required field."
  },

  # --- Build: TerraformBuildConfig -----------------------------------------
  @{
    Description = "with TerraformVersion inside TerraformBuildConfig"
    Parameters = @{
      EnvironmentConfigs = $environmentConfigs
      TerraformBuildConfig = "TerraformVersion: 1.13.0"
    }
    ErrorMessage = "Invalid TerraformBuildConfig: 'TerraformVersion' is not supported by terraform_pipeline."
  },
  @{
    Description = "with ArtifactName inside TerraformBuildConfig"
    Parameters = @{
      EnvironmentConfigs = $environmentConfigs
      TerraformBuildConfig = "ArtifactName: Other"
    }
    ErrorMessage = "Invalid TerraformBuildConfig: 'ArtifactName' is not supported by terraform_pipeline"
  },
  @{
    Description = "with a field set both in TerraformBuildConfig and as a deprecated parameter"
    Parameters = @{
      EnvironmentConfigs = $environmentConfigs
      RelativePathToTerraformFiles = 'old'
      TerraformBuildConfig = "RelativePathToTerraformFiles: new"
    }
    ErrorMessage = "use either 'RelativePathToTerraformFiles' (deprecated) or 'TerraformBuildConfig.RelativePathToTerraformFiles', not both."
  }
)

# ============================================================================
# RUN TESTS
# ============================================================================

# The deployment jobs check out the AzDOPipelineTemplates repository, so the resource is declared
# the same way consumers declare it (see tests/pipelines/terraform_pipeline/*_test.yml).
Run-Tests `
  -YamlPath "pipelines/terraform_pipeline.yml" `
  -TransformYamlFunction {
    param($yaml)
    return @"
resources:
  repositories:
    - repository: AzDOPipelineTemplates
      type: github
      endpoint: UKHO
      name: UKHO/devops-azdo-yaml-pipeline-templates
      ref: `${{ variables['Build.SourceBranch'] }}

"@ + $yaml
  } `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases
