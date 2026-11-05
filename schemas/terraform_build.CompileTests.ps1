# ============================================================================
# TEST: Terraform Build Schema
# ============================================================================
# Validation tests for the Checks list accepted by jobs/terraform_build.yml.
# Only the list shape and each entry's 'Check' and 'Name' are validated here; each check's own
# settings are tested by its check template (for example checks/terraformformat.CompileTests.ps1).

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
    Description = "with a single TerraformFormat entry"
    Parameters = @{
      Checks = @"
 - Check: TerraformFormat
"@
    }
  },
  @{
    Description = "with a TerraformFormat entry and its settings"
    Parameters = @{
      Checks = @"
 - Check: TerraformFormat
   Name: Modules
   Recursive: false
   TreatAsWarnings: true
"@
    }
  },
  @{
    Description = "with TerraformFormat listed twice with different Names"
    Parameters = @{
      Checks = @"
 - Check: TerraformFormat
   Name: Root
 - Check: TerraformFormat
   Name: Modules
"@
    }
  }
)

$invalidTestCases = @(
  @{
    Description = "with a string instead of a list"
    Parameters = @{
      Checks = "TerraformFormat"
    }
    ErrorMessage = "Invalid Checks: must be a list of check objects"
  },
  @{
    Description = "with an entry that is a string, not an object"
    Parameters = @{
      Checks = @"
 - TerraformFormat
"@
    }
    ErrorMessage = "Invalid Checks: each entry must be an object with a 'Check' field"
  },
  @{
    Description = "with an entry missing the Check field"
    Parameters = @{
      Checks = @"
 - Name: Modules
"@
    }
    ErrorMessage = "Invalid Checks: entry is missing required string field 'Check'."
  },
  @{
    Description = "with an empty Check field"
    Parameters = @{
      Checks = @"
 - Check: ''
"@
    }
    ErrorMessage = "Invalid Checks: entry is missing required string field 'Check'."
  },
  @{
    Description = "with a Check field that is a list"
    Parameters = @{
      Checks = @"
 - Check:
     - TerraformFormat
"@
    }
    ErrorMessage = "Invalid Checks: entry is missing required string field 'Check'."
  },
  @{
    Description = "with an unsupported check"
    Parameters = @{
      Checks = @"
 - Check: TFLint
"@
    }
    ErrorMessage = "Invalid Checks: 'TFLint' is not a supported check for terraform_build. Supported: TerraformFormat."
  },
  @{
    Description = "with a path-like Check value"
    Parameters = @{
      Checks = @"
 - Check: ../tasks/terraform
"@
    }
    ErrorMessage = "Invalid Checks: '../tasks/terraform' is not a supported check for terraform_build."
  },
  @{
    Description = "with an empty Name"
    Parameters = @{
      Checks = @"
 - Check: TerraformFormat
   Name: ''
"@
    }
    ErrorMessage = "Invalid Checks: 'Name' must be a non-empty string when provided."
  },
  @{
    Description = "with TerraformFormat listed twice and one Name missing"
    Parameters = @{
      Checks = @"
 - Check: TerraformFormat
 - Check: TerraformFormat
   Name: Modules
"@
    }
    ErrorMessage = "Invalid Checks: 'TerraformFormat' is listed more than once, so every 'TerraformFormat' entry needs a unique 'Name'."
  },
  @{
    Description = "with TerraformFormat listed twice with different settings and no Names"
    Parameters = @{
      Checks = @"
 - Check: TerraformFormat
 - Check: TerraformFormat
   Recursive: false
"@
    }
    ErrorMessage = "Invalid Checks: 'TerraformFormat' is listed more than once, so every 'TerraformFormat' entry needs a unique 'Name'."
  }
)

# ============================================================================
# RUN TESTS
# ============================================================================

Run-Tests `
  -YamlPath "schemas/terraform_build.yml" `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases
