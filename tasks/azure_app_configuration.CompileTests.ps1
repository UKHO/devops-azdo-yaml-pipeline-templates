# ============================================================================
# TEST: Azure App Configuration Task Template
# ============================================================================
# Tests for the azure_app_configuration.yml task wrapper.

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
    Description = "with required parameters"
    Parameters = @{
      AppConfigServiceConnection = "MyAzureServiceConnection"
      AppConfigEndpoint = "https://my-appconfig.azconfig.io"
    }
    ExpectedYaml = @(
      "task: AzureAppConfigurationExport@10"
      "displayName: 'Download config: https://my-appconfig.azconfig.io'"
      "azureSubscription: MyAzureServiceConnection"
      "AppConfigurationEndpoint: https://my-appconfig.azconfig.io"
      "SelectionMode: Default"
      "KeyFilter: '*'"
      "Label: ''"
      "TrimKeyPrefix: ''"
      "SuppressWarningForOverriddenKeys: False"
      "TreatKeyVaultErrorsAsWarning: False"
    )
  },
  @{
    Description = "with explicit optional parameters"
    Parameters = @{
      AppConfigServiceConnection = "MyAzureServiceConnection"
      AppConfigEndpoint = "https://my-appconfig.azconfig.io"
      AppConfigName = "appconfig-production"
      SelectionMode = "Default"
      KeyFilter = "app:*"
      Label = "prod"
      TrimKeyPrefix = "app:"
      SuppressWarningForOverriddenKeys = $true
    }
    ExpectedYaml = @(
      "displayName: 'Download config: appconfig-production'"
      "SelectionMode: Default"
      "KeyFilter: app:*"
      "Label: prod"
      "TrimKeyPrefix: 'app:'"
      "SuppressWarningForOverriddenKeys: True"
    )
  },
  @{
    Description = "with snapshot mode"
    Parameters = @{
      AppConfigServiceConnection = "MyAzureServiceConnection"
      AppConfigEndpoint = "https://my-appconfig.azconfig.io"
      SelectionMode = "Snapshot"
      SnapshotName = "release-2026-06-19"
    }
    ExpectedYaml = @(
      "SelectionMode: Snapshot"
      "SnapshotName: release-2026-06-19"
    )
  }
)

$invalidTestCases = @(
  @{
    Description = "with missing AppConfigServiceConnection"
    Parameters = @{
      AppConfigEndpoint = "https://my-appconfig.azconfig.io"
    }
    ErrorMessage = "A value for the 'AppConfigServiceConnection' parameter must be provided."
  },
  @{
    Description = "with missing AppConfigEndpoint"
    Parameters = @{
      AppConfigServiceConnection = "MyAzureServiceConnection"
    }
    ErrorMessage = "A value for the 'AppConfigEndpoint' parameter must be provided."
  }
)

# ============================================================================
# RUN TESTS
# ============================================================================

Run-Tests `
  -YamlPath "tasks/azure_app_configuration.yml" `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases

