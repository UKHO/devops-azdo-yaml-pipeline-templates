# ============================================================================
# TEST: Terraform Gated Destroy Job Template
# ============================================================================

# Load framework (only if not already loaded)
if (-not (Get-Command -Name 'Run-Tests' -ErrorAction SilentlyContinue))
{
  $repoRoot = git rev-parse --show-toplevel 2> $null
  . (Join-Path $repoRoot "tests" "framework" "Core.ps1")
}

$validTestCases = @(
  @{
    Description = "PlanOnly mode - includes only destroy plan job"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        RunMode = "PlanOnly"
      }
    }
    ExpectedYAML = @(
      "TerraformDestroyPlan_TerraformArtifact"
    )
  },
  @{
    Description = "DestroyOnly mode - includes only destroy job"
    Parameters = @{
      EnvironmentName = "prod"
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        RunMode = "DestroyOnly"
      }
    }
    ExpectedYAML = @(
      "TerraformDestroyDestroy_TerraformArtifact"
    )
  },
  @{
    Description = "PlanVerifyDestroy mode - includes plan, manual verification, destroy"
    Parameters = @{
      EnvironmentName = "staging"
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        RunMode = "PlanVerifyDestroy"
      }
    }
    ExpectedYAML = @(
      "TerraformDestroyPlan_TerraformArtifact"
      "ManualVerification_TerraformArtifact"
      "TerraformDestroyDestroy_TerraformArtifact"
      "condition: succeeded('ManualVerification_TerraformArtifact')"
    )
  },
  @{
    Description = "PlanVerifyDestroy with custom artifact"
    Parameters = @{
      EnvironmentName = "staging"
      TerraformArtifactName = "InfraArtifact"
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        RunMode = "PlanVerifyDestroy"
      }
    }
    ExpectedYAML = @(
      "TerraformDestroyPlan_InfraArtifact"
      "ManualVerification_InfraArtifact"
      "TerraformDestroyDestroy_InfraArtifact"
    )
  },
  @{
    Description = "DestroyOnly with custom pool"
    Parameters = @{
      EnvironmentName = "prod"
      Pool = "Premium-Agent-Pool"
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        RunMode = "DestroyOnly"
      }
    }
    ExpectedYAML = @(
      "pool:*name: Premium-Agent-Pool"
    )
  },
  @{
    Description = "PlanVerifyDestroy with VerificationTimeoutInMinutes/VerificationTimeoutBehaviour overrides timeout and behaviour"
    Parameters = @{
      EnvironmentName = "staging"
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        RunMode = "PlanVerifyDestroy"
        VerificationTimeoutInMinutes = 1
        VerificationTimeoutBehaviour = "resume"
      }
    }
    ExpectedYAML = @(
      "timeoutInMinutes: 1"
      "onTimeout: resume"
      "instructions:*Please validate the terraform destroy plan is acceptable to execute"
    )
  },
  @{
    Description = "PlanVerifyDestroy without verification overrides falls back to manual_verification.yml defaults"
    Parameters = @{
      EnvironmentName = "staging"
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        RunMode = "PlanVerifyDestroy"
      }
    }
    ExpectedYAML = @(
      "timeoutInMinutes: 60"
      "onTimeout: reject"
      "instructions:*Please validate the terraform destroy plan is acceptable to execute"
    )
  }
)

$invalidTestCases = @(
  @{
    Description = "missing required EnvironmentName parameter"
    Parameters = @{
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        RunMode = "PlanOnly"
      }
    }
    ErrorMessage = "A value for the 'EnvironmentName' parameter must be provided."
  },
  @{
    Description = "missing required TerraformDestroyConfig parameter"
    Parameters = @{
      EnvironmentName = "dev"
    }
    ErrorMessage = "A value for the 'TerraformDestroyConfig' parameter must be provided."
  },
  @{
    Description = "TerraformDestroyConfig missing AzDOEnvironmentName"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDestroyConfig = @{
        RunMode = "PlanOnly"
      }
    }
    ErrorMessage = "'dev' environment error: AzDOEnvironmentName is not properly defined and is a required field."
  },
  @{
    Description = "TerraformDestroyConfig missing RunMode"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
      }
    }
    ErrorMessage = "RunMode is not properly defined and is a required field. Must be a valid option (PlanVerifyDestroy, PlanOnly, DestroyOnly)."
  },
  @{
    Description = "invalid RunMode value (should be PlanOnly, DestroyOnly, or PlanVerifyDestroy)"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        RunMode = "InvalidMode"
      }
    }
    ErrorMessage = "RunMode must be a valid option (PlanVerifyDestroy, PlanOnly, DestroyOnly)."
  },
  @{
    Description = "invalid VerificationTimeoutBehaviour value"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        RunMode = "PlanVerifyDestroy"
        VerificationTimeoutBehaviour = "invalid"
      }
    }
    ErrorMessage = "VerificationTimeoutBehaviour must be either 'reject' or 'resume'."
  },
  @{
    Description = "invalid VerificationTimeoutInMinutes value (out of range)"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        RunMode = "PlanVerifyDestroy"
        VerificationTimeoutInMinutes = 43201
      }
    }
    ErrorMessage = "VerificationTimeoutInMinutes must be a number between 1 and 43200 (30 days)."
  }
)

Run-Tests `
  -YamlPath "jobs/terraform_gated_destroy.yml" `
  -TransformYamlFunction { param($yaml) return $yaml -replace 'AzDOPipelineTemplates', 'self' } `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases

