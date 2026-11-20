$repoRoot = git rev-parse --show-toplevel
. (Join-Path $repoRoot "tests" "framework" "Core.ps1")

# Branch coverage (stages/terraform_build.yml): no conditional branches.
# The stage only passes its parameters through to jobs/terraform_build.yml, which has its own tests.

$validTestCases = @(
  @{
    Description = "with default parameters"
    Parameters = @{ }
    ExpectedYaml = @(
      "- stage: Build_Terraform"
      "displayName: Build 'TerraformArtifact' Terraform"
      "inputs:*TerraformVersion:* 1.14.0"
    )
  },
  @{
    Description = "parameters are passed through to the build job"
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
      "displayName: Build 'InfraArtifact' Terraform"
      "inputs:*TerraformVersion:* 1.6.0"
      "infra/terraform"
      "echo injected-step"
      "artifact: InfraArtifact"
    )
  }
)

$invalidTestCases = @(
  @{
    Description = "TerraformBuildInjectionSteps is not a step list"
    Parameters = @{
      TerraformBuildInjectionSteps = "- notAStep: value"
    }
    ErrorMessage = "TerraformBuildInjectionSteps"
  }
)

Run-Tests `
  -YamlPath "stages/terraform_build.yml" `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases
