# ============================================================================
# TEST: Config Sources Schema
# ============================================================================
# Validation tests for the ConfigSources object-array schema.

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
    Description = "with a single KeyVault entry"
    Parameters = @{
      ConfigSources = @"
 - Type: KeyVault
   Name: "dev-vault"
   ServiceConnection: "Azure-Dev-SC"
"@
    }
  },
  @{
    Description = "with a single AppConfiguration entry"
    Parameters = @{
      ConfigSources = @"
 - Type: AppConfiguration
   Endpoint: "https://dev-appconfig.azconfig.io"
   ServiceConnection: "Azure-Dev-SC"
"@
    }
  },
  @{
    Description = "with a single AppConfiguration snapshot entry"
    Parameters = @{
      ConfigSources = @"
 - Type: AppConfiguration
   Endpoint: "https://dev-appconfig.azconfig.io"
   ServiceConnection: "Azure-Dev-SC"
   SelectionMode: Snapshot
   SnapshotName: "release-2026-06-19"
"@
    }
  },
  @{
    Description = "with mixed entries preserving order"
    Parameters = @{
      ConfigSources = @"
 - Type: KeyVault
   Name: "shared-vault"
   ServiceConnection: "Azure-Shared-SC"
   SecretsFilter: "shared-*"
 - Type: AppConfiguration
   Endpoint: "https://appconfig-discovery.azconfig.io"
   ServiceConnection: "Azure-App-SC"
   KeyFilter: "app:*"
   Label: "prod"
   TrimKeyPrefix: "app:"
"@
    }
  },
  @{
    Description = "with optional fields populated for both source types"
    Parameters = @{
      ConfigSources = @"
 - Type: KeyVault
   Name: "shared-vault"
   ServiceConnection: "Azure-Shared-SC"
   SecretsFilter: "shared-*"
   RunAsPreJob: true
 - Type: AppConfiguration
   Endpoint: "https://appconfig-discovery.azconfig.io"
   Name: "appconfig-discovery"
   ServiceConnection: "Azure-App-SC"
   SelectionMode: Default
   KeyFilter: "app:*"
   Label: "prod"
   TrimKeyPrefix: "app:"
   SuppressWarningForOverriddenKeys: true
   TreatKeyVaultErrorsAsWarning: false
"@
    }
  }
)

