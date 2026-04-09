# ============================================================================
# TEST: Terraform Build Job Template
# ============================================================================
# This test verifies the terraform_build job template with different parameter combinations.
#
# NOTE: Job templates that reference other templates (tasks, jobs, steps) may experience
# resolution issues during testing. These test cases focus on parameter validation.
# Full integration testing requires the pipeline to be run in Azure DevOps.

# Load framework (only if not already loaded)
if (-not (Get-Command -Name 'Run-Tests' -ErrorAction SilentlyContinue))
{
  $repoRoot = git rev-parse --show-toplevel 2> $null
  . (Join-Path $repoRoot "tests" "framework" "Core.ps1")
}

# ============================================================================
# DEFINE TEST CASES
# ============================================================================
# These test cases validate parameter combinations and their correct passage to the template.
# Each test case documents a realistic usage scenario.

$validTestCases = @(
  @{
    Description = "with default parameters"
    Parameters = @{
    }
    ExpectedYaml = @(
      'job: TerraformBuild',
      'displayName:*Terraform Build',
      'terraformVersion:*1.14.0',
      'artifact:*TerraformArtifact'
    )
  },
  @{
    Description = "expected terraform commands"
    Parameters = @{
    }
    ExpectedYaml = @(
      'terraform init -backend=false',
      'terraform validate'
    )
  },
  @{
    Description = "with custom artifact name"
    Parameters = @{
      ArtifactName = 'CustomTerraformArtifact'
    }
    ExpectedYaml = @(
      'artifact:*CustomTerraformArtifact'
    )
  },
  @{
    Description = "with custom terraform version"
    Parameters = @{
      TerraformVersion = '1.15.0'
    }
    ExpectedYaml = @(
      'terraformVersion:*1.15.0'
    )
  },
  @{
    Description = "with latest terraform version"
    Parameters = @{
      TerraformVersion = 'latest'
    }
    ExpectedYaml = @(
      'terraformVersion:*latest'
    )
  },
  @{
    Description = "with relative path to terraform files"
    Parameters = @{
      RelativePathToTerraformFiles = 'terraform/production'
    }
    ExpectedYaml = @(
      'value: $(RepositoryDirectory)/terraform/production'
    )
  },
  @{
    Description = "with custom artifact name and latest terraform"
    Parameters = @{
      ArtifactName = 'LatestTerraformArtifact'
      TerraformVersion = 'latest'
    }
    ExpectedYaml = @(
      'artifact:*LatestTerraformArtifact',
      'terraformVersion:*latest'
    )
  }
)

$invalidTestCases = @(
  @{
    Description = "with invalid terraform version format"
    Parameters = @{
      TerraformVersion = '1.0.x'
    }
    ErrorMessage = "terraform_installer' task error: TerraformVersion is not properly defined. Must either be 'latest' or an exact numeric semantic version 'x.y.z' (digits only). Wildcards, comparators, and other non-semver formats are not allowed."
  }
)

# ============================================================================
# RUN TESTS
# ============================================================================

Run-Tests `
  -YamlPath "jobs/terraform_build.yml" `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases
