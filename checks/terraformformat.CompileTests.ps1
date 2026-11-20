# ============================================================================
# TEST: TerraformFormat Check Template
# ============================================================================
# Tests for checks/terraformformat.yml, which runs 'terraform fmt -check -diff' through
# /tasks/terraform.yml. Covers the defaults, each setting (Recursive, Name, TreatAsWarnings),
# and that bad input is rejected: missing or empty WorkingDirectory, wrong types, and unknown
# settings (which is how a consumer's misspelled setting shows up when forwarded from Checks).

# Load framework (only if not already loaded)
if (-not (Get-Command -Name 'Run-Tests' -ErrorAction SilentlyContinue))
{
  $repoRoot = git rev-parse --show-toplevel 2> $null
  . (Join-Path $repoRoot "tests" "framework" "Core.ps1")
}

# ============================================================================
# DEFINE TEST CASES
# ============================================================================

$workingDirectory = '$(Pipeline.Workspace)/infra'

# Valid test cases
$validTestCases = @(
  @{
    Description = "with defaults (recursive, fails the job on unformatted files)"
    Parameters = @{
      WorkingDirectory = $workingDirectory
    }
    ExpectedYaml = @(
      'terraform fmt -check -diff -recursive'
      'name: TerraformTask_fmt'
      "workingDirectory: $workingDirectory"
      'displayName: Terraform fmt'
    )
  },
  @{
    Description = "with Recursive false"
    Parameters = @{
      WorkingDirectory = $workingDirectory
      Recursive = $false
    }
    ExpectedYaml = @(
      'terraform fmt -check -diff'
    )
  },
  @{
    Description = "with a Name, which makes the step name unique"
    Parameters = @{
      WorkingDirectory = $workingDirectory
      Name = "Modules"
    }
    ExpectedYaml = @(
      'name: TerraformTask_fmt_Modules'
    )
  },
  @{
    Description = "with TreatAsWarnings true, which sets continueOnError"
    Parameters = @{
      WorkingDirectory = $workingDirectory
      TreatAsWarnings = $true
    }
    ExpectedYaml = @(
      'terraform fmt -check -diff -recursive'
      'continueOnError: true'
    )
  },
  @{
    Description = "with every setting"
    Parameters = @{
      WorkingDirectory = $workingDirectory
      Name = "Root_Only"
      Recursive = $false
      TreatAsWarnings = $true
    }
    ExpectedYaml = @(
      'terraform fmt -check -diff'
      'name: TerraformTask_fmt_Root_Only'
      "workingDirectory: $workingDirectory"
      'displayName: Terraform fmt'
      'continueOnError: true'
    )
  }
)

# Invalid test cases
$invalidTestCases = @(
  @{
    Description = "missing WorkingDirectory parameter"
    Parameters = @{ }
    ErrorMessage = "A value for the 'WorkingDirectory' parameter must be provided."
  },
  @{
    Description = "with an empty WorkingDirectory"
    Parameters = @{
      WorkingDirectory = ""
    }
    ErrorMessage = "The 'WorkingDirectory' parameter is not a valid String."
  },
  @{
    Description = "with a misspelled setting (Recursiv)"
    Parameters = @{
      WorkingDirectory = $workingDirectory
      Recursiv = $false
    }
    ErrorMessage = "Unexpected parameter 'Recursiv'"
  },
  @{
    Description = "with a non-boolean TreatAsWarnings"
    Parameters = @{
      WorkingDirectory = $workingDirectory
      TreatAsWarnings = "sometimes"
    }
    ErrorMessage = "The 'TreatAsWarnings' parameter value 'sometimes' is not a valid Boolean."
  },
  @{
    Description = "with a non-boolean Recursive"
    Parameters = @{
      WorkingDirectory = $workingDirectory
      Recursive = "yes please"
    }
    ErrorMessage = "The 'Recursive' parameter value 'yes please' is not a valid Boolean."
  },
  @{
    Description = "with a Name containing a space (invalid step name)"
    Parameters = @{
      WorkingDirectory = $workingDirectory
      Name = "My Modules"
    }
    ErrorMessage = "Step TerraformTask_fmt_My Modules has an invalid name. Valid names may only contain alphanumeric characters and '_' and may not start with a number."
  }
)

# ============================================================================
# RUN TESTS
# ============================================================================

Run-Tests `
  -YamlPath "checks/terraformformat.yml" `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases
