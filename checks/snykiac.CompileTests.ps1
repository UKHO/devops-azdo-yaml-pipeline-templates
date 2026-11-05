# ============================================================================
# TEST: SnykIac Check Template
# ============================================================================
# Tests for checks/snykiac.yml, which runs a Snyk iac scan through /tasks/snyk_scan.yml.
# Covers the defaults, each setting, and that bad input is rejected (missing required settings,
# wrong types and values, and unknown settings forwarded from Checks).
# Requires the UKHO Snyk extension to be installed in the test Azure DevOps organisation.

# Load framework (only if not already loaded)
if (-not (Get-Command -Name 'Run-Tests' -ErrorAction SilentlyContinue))
{
  $repoRoot = git rev-parse --show-toplevel 2> $null
  . (Join-Path $repoRoot "tests" "framework" "Core.ps1")
}

# ============================================================================
# DEFINE TEST CASES
# ============================================================================

$required = @{
  WorkingDirectory = '$(Pipeline.Workspace)/infra'
  ServiceConnection = 'Snyk'
  Organization = 'my-team'
}

$validTestCases = @(
  @{
    Description = "with only the required settings"
    Parameters = $required.Clone()
    ExpectedYaml = @(
      'task: UkhoSnykScanTask@0'
      'name: SnykScanTask_iac'
      'testType: iac'
      'testDirectory: $(Pipeline.Workspace)/infra'
      'severityThreshold: low'
      'failOnIssues: true'
      'reportFileName: snyk-iac'
    )
  },
  @{
    Description = "with a Name, which makes the step and report names unique"
    Parameters = $required.Clone() + @{ Name = 'Modules' }
    ExpectedYaml = @(
      'name: SnykScanTask_iac_Modules'
      'reportFileName: snyk-iac-Modules'
    )
  },
  @{
    Description = "with TreatAsWarnings true, which sets continueOnError"
    Parameters = $required.Clone() + @{ TreatAsWarnings = $true }
    ExpectedYaml = @(
      'continueOnError: true'
    )
  },
  @{
    Description = "with every setting"
    Parameters = $required.Clone() + @{
      Name = 'HighOnly'
      TreatAsWarnings = $true
      SeverityThreshold = 'high'
      FailOnIssues = $false
      AdditionalArguments = '--report'
    }
    ExpectedYaml = @(
      'name: SnykScanTask_iac_HighOnly'
      'severityThreshold: high'
      'failOnIssues: false'
      'additionalArguments: --report'
      'continueOnError: true'
    )
  }
)

$invalidTestCases = @(
  @{
    Description = "missing ServiceConnection"
    Parameters = @{ WorkingDirectory = 'infra'; Organization = 'my-team' }
    ErrorMessage = "A value for the 'ServiceConnection' parameter must be provided."
  },
  @{
    Description = "missing Organization"
    Parameters = @{ WorkingDirectory = 'infra'; ServiceConnection = 'Snyk' }
    ErrorMessage = "A value for the 'Organization' parameter must be provided."
  },
  @{
    Description = "with an empty Organization"
    Parameters = @{ WorkingDirectory = 'infra'; ServiceConnection = 'Snyk'; Organization = '' }
    ErrorMessage = "The 'Organization' parameter"
  },
  @{
    Description = "with an invalid SeverityThreshold"
    Parameters = $required.Clone() + @{ SeverityThreshold = 'severe' }
    ErrorMessage = "SeverityThreshold"
  },
  @{
    Description = "with a non-boolean FailOnIssues"
    Parameters = $required.Clone() + @{ FailOnIssues = 'maybe' }
    ErrorMessage = "FailOnIssues"
  },
  @{
    Description = "with a misspelled setting (Organisation)"
    Parameters = $required.Clone() + @{ Organisation = 'my-team' }
    ErrorMessage = "Organisation"
  }
)

# ============================================================================
# RUN TESTS
# ============================================================================

Run-Tests `
  -YamlPath "checks/snykiac.yml" `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases
