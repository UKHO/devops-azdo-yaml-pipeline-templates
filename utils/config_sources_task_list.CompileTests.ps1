# ============================================================================
# TEST: Config Sources Task List Utility Template
# ============================================================================
# Compile tests for utils/config_sources_task_list.yml.
# Verifies that the template expands to the reusable task wrappers with the
# expected parameter values and ordering.

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
    Description = "with a single KeyVault entry using defaults"
    Parameters = @{
      ConfigSources = @"
 - Type: KeyVault
   Name: "dev-vault"
   ServiceConnection: "Azure-Dev-SC"
"@
    }
    ExpectedYaml = @(
      "task: AzureKeyVault@2"
      "azureSubscription: Azure-Dev-SC"
      "KeyVaultName: dev-vault"
      "SecretsFilter: '*'"
      "RunAsPreJob: False"
    )
  },
  @{
    Description = "with a KeyVault entry enabling RunAsPreJob"
    Parameters = @{
      ConfigSources = @"
 - Type: KeyVault
   Name: "dev-vault"
   ServiceConnection: "Azure-Dev-SC"
   RunAsPreJob: true
"@
    }
    ExpectedYaml = @(
      "task: AzureKeyVault@2"
      "RunAsPreJob: True"
    )
  },
  @{
    Description = "with a KeyVault entry SecretFilter"
    Parameters = @{
      ConfigSources = @"
 - Type: KeyVault
   Name: "dev-vault"
   ServiceConnection: "Azure-Dev-SC"
   SecretsFilter: 'SERVICE-PRINCIPAL-ID'
"@
    }
    ExpectedYaml = @(
      "task: AzureKeyVault@2"
      "SecretsFilter: SERVICE-PRINCIPAL-ID"
    )
  },
  @{
    Description = "with multiple KeyVault entries preserving order"
    Parameters = @{
      ConfigSources = @"
 - Type: KeyVault
   Name: "shared-vault"
   ServiceConnection: "Azure-Shared-SC"
   SecretsFilter: "shared-*"
 - Type: KeyVault
   Name: "tenant-vault"
   ServiceConnection: "Azure-Tenant-SC"
   SecretsFilter: "tenant-*"
"@
    }
    ExpectedYaml = @(
      "task: AzureKeyVault@2"
      "KeyVaultName: shared-vault"
      "SecretsFilter: shared-*"
      "task: AzureKeyVault@2"
      "KeyVaultName: tenant-vault"
      "SecretsFilter: tenant-*"
    )
  }
)

$invalidTestCases = @(
  @{
    Description = "missing ConfigSources parameter"
    Parameters = @{ }
    ErrorMessage = "A value for the 'ConfigSources' parameter must be provided."
  },
  @{
    Description = "validation is triggered for empty array"
    Parameters = @{
      ConfigSources = @"
[]
"@
    }
    ErrorMessage = "Invalid ConfigSources: list cannot be empty. If no configuration sources are needed, omit the parameter entirely."
  },
  @{
    Description = "validation is triggered for unsupported Type"
    Parameters = @{
      ConfigSources = @"
 - Type: Unsupported
   Name: "dev-vault"
   ServiceConnection: "Azure-Dev-SC"
"@
    }
    ErrorMessage = "Invalid ConfigSources: entry field 'Type' is required, must be a non-empty string, and must be 'KeyVault'."
  },
  @{
    Description = "validation is triggered for missing ServiceConnection"
    Parameters = @{
      ConfigSources = @"
 - Type: KeyVault
   Name: "dev-vault"
"@
    }
    ErrorMessage = "Invalid ConfigSources: entry is missing required field 'ServiceConnection'."
  }
)

# ============================================================================
# RUN TESTS
# ============================================================================

Run-Tests `
  -YamlPath "utils/config_sources_task_list.yml" `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases

