# ============================================================================
# TEST: Key Vault Configs Schema
# ============================================================================
# Validation tests for the KeyVaultConfigs object-array schema.

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
    Description = "with single KeyVaultConfigs entry"
    Parameters = @{
      KeyVaultConfigs = @"
 - Name: "dev-vault"
   ServiceConnection: "Azure-Dev-SC"
"@
    }
  },
  @{
    Description = "with multiple KeyVaultConfigs entries"
    Parameters = @{
      KeyVaultConfigs = @"
 - Name: "shared-vault"
   ServiceConnection: "Azure-Prod-SC"
   SecretsFilter: "shared-*"
 - Name: "app-vault"
   ServiceConnection: "Azure-Prod-SC"
   SecretsFilter: "app-*"
   RunAsPreJob: true
"@
    }
  }
)

$invalidTestCases = @(
  @{
    Description = "missing KeyVaultConfigs parameter"
    Parameters = @{ }
    ErrorMessage = "A value for the 'KeyVaultConfigs' parameter must be provided."
  },
  @{
    Description = "KeyVaultConfigs is an empty array"
    Parameters = @{
      KeyVaultConfigs = @"
[]
"@
    }
    ErrorMessage = "Invalid KeyVaultConfigs: array cannot be empty. If no Key Vaults are needed, omit the parameter entirely."
  },
  @{
    Description = "KeyVaultConfigs entry is missing Name"
    Parameters = @{
      KeyVaultConfigs = @"
 - ServiceConnection: "Azure-Dev-SC"
"@
    }
    ErrorMessage = "Invalid KeyVaultConfigs: entry is missing required field 'Name'."
  },
  @{
    Description = "KeyVaultConfigs entry is missing ServiceConnection"
    Parameters = @{
      KeyVaultConfigs = @"
 - Name: "dev-vault"
"@
    }
    ErrorMessage = "Invalid KeyVaultConfigs: entry is missing required field 'ServiceConnection'."
  },
  @{
    Description = "KeyVaultConfigs contains a blank entry"
    Parameters = @{
      KeyVaultConfigs = @"
 -
"@
    }
    ErrorMessage = "Invalid KeyVaultConfigs: entry is missing required field 'Name'."
  },
  @{
    Description = "KeyVaultConfigs contains a blank entry at the end"
    Parameters = @{
      KeyVaultConfigs = @"
 - Name: "shared-vault"
   ServiceConnection: "Azure-Prod-SC"
   SecretsFilter: "shared-*"
 -
"@
    }
    ErrorMessage = "Invalid KeyVaultConfigs: entry is missing required field 'Name'."
  },
  @{
    Description = "KeyVaultConfigs contains a blank entry at the beginning"
    Parameters = @{
      KeyVaultConfigs = @"
 -
 - Name: "shared-vault"
   ServiceConnection: "Azure-Prod-SC"
   SecretsFilter: "shared-*"
"@
    }
    ErrorMessage = "Invalid KeyVaultConfigs: entry is missing required field 'Name'."
  }
)

# ============================================================================
# RUN TESTS
# ============================================================================

Run-Tests `
  -YamlPath "schemas/key_vault_configs.yml" `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases
