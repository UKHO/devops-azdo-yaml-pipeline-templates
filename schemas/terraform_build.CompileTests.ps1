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

$seeDocs = "See: docs/user-docs/checks/README.md"

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
  },
  @{
    Description = "with one Name that starts with another (Root and Root_All)"
    Parameters = @{
      Checks = @"
 - Check: TerraformFormat
   Name: Root
 - Check: TerraformFormat
   Name: Root_All
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
    ErrorMessage = "Invalid Checks: must be a list of check objects, for example '- Check: TerraformFormat'. $seeDocs"
  },
  @{
    Description = "with an entry that is a string, not an object"
    Parameters = @{
      Checks = @"
 - TerraformFormat
"@
    }
    ErrorMessage = "Invalid Checks: each entry must be an object with a 'Check' field, for example '- Check: TerraformFormat'. $seeDocs"
  },
  @{
    Description = "with an entry missing the Check field"
    Parameters = @{
      Checks = @"
 - Name: Modules
"@
    }
    ErrorMessage = "Invalid Checks: entry is missing required field 'Check'. Supported: TerraformFormat. $seeDocs"
  },
  @{
    Description = "with an empty Check field"
    Parameters = @{
      Checks = @"
 - Check: ''
"@
    }
    ErrorMessage = "Invalid Checks: entry is missing required field 'Check'. Supported: TerraformFormat. $seeDocs"
  },
  @{
    Description = "with a Check field that is a list"
    Parameters = @{
      Checks = @"
 - Check:
     - TerraformFormat
"@
    }
    ErrorMessage = "Invalid Checks: 'Check' must be a string. Supported: TerraformFormat. $seeDocs"
  },
  @{
    Description = "with a Check field that is an object"
    Parameters = @{
      Checks = @"
 - Check:
     Name: TerraformFormat
"@
    }
    ErrorMessage = "Invalid Checks: 'Check' must be a string. Supported: TerraformFormat. $seeDocs"
  },
  @{
    Description = "with an unsupported check"
    Parameters = @{
      Checks = @"
 - Check: TFLint
"@
    }
    ErrorMessage = "Invalid Checks: 'TFLint' is not a supported check for terraform_build. Supported: TerraformFormat. $seeDocs"
  },
  @{
    Description = "with a path-like Check value"
    Parameters = @{
      Checks = @"
 - Check: ../tasks/terraform
"@
    }
    ErrorMessage = "Invalid Checks: '../tasks/terraform' is not a supported check for terraform_build. Supported: TerraformFormat. $seeDocs"
  },
  @{
    Description = "with an empty Name"
    Parameters = @{
      Checks = @"
 - Check: TerraformFormat
   Name: ''
"@
    }
    ErrorMessage = "Invalid Checks: 'Name' must be a non-empty string when provided. $seeDocs"
  },
  @{
    Description = "with a Name that is a list"
    Parameters = @{
      Checks = @"
 - Check: TerraformFormat
   Name:
     - Root
"@
    }
    ErrorMessage = "Invalid Checks: 'Name' must be a string. $seeDocs"
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
    ErrorMessage = "Invalid Checks: 'TerraformFormat' is listed more than once, so every 'TerraformFormat' entry needs a unique 'Name'. $seeDocs"
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
    ErrorMessage = "Invalid Checks: 'TerraformFormat' is listed more than once, so every 'TerraformFormat' entry needs a unique 'Name'. $seeDocs"
  },
  @{
    Description = "with two identical unnamed TerraformFormat entries"
    Parameters = @{
      Checks = @"
 - Check: TerraformFormat
 - Check: TerraformFormat
"@
    }
    ErrorMessage = "Invalid Checks: 'TerraformFormat' is listed more than once, so every 'TerraformFormat' entry needs a unique 'Name'. $seeDocs"
  },
  @{
    Description = "with two unnamed entries whose Check differs only in case"
    Parameters = @{
      Checks = @"
 - Check: TerraformFormat
 - Check: terraformformat
"@
    }
    ErrorMessage = "Invalid Checks: 'TerraformFormat' is listed more than once, so every 'TerraformFormat' entry needs a unique 'Name'. $seeDocs"
  },
  @{
    Description = "with two entries using the same Name"
    Parameters = @{
      Checks = @"
 - Check: TerraformFormat
   Name: Root
 - Check: TerraformFormat
   Name: Root
   Recursive: false
"@
    }
    ErrorMessage = "Invalid Checks: the Name 'Root' is used by more than one entry. Each 'Name' must be unique. $seeDocs"
  },
  @{
    Description = "with two entries whose Names differ only in case"
    Parameters = @{
      Checks = @"
 - Check: TerraformFormat
   Name: Root
 - Check: TerraformFormat
   Name: ROOT
"@
    }
    ErrorMessage = "Invalid Checks: the Name 'Root' is used by more than one entry. Each 'Name' must be unique. $seeDocs"
  }
)

# ============================================================================
# RUN TESTS
# ============================================================================

Run-Tests `
  -YamlPath "schemas/terraform_build.yml" `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases
