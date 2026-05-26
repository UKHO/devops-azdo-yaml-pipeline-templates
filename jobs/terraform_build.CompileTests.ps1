# ============================================================================
# TEST: Terraform Build Job Template
# ============================================================================
# This test verifies the terraform_build job template with different parameter combinations.
#
# Tests cover:
# - Artifact naming and configuration
# - Terraform version specification and validation
# - Repository checkout paths and working directories
# - Build injection steps (custom pre-build steps)
# - Additional files packaging (copying extra resources into artifact)
# - Combined scenarios with multiple parameters
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
        Description = "with default parameters (no injection steps, no additional files)"
        Parameters = @{
        }
        ExpectedYaml = @(
            'job: TerraformBuild_TerraformArtifact',
            "displayName:*Build 'TerraformArtifact' Terraform Artifact",
            'artifact:*TerraformArtifact',
            'inputs:*TerraformVersion:**1.14.0'
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
            'job: TerraformBuild_CustomTerraformArtifact',
            "displayName:*Build 'CustomTerraformArtifact' Terraform Artifact",
            'artifact:*CustomTerraformArtifact'
        )
    },
    @{
        Description = "with custom terraform version"
        Parameters = @{
            TerraformVersion = '1.15.0'
        }
        ExpectedYaml = @(
            'inputs:*TerraformVersion:**1.15.0'
        )
    },
    @{
        Description = "with latest terraform version"
        Parameters = @{
            TerraformVersion = 'latest'
        }
        ExpectedYaml = @(
            'inputs:*TerraformVersion:**latest'
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
            'inputs:*TerraformVersion:**latest'
        )
    },
    @{
        Description = "with single TerraformBuildInjectionStep"
        Parameters = @{
            TerraformBuildInjectionSteps = @"
- script: echo "Pre-build step"
  displayName: Run pre-build validation
"@
        }
        ExpectedYaml = @('CmdLine@2', 'Run pre-build validation', 'echo "Pre-build step"')
    },
    @{
        Description = "with multiple TerraformBuildInjectionSteps"
        Parameters = @{
            TerraformBuildInjectionSteps = @"
- script: echo "Step 1"
  displayName: Pre-build step 1
- script: echo "Step 2"
  displayName: Pre-build step 2
"@
        }
        ExpectedYaml = @('CmdLine@2', 'Pre-build step 1', 'Pre-build step 2', 'echo "Step 1"', 'echo "Step 2"')
    },
    @{
        Description = "with single AdditionalFileToPackage"
        Parameters = @{
            AdditionalFilesToPackage = @"
- FilesPattern: '**'
  SourceDirectory: resources/keyvault
  TargetSubdirectoryName: keyvault
"@
        }
        ExpectedYaml = @('CopyFiles@2', 'resources/keyvault', 'keyvault')
    },
    @{
        Description = "with multiple AdditionalFilesToPackage"
        Parameters = @{
            AdditionalFilesToPackage = @"
- FilesPattern: '**'
  SourceDirectory: resources/keyvault
  TargetSubdirectoryName: newresourcedirectoryone
- FilesPattern: '**'
  SourceDirectory: resources/storageaccount
  TargetSubdirectoryName: newresourcedirectorytwo
"@
        }
        ExpectedYaml = @('CopyFiles@2', 'resources/keyvault', 'resources/storageaccount', 'newresourcedirectoryone', 'newresourcedirectorytwo')
    },
    @{
        Description = "with both TerraformBuildInjectionSteps and AdditionalFilesToPackage"
        Parameters = @{
            TerraformBuildInjectionSteps = @"
- script: echo "Validating configuration"
  displayName: Validate configuration
"@
            AdditionalFilesToPackage = @"
- FilesPattern: '**'
  SourceDirectory: scripts
  TargetSubdirectoryName: terraform_scripts
"@
        }
        ExpectedYaml = @('CmdLine@2', 'Validate configuration', 'CopyFiles@2', 'scripts', 'terraform_scripts')
    }
)

$invalidTestCases = @(
    @{
        Description = "with invalid terraform version format"
        Parameters = @{
            TerraformVersion = '1.0.x'
        }
        ErrorMessage = "terraform_installer' task error: TerraformVersion is not properly defined. Must either be 'latest' or an exact numeric semantic version 'x.y.z' (digits only). Wildcards, comparators, and other non-semver formats are not allowed."
    },
    @{
        Description = "with invalid AdditionalFilesToPackage parameter"
        Parameters = @{
            AdditionalFilesToPackage = "junk"
        }
        ErrorMessage = "Expected a sequence or mapping. Actual value 'junk'"
    },
    @{
        Description = "with invalid TerraformBuildInjectionSteps parameter"
        Parameters = @{
            TerraformBuildInjectionSteps = "junk"
        }
        ErrorMessage = "The 'TerraformBuildInjectionSteps' parameter is not a valid StepList."
    }
)

# ============================================================================
# RUN TESTS
# ============================================================================

Run-Tests `
  -YamlPath "jobs/terraform_build.yml" `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases
