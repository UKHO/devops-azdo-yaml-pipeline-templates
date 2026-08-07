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
  },
  @{
    Description = "missing required TerraformDestroyConfig parameter"
    Parameters = @{
      EnvironmentName = "dev"
    }
  },
  @{
    Description = "invalid RunMode value"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        RunMode = "InvalidMode"
      }
    }
  },
  @{
    Description = "VerificationMode is not supported for destroy workflows"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        RunMode = "PlanVerifyDestroy"
        VerificationMode = "VerifyOnAny"
      }
    }
  },
  @{
    Description = "invalid VerificationTimeoutBehaviour"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        RunMode = "PlanVerifyDestroy"
        VerificationTimeoutBehaviour = "invalid"
      }
    }
  }
)

Run-Tests `
  -YamlPath "jobs/terraform_gated_destroy.yml" `
  -TransformYamlFunction { param($yaml) return $yaml -replace 'AzDOPipelineTemplates', 'self' } `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases

