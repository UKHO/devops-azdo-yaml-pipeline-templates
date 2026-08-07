# ============================================================================
# TEST: MANUAL VERIFICATION CONFIG SCHEMA
# ============================================================================

# Load framework (only if not already loaded)
if (-not (Get-Command -Name 'Run-Tests' -ErrorAction SilentlyContinue))
{
  $repoRoot = git rev-parse --show-toplevel 2> $null
  . (Join-Path $repoRoot "tests" "framework" "Core.ps1")
}

$validTestCases = @(
  @{
    Description = "no ManualVerificationConfig provided (uses default empty object)"
    Parameters = @{
      ContextName = "ManualVerification"
    }
  },
  @{
    Description = "ManualVerificationConfig with only required TimeoutInMinutes"
    Parameters = @{
      ContextName = "ManualVerification"
      ManualVerificationConfig = @{
        TimeoutInMinutes = 1
      }
    }
  },
  @{
    Description = "ManualVerificationConfig with all fields"
    Parameters = @{
      ContextName = "ManualVerification"
      ManualVerificationConfig = @{
        TimeoutInMinutes = 240
        OnTimeoutBehaviour = "resume"
        Instructions = "Please review and approve"
      }
    }
  },
  @{
    Description = "ManualVerificationConfig with OnTimeoutBehaviour reject"
    Parameters = @{
      ContextName = "ManualVerification"
      ManualVerificationConfig = @{
        TimeoutInMinutes = 60
        OnTimeoutBehaviour = "reject"
      }
    }
  },
  @{
    Description = "ManualVerificationConfig with maximum TimeoutInMinutes"
    Parameters = @{
      ContextName = "ManualVerification"
      ManualVerificationConfig = @{
        TimeoutInMinutes = 43200
      }
    }
  }
)

$invalidTestCases = @(
  @{
    Description = "missing required ContextName parameter"
    Parameters = @{
      ManualVerificationConfig = @{
        TimeoutInMinutes = 1
      }
    }
    ErrorMessage = "A value for the 'ContextName' parameter must be provided."
  },
  @{
    Description = "ManualVerificationConfig provided without required TimeoutInMinutes"
    Parameters = @{
      ContextName = "ManualVerification"
      ManualVerificationConfig = @{
        OnTimeoutBehaviour = "resume"
      }
    }
    ErrorMessage = "ManualVerificationConfig.TimeoutInMinutes is required when ManualVerificationConfig is provided."
  },
  @{
    Description = "invalid OnTimeoutBehaviour value"
    Parameters = @{
      ContextName = "ManualVerification"
      ManualVerificationConfig = @{
        TimeoutInMinutes = 60
        OnTimeoutBehaviour = "invalid"
      }
    }
    ErrorMessage = "ManualVerificationConfig.OnTimeoutBehaviour must be either 'reject' or 'resume'."
  },
  @{
    Description = "TimeoutInMinutes below minimum"
    Parameters = @{
      ContextName = "ManualVerification"
      ManualVerificationConfig = @{
        TimeoutInMinutes = 0
      }
    }
    ErrorMessage = "ManualVerificationConfig.TimeoutInMinutes must be a number between 1 and 43200 (30 days)."
  },
  @{
    Description = "TimeoutInMinutes above maximum"
    Parameters = @{
      ContextName = "ManualVerification"
      ManualVerificationConfig = @{
        TimeoutInMinutes = 43201
      }
    }
    ErrorMessage = "ManualVerificationConfig.TimeoutInMinutes must be a number between 1 and 43200 (30 days)."
  },
  @{
    Description = "empty Instructions string"
    Parameters = @{
      ContextName = "ManualVerification"
      ManualVerificationConfig = @{
        TimeoutInMinutes = 60
        Instructions = ""
      }
    }
    ErrorMessage = "ManualVerificationConfig.Instructions must be a non-empty string when provided."
  }
)

# ============================================================================
# RUN TESTS
# ============================================================================

Run-Tests `
  -YamlPath "schemas/manual_verification_config.yml" `
  -TransformYamlFunction { param($yaml) return $yaml + @"
  - job:
    steps:
    - script: echo \"Hello World\"
"@ } `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases
