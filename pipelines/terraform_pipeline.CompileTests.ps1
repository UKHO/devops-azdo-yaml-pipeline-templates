$repoRoot = git rev-parse --show-toplevel
. (Join-Path $repoRoot "tests" "framework" "Core.ps1")

# Branch coverage (pipelines/terraform_pipeline.yml):
#   each EnvironmentConfigs          -> "with one environment", "with two environments, in order"
#   if environmentConfig.Name empty  -> "environment without a Name" (entered), "with one environment" (not entered)
# Stage-level behaviour is tested in stages/terraform_build.CompileTests.ps1 and stages/terraform_deploy.CompileTests.ps1.
#
# EnvironmentConfigs is passed as YAML text. Passed as JSON, the 'each' loop hands each entry on as a
# value that cannot be converted back into a template token.

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

$validTestCases = @(
  @{
    Description = "with one environment"
    Parameters = @{
      EnvironmentConfigs = (New-EnvironmentConfigYaml -Name "dev")
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
      EnvironmentConfigs = (New-EnvironmentConfigYaml -Name "dev")
    }
    ExpectedYaml = @(
      "- stage: Build_Terraform*TerraformVersion:* 1.6.0*- stage: Deploy_dev_Terraform*TerraformVersion:* 1.6.0"
    )
  }
)

$invalidTestCases = @(
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
  }
)

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