$invalidTestCases = @(
  @{
    Description = "missing ConfigSources parameter"
    Parameters = @{ }
    ErrorMessage = "A value for the 'ConfigSources' parameter must be provided."
  },
  @{
    Description = "ConfigSources is an empty array"
    Parameters = @{
      ConfigSources = @"
[]
"@
    }
    ErrorMessage = "Invalid ConfigSources: list cannot be empty. If no configuration sources are needed, omit the parameter entirely."
  },
  @{
    Description = "ConfigSources entry has an invalid Type"
    Parameters = @{
      ConfigSources = @"
 - Type: Unsupported
   Name: "dev-vault"
   ServiceConnection: "Azure-Dev-SC"
"@
    }
    ErrorMessage = "Invalid ConfigSources: entry field 'Type' is required, must be a non-empty string, and must be one of 'KeyVault' or 'AppConfiguration'."
  },
  @{
    Description = "KeyVault entry is missing Name"
    Parameters = @{
      ConfigSources = @"
 - Type: KeyVault
   ServiceConnection: "Azure-Dev-SC"
"@
    }
    ErrorMessage = "Invalid ConfigSources: KeyVault entry is missing required field 'Name'."
  },
  @{
    Description = "AppConfiguration entry is missing Endpoint"
    Parameters = @{
      ConfigSources = @"
 - Type: AppConfiguration
   ServiceConnection: "Azure-Dev-SC"
"@
    }
    ErrorMessage = "Invalid ConfigSources: AppConfiguration entry is missing required field 'Endpoint'."
  },
  @{
    Description = "AppConfiguration entry has invalid SelectionMode"
    Parameters = @{
      ConfigSources = @"
 - Type: AppConfiguration
   Endpoint: "https://dev-appconfig.azconfig.io"
   ServiceConnection: "Azure-Dev-SC"
   SelectionMode: Invalid
"@
    }
    ErrorMessage = "Invalid ConfigSources: AppConfiguration entry field 'SelectionMode' must be one of 'Default' or 'Snapshot'."
  },
  @{
    Description = "AppConfiguration snapshot entry is missing SnapshotName"
    Parameters = @{
      ConfigSources = @"
 - Type: AppConfiguration
   Endpoint: "https://dev-appconfig.azconfig.io"
   ServiceConnection: "Azure-Dev-SC"
   SelectionMode: Snapshot
"@
    }
    ErrorMessage = "Invalid ConfigSources: AppConfiguration entry requires 'SnapshotName' when SelectionMode is 'Snapshot'."
  },
  @{
    Description = "ConfigSources entry is missing ServiceConnection"
    Parameters = @{
      ConfigSources = @"
 - Type: KeyVault
   Name: "dev-vault"
"@
    }
    ErrorMessage = "Invalid ConfigSources: entry is missing required field 'ServiceConnection'."
  },
  @{
    Description = "KeyVault optional SecretsFilter has invalid type"
    Parameters = @{
      ConfigSources = @"
 - Type: KeyVault
   Name: "dev-vault"
   ServiceConnection: "Azure-Dev-SC"
   SecretsFilter:
     bad: value
"@
    }
    ErrorMessage = "Invalid ConfigSources: KeyVault entry field 'SecretsFilter' must be a non-empty string when provided."
  },
  @{
    Description = "KeyVault optional SecretsFilter is provided empty"
    Parameters = @{
      ConfigSources = @"
 - Type: KeyVault
   Name: "dev-vault"
   ServiceConnection: "Azure-Dev-SC"
   SecretsFilter: ''
"@
    }
    ErrorMessage = "Invalid ConfigSources: KeyVault entry field 'SecretsFilter' must be a non-empty string when provided."
  },
  @{
    Description = "KeyVault optional RunAsPreJob has invalid type"
    Parameters = @{
      ConfigSources = @"
 - Type: KeyVault
   Name: "dev-vault"
   ServiceConnection: "Azure-Dev-SC"
   RunAsPreJob: "error"
"@
    }
    ErrorMessage = "Invalid ConfigSources: KeyVault entry field 'RunAsPreJob' must be a boolean when provided."
  },
  @{
    Description = "AppConfiguration optional KeyFilter has invalid type"
    Parameters = @{
      ConfigSources = @"
 - Type: AppConfiguration
   Endpoint: "https://dev-appconfig.azconfig.io"
   ServiceConnection: "Azure-Dev-SC"
   KeyFilter:
     bad: value
"@
    }
    ErrorMessage = "Invalid ConfigSources: AppConfiguration entry field 'KeyFilter' must be a non-empty string when provided."
  },
  @{
    Description = "AppConfiguration optional Name is provided empty"
    Parameters = @{
      ConfigSources = @"
 - Type: AppConfiguration
   Endpoint: "https://dev-appconfig.azconfig.io"
   ServiceConnection: "Azure-Dev-SC"
   Name: ''
"@
    }
    ErrorMessage = "Invalid ConfigSources: AppConfiguration entry field 'Name' must be a non-empty string when provided."
  },
  @{
    Description = "AppConfiguration optional KeyFilter is provided empty"
    Parameters = @{
      ConfigSources = @"
 - Type: AppConfiguration
   Endpoint: "https://dev-appconfig.azconfig.io"
   ServiceConnection: "Azure-Dev-SC"
   KeyFilter: ''
"@
    }
    ErrorMessage = "Invalid ConfigSources: AppConfiguration entry field 'KeyFilter' must be a non-empty string when provided."
  },
  @{
    Description = "AppConfiguration optional Label has invalid type"
    Parameters = @{
      ConfigSources = @"
 - Type: AppConfiguration
   Endpoint: "https://dev-appconfig.azconfig.io"
   ServiceConnection: "Azure-Dev-SC"
   Label:
    - prod
"@
    }
    ErrorMessage = "Invalid ConfigSources: AppConfiguration entry field 'Label' must be a non-empty string when provided."
  },
  @{
    Description = "AppConfiguration optional Label is provided empty"
    Parameters = @{
      ConfigSources = @"
 - Type: AppConfiguration
   Endpoint: "https://dev-appconfig.azconfig.io"
   ServiceConnection: "Azure-Dev-SC"
   Label: ''
"@
    }
    ErrorMessage = "Invalid ConfigSources: AppConfiguration entry field 'Label' must be a non-empty string when provided."
  },
  @{
    Description = "AppConfiguration optional TrimKeyPrefix has invalid type"
    Parameters = @{
      ConfigSources = @"
 - Type: AppConfiguration
   Endpoint: "https://dev-appconfig.azconfig.io"
   ServiceConnection: "Azure-Dev-SC"
   TrimKeyPrefix:
    - app:
"@
    }
    ErrorMessage = "Invalid ConfigSources: AppConfiguration entry field 'TrimKeyPrefix' must be a non-empty string when provided."
  },
  @{
    Description = "AppConfiguration optional TrimKeyPrefix is provided empty"
    Parameters = @{
      ConfigSources = @"
 - Type: AppConfiguration
   Endpoint: "https://dev-appconfig.azconfig.io"
   ServiceConnection: "Azure-Dev-SC"
   TrimKeyPrefix: ''
"@
    }
    ErrorMessage = "Invalid ConfigSources: AppConfiguration entry field 'TrimKeyPrefix' must be a non-empty string when provided."
  },
  @{
    Description = "AppConfiguration optional SnapshotName is provided empty"
    Parameters = @{
      ConfigSources = @"
 - Type: AppConfiguration
   Endpoint: "https://dev-appconfig.azconfig.io"
   ServiceConnection: "Azure-Dev-SC"
   SnapshotName: ''
"@
    }
    ErrorMessage = "Invalid ConfigSources: AppConfiguration entry field 'SnapshotName' must be a non-empty string when provided."
  },
  @{
    Description = "AppConfiguration optional SuppressWarningForOverriddenKeys has invalid type"
    Parameters = @{
      ConfigSources = @"
 - Type: AppConfiguration
   Endpoint: "https://dev-appconfig.azconfig.io"
   ServiceConnection: "Azure-Dev-SC"
   SuppressWarningForOverriddenKeys: "error"
"@
    }
    ErrorMessage = "Invalid ConfigSources: AppConfiguration entry field 'SuppressWarningForOverriddenKeys' must be a boolean when provided."
  },
  @{
    Description = "AppConfiguration optional TreatKeyVaultErrorsAsWarning has invalid type"
    Parameters = @{
      ConfigSources = @"
 - Type: AppConfiguration
   Endpoint: "https://dev-appconfig.azconfig.io"
   ServiceConnection: "Azure-Dev-SC"
   TreatKeyVaultErrorsAsWarning: "error"
"@
    }
    ErrorMessage = "Invalid ConfigSources: AppConfiguration entry field 'TreatKeyVaultErrorsAsWarning' must be a boolean when provided."
  }
)

# ============================================================================
# RUN TESTS
# ============================================================================

Run-Tests `
  -YamlPath "schemas/config_sources.yml" `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases

