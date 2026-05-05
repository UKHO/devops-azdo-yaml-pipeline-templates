# ============================================================================
# TEST: Terraform Repository Checkout Steps List Template
# ============================================================================
# Tests for the terraform_build_checkout_steps.yml template which checks out
# the repository and optionally injects custom build steps and packages additional files.

# Load framework (only if not already loaded)
if (-not (Get-Command -Name 'Run-Tests' -ErrorAction SilentlyContinue))
{
    $repoRoot = git rev-parse --show-toplevel 2> $null
    . (Join-Path $repoRoot "tests" "framework" "Core.ps1")
}

# ============================================================================
# DEFINE TEST CASES
# ============================================================================

# Valid test cases with different parameter combinations
$validTestCases = @(
    @{
        Description = "with default parameters (no injection steps, no additional files)"
        ExpectedYaml = @('task: 6d15af64-176c-496d-b583-fd2ae21d4df4', 'Checkout self repository', 'clean: true', 'path: $(RepositoryCheckoutFolderName)')
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

# Invalid test cases
$invalidTestCases = @(
    @{
        Description = "Invalid AdditionalFilesToPackage parameter"
        Parameters = @{
            AdditionalFilesToPackage = "junk"
        }
        ErrorMessage = "Expected a sequence or mapping. Actual value 'junk'"
    },
    @{
        Description = "Invalid TerraformBuildInjectionSteps parameter"
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
  -YamlPath "jobs/terraform_build_checkout_steps.yml" `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases
