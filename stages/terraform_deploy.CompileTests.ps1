$repoRoot = git rev-parse --show-toplevel
. (Join-Path $repoRoot "tests" "framework" "Core.ps1")

# Branch coverage (stages/terraform_deploy.yml):
#   if Stage.DependsOn missing or empty  -> "missing Stage.DependsOn" (entered), "with a complete EnvironmentConfig" (not entered)
#   if Stage.Condition missing or empty  -> "missing Stage.Condition" (entered), "with a complete EnvironmentConfig" (not entered)
# Validation of TerraformDeploymentConfig belongs to schemas/terraform_gated_deployment_config.yml.

function New-EnvironmentConfig
{
  param(
    [object]$DependsOn = @("Build_Terraform"),
    [string]$Condition = "succeeded('Build_Terraform')"
  )
  $stage = @{ }
  if ($null -ne $DependsOn) { $stage.DependsOn = $DependsOn }
  if ($null -ne $Condition) { $stage.Condition = $Condition }
  return @{
    Name = "dev"
    Stage = $stage
    TerraformDeploymentConfig = @{
      AzDOEnvironmentName = "compile-tests-only"
      RunMode = "PlanOnly"
    }
  }
}

$validTestCases = @(
  @{
    Description = "with a complete EnvironmentConfig"
    Parameters = @{
      EnvironmentConfig = (New-EnvironmentConfig)
    }
    ExpectedYaml = @(
      "- stage: Deploy_dev_Terraform"
      "displayName: Deploy dev Terraform"
      "dependsOn:*Build_Terraform"
      "condition: succeeded('Build_Terraform')"
      "inputs:*TerraformVersion:* 1.14.0"
    )
  },
  @{
    Description = "TerraformVersion and TerraformArtifactName are passed through to the deployment jobs"
    Parameters = @{
      TerraformVersion = "1.6.0"
      TerraformArtifactName = "InfraArtifact"
      EnvironmentConfig = (New-EnvironmentConfig)
    }
    ExpectedYaml = @(
      "inputs:*TerraformVersion:* 1.6.0"
      "InfraArtifact"
    )
  }
)

$invalidTestCases = @(
  @{
    Description = "missing EnvironmentConfig parameter"
    Parameters = @{ }
    ErrorMessage = "A value for the 'EnvironmentConfig' parameter must be provided."
  },
  @{
    Description = "missing Stage.DependsOn"
    Parameters = @{
      EnvironmentConfig = (New-EnvironmentConfig -DependsOn $null)
    }
    ErrorMessage = "environment 'dev' DependsOn is not properly defined and is a required field."
  },
  @{
    Description = "missing Stage.Condition"
    Parameters = @{
      EnvironmentConfig = (New-EnvironmentConfig -Condition $null)
    }
    ErrorMessage = "environment 'dev' Condition is not properly defined and is a required field."
  },
  @{
    Description = "deployment schema is applied to TerraformDeploymentConfig"
    Parameters = @{
      EnvironmentConfig = @{
        Name = "dev"
        Stage = @{
          DependsOn = @("Build_Terraform")
          Condition = "succeeded('Build_Terraform')"
        }
        TerraformDeploymentConfig = @{
          AzDOEnvironmentName = "compile-tests-only"
        }
      }
    }
    ErrorMessage = "'dev' environment error: RunMode is not properly defined and is a required field."
  }
)

# The deployment jobs check out the AzDOPipelineTemplates repository, so the resource is declared
# the same way consumers declare it (see tests/pipelines/terraform_pipeline/*_test.yml).
# A Build_Terraform stage is appended so that Stage.DependsOn refers to an existing stage.
Run-Tests `
  -YamlPath "stages/terraform_deploy.yml" `
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

"@ + $yaml + @"

  - stage: Build_Terraform
    dependsOn: []
    jobs:
      - job: Build
        steps:
          - script: echo build
"@
  } `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases
