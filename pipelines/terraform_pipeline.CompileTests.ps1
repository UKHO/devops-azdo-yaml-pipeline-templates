# ============================================================================
# TEST: Terraform Pipeline Template (build stage)
# ============================================================================
# Tests for how pipelines/terraform_pipeline.yml builds the Terraform artifact: TerraformBuildConfig
# (including Checks) is passed to the build, the pipeline's shared TerraformVersion is added to it, and
# the deprecated top-level build parameters still work. Deploy stages are covered by their own tests and
# the end-to-end pipelines in tests/pipelines/terraform_pipeline/.

# Load framework (only if not already loaded)
if (-not (Get-Command -Name 'Run-Tests' -ErrorAction SilentlyContinue))
{
  $repoRoot = git rev-parse --show-toplevel 2> $null
  . (Join-Path $repoRoot "tests" "framework" "Core.ps1")
}

# ============================================================================
# DEFINE TEST CASES
# ============================================================================

# A minimal plan-only environment, so the pipeline compiles.
$environmentConfigs = @"
- Name: dev
  Stage:
    DependsOn:
      - build_terraform
    Condition: succeeded('build_terraform')
  TerraformDeploymentConfig:
    AzureServiceConnection: DevOps Chapter Dev
    AzDOEnvironmentName: Discovery
    RunMode: PlanOnly
"@

$validTestCases = @(
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

# The deploy stages check out the 'AzDOPipelineTemplates' repository, so declare it as a resource, the
# same way the end-to-end pipelines in tests/pipelines/terraform_pipeline/ do.
$resources = @"
resources:
  repositories:
    - repository: AzDOPipelineTemplates
      type: github
      endpoint: UKHO
      name: UKHO/devops-azdo-yaml-pipeline-templates

"@

Run-Tests `
  -YamlPath "pipelines/terraform_pipeline.yml" `
  -TransformYamlFunction { param($yaml) return $resources + $yaml } `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases
