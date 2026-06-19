# ============================================================================
# TEST: Key Vault Configs Task List Utility Template
# ============================================================================
# Compile tests for utils/key_vault_configs_task_list.yml.
# Verifies that the template expands to the reusable Azure Key Vault task wrapper
# with the expected parameter values and ordering.

# Load framework (only if not already loaded)
if (-not (Get-Command -Name 'Run-Tests' -ErrorAction SilentlyContinue))
{
  $repoRoot = git rev-parse --show-toplevel 2> $null
  . (Join-Path $repoRoot "tests" "framework" "Core.ps1")
}

# ============================================================================
# DEFINE TEST CASES
# ============================================================================

# Parameters = @{
#   AdditionalFilesToPackage = @"
# - FilesPattern: '**'
#   SourceDirectory: resources/keyvault
#   TargetSubdirectoryName: keyvault
# "@
# }

$validTestCases = @(
  @{
    Description = "with a single KeyVaultConfigs entry using defaults"
    Parameters = @{
      KeyVaultConfigs = @"
 - Name: "dev-vault"
   ServiceConnection: "Azure-Dev-SC"
"@
    }
    ExpectedYaml = @(
      "AzureKeyVault@2"
      "Download secrets from Azure Key Vault: dev-vault"
      "azureSubscription: Azure-Dev-SC"
      "KeyVaultName: dev-vault"
      "SecretsFilter: '*'"
      "RunAsPreJob: false"
    )
  },
  @{
    Description = "with a single KeyVaultConfigs entry using explicit values"
    Parameters = @{
      KeyVaultConfigs = @"
 - Name: "prod-vault"
   ServiceConnection: "Azure-Prod-SC"
   SecretsFilter: "app-*"
   RunAsPreJob: true
"@
    }
    ExpectedYaml = @(
      "AzureKeyVault@2"
      "Download secrets from Azure Key Vault: prod-vault"
      "azureSubscription: Azure-Prod-SC"
      "KeyVaultName: prod-vault"
      "SecretsFilter: app-*"
      "RunAsPreJob: true"
    )
  },
  @{
    Description = "with multiple KeyVaultConfigs entries preserving order"
    Parameters = @{
      KeyVaultConfigs = @"
 - Name: "shared-vault"
   ServiceConnection: "Azure-Shared-SC"
   SecretsFilter: "shared-*"
 - Name: "app-vault"
   ServiceConnection: "Azure-App-SC"
   SecretsFilter: "app-*"
   RunAsPreJob: true
"@
    }
    ExpectedYaml = @(
      "Download secrets from Azure Key Vault: shared-vault"
      "azureSubscription: Azure-Shared-SC"
      "KeyVaultName: shared-vault"
      "SecretsFilter: shared-*"
      "Download secrets from Azure Key Vault: app-vault"
      "azureSubscription: Azure-App-SC"
      "KeyVaultName: app-vault"
      "SecretsFilter: app-*"
      "RunAsPreJob: true"
    )
  }
)

$invalidTestCases = @(
  @{
    Description = "missing KeyVaultConfigs parameter"
    Parameters = @{ }
    ErrorMessage = "A value for the 'KeyVaultConfigs' parameter must be provided."
  },
  @{
    Description = "validation is triggered"
    Parameters = @{
      KeyVaultConfigs = @"
[]
"@
    }
    ErrorMessage = "Invalid KeyVaultConfigs: array cannot be empty. If no Key Vaults are needed, omit the parameter entirely."
  }
)

# ============================================================================
# RUN TESTS
# ============================================================================

Run-Tests `
  -YamlPath "utils/key_vault_configs_task_list.yml" `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases

