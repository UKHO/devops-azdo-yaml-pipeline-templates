# ============================================================================
# TEST: Terraform Installer Task Template
# ============================================================================
# Tests for the terraform_installer.yml template which installs Terraform CLI.
# Validates that TerraformVersion parameter accepts 'latest' or strict semantic versions only.

# Load framework (only if not already loaded)
if (-not (Get-Command -Name 'Run-Tests' -ErrorAction SilentlyContinue))
{
  $repoRoot = git rev-parse --show-toplevel 2> $null
  . (Join-Path $repoRoot "tests" "framework" "Core.ps1")
}

# ============================================================================
# DEFINE TEST CASES
# ============================================================================

# Valid test cases: TerraformVersion parameter accepts 'latest' or strict semantic versions
$validTestCases = @(
  @{
    Description = "with default version (1.14.0)"
    Parameters = @{
      TerraformVersion = "1.14.0"
    }
    ExpectedYaml = @('TerraformInstall', 'terraformVersion: 1.14.0')
  },
  @{
    Description = "with 'latest' version"
    Parameters = @{
      TerraformVersion = "latest"
    }
    ExpectedYaml = @('TerraformInstall', 'terraformVersion: latest')
  },
  @{
    Description = "with semantic version 1.3.5"
    Parameters = @{
      TerraformVersion = "1.3.5"
    }
    ExpectedYaml = @('TerraformInstall', 'terraformVersion: 1.3.5')
  },
  @{
    Description = "with semantic version 1.11.3"
    Parameters = @{
      TerraformVersion = "1.11.3"
    }
    ExpectedYaml = @('TerraformInstall', 'terraformVersion: 1.11.3')
  },
  @{
    Description = "with semantic version 0.15.0"
    Parameters = @{
      TerraformVersion = "0.15.0"
    }
    ExpectedYaml = @('TerraformInstall', "terraformVersion: '0.15.0'") # Keep the quoted form because the compiled YAML normalizes this version as a string
  },
  @{
    Description = "with semantic version 2.0.1"
    Parameters = @{
      TerraformVersion = "2.0.1"
    }
    ExpectedYaml = @('TerraformInstall', 'terraformVersion: 2.0.1')
  }

)

# Invalid test cases: TerraformVersion parameter rejects wildcards, comparators, and non-semver formats
$invalidTestCases = @(
  @{
    Description = "with wildcard version 1.11.x"
    Parameters = @{
      TerraformVersion = "1.11.x"
    }
    ErrorMessage = "TerraformVersion is not properly defined. Must either be 'latest' or an exact numeric semantic version"
  },
  @{
    Description = "with wildcard version 1.x.x"
    Parameters = @{
      TerraformVersion = "1.x.x"
    }
    ErrorMessage = "TerraformVersion is not properly defined. Must either be 'latest' or an exact numeric semantic version"
  },
  @{
    Description = "with comparator operator >=1.11.0"
    Parameters = @{
      TerraformVersion = ">=1.11.0"
    }
    ErrorMessage = "TerraformVersion is not properly defined. Must either be 'latest' or an exact numeric semantic version"
  },
  @{
    Description = "with comparator operator ~1.11.0"
    Parameters = @{
      TerraformVersion = "~1.11.0"
    }
    ErrorMessage = "TerraformVersion is not properly defined. Must either be 'latest' or an exact numeric semantic version"
  },
  @{
    Description = "with incomplete semantic version 1.11"
    Parameters = @{
      TerraformVersion = "1.11"
    }
    ErrorMessage = "TerraformVersion is not properly defined. Must either be 'latest' or an exact numeric semantic version"
  },
  @{
    Description = "with too many version parts 1.11.3.0"
    Parameters = @{
      TerraformVersion = "1.11.3.0"
    }
    ErrorMessage = "TerraformVersion is not properly defined. Must either be 'latest' or an exact numeric semantic version"
  },
  @{
    Description = "with non-numeric version string alpha"
    Parameters = @{
      TerraformVersion = "alpha"
    }
    ErrorMessage = "TerraformVersion is not properly defined. Must either be 'latest' or an exact numeric semantic version"
  },
  @{
    Description = "with pre-release version 1.11.0-beta"
    Parameters = @{
      TerraformVersion = "1.11.0-beta"
    }
    ErrorMessage = "TerraformVersion is not properly defined. Must either be 'latest' or an exact numeric semantic version"
  }
)

# ============================================================================
# RUN TESTS
# ============================================================================

Run-Tests `
  -YamlPath "tasks/terraform_installer.yml" `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases
