# ============================================================================
# TEST: Snyk Scan Task Template
# ============================================================================
# Tests for tasks/snyk_scan.yml, a wrapper around UkhoSnykScanTask@0 (iac only for now).
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
  ServiceConnection = 'Snyk'
  Organization = 'my-team'
  WorkingDirectory = '$(Pipeline.Workspace)/infra'
}

$validTestCases = @(
  @{
    Description = "with only the required parameters"
    Parameters = $required.Clone()
    ExpectedYaml = @(
      'task: UkhoSnykScanTask@0'
      'name: SnykScanTask_iac'
      'displayName: Snyk iac scan'
      'serviceConnectionEndpoint: Snyk'
      'testType: iac'
      'organization: my-team'
      'testDirectory: $(Pipeline.Workspace)/infra'
      'severityThreshold: low'
      'failOnIssues: true'
    )
  },
  @{
    Description = "with every optional parameter"
    Parameters = $required.Clone() + @{
      SeverityThreshold = 'critical'
      FailOnIssues = $false
      AdditionalArguments = '--report'
      ReportFileName = 'snyk-iac-Root'
      TaskNameUniqueSlug = 'Root'
      ContinueOnError = $true
    }
    ExpectedYaml = @(
      'name: SnykScanTask_iac_Root'
      'displayName: Snyk iac scan (Root)'
      'severityThreshold: critical'
      'failOnIssues: false'
      'additionalArguments: --report'
      'reportFileName: snyk-iac-Root'
      'continueOnError: true'
    )
  }
)

$invalidTestCases = @(
  @{
    Description = "missing ServiceConnection"
    Parameters = @{ Organization = 'my-team'; WorkingDirectory = 'infra' }
    ErrorMessage = "A value for the 'ServiceConnection' parameter must be provided."
  },
  @{
    Description = "missing Organization"
    Parameters = @{ ServiceConnection = 'Snyk'; WorkingDirectory = 'infra' }
    ErrorMessage = "A value for the 'Organization' parameter must be provided."
  },
  @{
    Description = "missing WorkingDirectory"
    Parameters = @{ ServiceConnection = 'Snyk'; Organization = 'my-team' }
    ErrorMessage = "A value for the 'WorkingDirectory' parameter must be provided."
  },
  @{
    Description = "with an unsupported TestType"
    Parameters = $required.Clone() + @{ TestType = 'container' }
    ErrorMessage = "TestType"
  },
  @{
    Description = "with an invalid SeverityThreshold"
    Parameters = $required.Clone() + @{ SeverityThreshold = 'severe' }
    ErrorMessage = "SeverityThreshold"
  }
)

# ============================================================================
# RUN TESTS
# ============================================================================

Run-Tests `
  -YamlPath "tasks/snyk_scan.yml" `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases
