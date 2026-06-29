# ============================================================================
# TEST: Azure Key Vault Task Template
# ============================================================================
# Tests for the azure_key_vault.yml task wrapper.

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
      KeyVaultServiceConnection = "MyAzureServiceConnection"
      KeyVaultName = "my-keyvault"
    }
    ExpectedYaml = @(
      "task: AzureKeyVault@2"
      "displayName: 'Download secrets: my-keyvault'"
      "azureSubscription: MyAzureServiceConnection"
      "KeyVaultName: my-keyvault"
    )
  },
  @{
    Description = "with explicit secrets filter"
    Parameters = @{
      KeyVaultServiceConnection = "MyAzureServiceConnection"
      KeyVaultName = "my-keyvault"
      SecretsFilter = "appsecret1,appsecret2"
    }
    ExpectedYaml = @(
      "SecretsFilter: appsecret1,appsecret2"
    )
  },
  @{
    Description = "with run as pre-job enabled"
    Parameters = @{
      KeyVaultServiceConnection = "MyAzureServiceConnection"
      KeyVaultName = "my-keyvault"
      RunAsPreJob = $true
    }
    ExpectedYaml = @(
      "RunAsPreJob: true"
    )
  },
  @{
    Description = "with wildcard secrets filter"
    Parameters = @{
      KeyVaultServiceConnection = "MyAzureServiceConnection"
      KeyVaultName = "my-keyvault"
      SecretsFilter = "terraform-*"
    }
    ExpectedYaml = @(
      "SecretsFilter: terraform-*"
    )
  }
)

$invalidTestCases = @(
  @{
    Description = "with missing KeyVaultServiceConnection"
    Parameters = @{
      KeyVaultName = "my-keyvault"
    }
    ErrorMessage = "A value for the 'KeyVaultServiceConnection' parameter must be provided."
  },
  @{
    Description = "with missing KeyVaultName"
    Parameters = @{
      KeyVaultServiceConnection = "MyAzureServiceConnection"
    }
    ErrorMessage = "A value for the 'KeyVaultName' parameter must be provided."
  }
)

# ============================================================================
# RUN TESTS
# ============================================================================

Run-Tests `
  -YamlPath "tasks/azure_key_vault.yml" `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases

