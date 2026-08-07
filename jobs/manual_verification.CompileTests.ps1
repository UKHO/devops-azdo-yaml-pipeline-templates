# ============================================================================
# TEST: Manual Verification Job Template
# ============================================================================

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
    Description = "with default parameters"
    Parameters = @{
      JobName = "ManualVerification"
      Condition = "succeeded()"
      TimeoutInMinutes = 60
      Instructions = '""'
    }
    ExpectedYaml = @(
      'job: ManualVerification',
      'displayName: ''Manual Verification''',
      'condition: succeeded()',
      'pool:*name: server'
    )
  },
  @{
    Description = "with custom job name"
    Parameters = @{
      JobName = "CustomVerification"
      Condition = "succeeded()"
      TimeoutInMinutes = 60
    }
    ExpectedYaml = @(
      'job: CustomVerification',
      'displayName: ''Manual Verification'''
    )
  },
  @{
    Description = "with custom timeout"
    Parameters = @{
      JobName = "ManualVerification"
      Condition = "succeeded()"
      TimeoutInMinutes = 120
      Instructions = "Please verify the deployment"
    }
    ExpectedYaml = @(
      'timeoutInMinutes: 120',
      'instructions:*Please verify the deployment'
    )
  },
  @{
    Description = "with custom timeout behaviour"
    Parameters = @{
      JobName = "ManualVerification"
      Condition = "succeeded()"
      OnTimeoutBehaviour = "resume"
      TimeoutInMinutes = 120
      Instructions = "Please verify the deployment"
    }
    ExpectedYaml = @(
      'timeoutInMinutes: 120',
      'instructions:*Please verify the deployment'
      'onTimeout: resume'
    )
  },
  @{
    Description = "with custom condition"
    Parameters = @{
      JobName = "ManualVerification"
      Condition = "and(succeeded(), eq('refs/heads/main', 'refs/heads/main'))"
      TimeoutInMinutes = 60
    }
    ExpectedYaml = @(
      "condition: and(succeeded(), eq('refs/heads/main', 'refs/heads/main'))"
    )
  }
)

# Invalid test cases
$invalidTestCases = @(
  @{
    Description = "with missing JobName parameter"
    Parameters = @{
      Condition = "succeeded()"
      TimeoutInMinutes = 60
      JobName = '""'
    }
    ErrorMessage = "Job `"`" has an invalid name. Valid names may only contain alphanumeric characters and '_' and may not start with a number."
  }
)

# ============================================================================
# RUN TESTS
# ============================================================================

Run-Tests `
  -YamlPath "jobs/manual_verification.yml" `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases
