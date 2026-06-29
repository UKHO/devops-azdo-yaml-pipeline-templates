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
    Description = "with optional fields populated"
    Parameters = @{
      ConfigSources = @"
 - Type: KeyVault
   Name: "shared-vault"
   ServiceConnection: "Azure-Shared-SC"
   SecretsFilter: "shared-*"
   RunAsPreJob: true
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
    ErrorMessage = "Invalid ConfigSources: entry field 'Type' is required, must be a non-empty string, and must be 'KeyVault'."
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
  }
)

# ============================================================================
# RUN TESTS
# ============================================================================

Run-Tests `
  -YamlPath "schemas/config_sources.yml" `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases

