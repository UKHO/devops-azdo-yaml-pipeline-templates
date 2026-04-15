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
    Parameters = @{ }
    ExpectedYaml = @(
      ' -backend-config="resource_group_name=$(TFStateResourceGroupName)"'
      ' -backend-config="storage_account_name=$(TFStateStorageAccountName)"'
      ' -backend-config="container_name=tfstate-devops-azdo-yaml-pipeline-templates"'
      ' -backend-config="key=pipeline.elastic_test.tfstate"'
    )
  }
)

# Invalid test cases
$invalidTestCases = @()

# ============================================================================
# RUN TESTS
# ============================================================================

Run-Tests `
  -YamlPath "tests/pipelines/infrastructure_pipeline/elastic_test.yml" `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases
