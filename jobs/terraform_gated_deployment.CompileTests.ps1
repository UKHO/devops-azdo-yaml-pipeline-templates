# ============================================================================
# TEST: Terraform Deploy
# ============================================================================

# Load framework (only if not already loaded)
if (-not (Get-Command -Name 'Run-Tests' -ErrorAction SilentlyContinue))
{
  $repoRoot = git rev-parse --show-toplevel 2> $null
  . (Join-Path $repoRoot "tests" "framework" "Core.ps1")
}

# ============================================================================
# DEFINE TEST CASES
# ============================================================================

# Valid test cases with different parameter combinations
$validTestCases = @(
  # ========================================================================
  # RUNMODE TESTS
  # ========================================================================
  
  @{
    Description = "PlanOnly mode - includes only Plan job"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        RunMode = "PlanOnly"
      }
    }
    ExpectedYAML = @(
      "TerraformDeployPlan_TerraformArtifact"
    )
  },

  @{
    Description = "ApplyOnly mode - includes only Apply job without plan"
    Parameters = @{
      EnvironmentName = "prod"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        RunMode = "ApplyOnly"
      }
    }
    ExpectedYAML = @(
      "TerraformDeployApply_TerraformArtifact"
    )
  },

  @{
    Description = "PlanVerifyApply mode - includes Plan, Manual Verification, and Apply jobs"
    Parameters = @{
      EnvironmentName = "staging"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        RunMode = "PlanVerifyApply"
        VerificationMode = "VerifyOnAny"
      }
    }
    ExpectedYAML = @(
      "TerraformDeployPlan_TerraformArtifact"
      "TerraformDeployApply_TerraformArtifact"
      "ManualVerification_TerraformArtifact"
    )
  },

  # ========================================================================
  # VERIFICATION MODE TESTS (with PlanVerifyApply)
  # ========================================================================
  
  @{
    Description = "PlanVerifyApply with VerifyOnDestroy verification mode"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        RunMode = "PlanVerifyApply"
        VerificationMode = "VerifyOnDestroy"
      }
    }
    ExpectedYAML = "ManualVerification_TerraformArtifact"
  },

  @{
    Description = "PlanVerifyApply with VerifyDisabled verification mode"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        RunMode = "PlanVerifyApply"
        VerificationMode = "VerifyDisabled"
      }
    }
    ExpectedYAML = "ManualVerification_TerraformArtifact"
  },

  # ========================================================================
  # CHECKOUT ALIAS TESTS
  # ========================================================================
  
  @{
    Description = "with CheckoutAlias set to 'self'"
    Parameters = @{
      EnvironmentName = "dev"
      CheckoutAlias = "self"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        RunMode = "ApplyOnly"
      }
    }
    ExpectedYAML = "repository: self"
  },

  # ========================================================================
  # CONDITION TESTS
  # ========================================================================
  
  @{
    Description = "with failed() condition on PlanOnly mode"
    Parameters = @{
      EnvironmentName = "dev"
      Condition = "failed()"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        RunMode = "PlanOnly"
      }
    }
    ExpectedYAML = "condition: failed()"
  },

  # ========================================================================
  # POOL TESTS
  # ========================================================================
  
  @{
    Description = "with custom Pool configuration"
    Parameters = @{
      EnvironmentName = "prod"
      Pool = "Premium-Agent-Pool"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        RunMode = "ApplyOnly"
      }
    }
    ExpectedYAML = "pool:*name: Premium-Agent-Pool"
  },

  # ========================================================================
  # VERSION AND ARTIFACT TESTS
  # ========================================================================
  
  @{
    Description = "with custom Terraform version"
    Parameters = @{
      EnvironmentName = "prod"
      TerraformVersion = "1.6.5"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        RunMode = "ApplyOnly"
      }
    }
    ExpectedYAML = "TerraformVersion: 1.6.5"
  },

  @{
    Description = "with default Terraform version (1.14.0)"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        RunMode = "PlanOnly"
      }
    }
    ExpectedYAML = "TerraformVersion: 1.14.0"
  },

  @{
    Description = "with custom TerraformArtifactName"
    Parameters = @{
      EnvironmentName = "prod"
      TerraformArtifactName = "InfrastructureArtifact"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        RunMode = "PlanVerifyApply"
        VerificationMode = "VerifyOnAny"
      }
    }
    ExpectedYAML = @(
      "artifactName: InfrastructureArtifact"
      "ManualVerification_InfrastructureArtifact"
    )
  },

  @{
    Description = "with default TerraformArtifactName (TerraformArtifact)"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        RunMode = "PlanOnly"
      }
    }
    ExpectedYAML = "artifactName: TerraformArtifact"
  },

  # ========================================================================
  # DEPENDENCIES TESTS
  # ========================================================================
  
  @{
    Description = "PlanVerifyApply with proper dependencies between jobs"
    Parameters = @{
      EnvironmentName = "staging"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        RunMode = "PlanVerifyApply"
        VerificationMode = "VerifyOnAny"
      }
    }
    ExpectedYAML = @(
      "dependsOn:*- TerraformDeployPlan_TerraformArtifact"
      "dependsOn:*- ManualVerification_TerraformArtifact*- TerraformDeployPlan_TerraformArtifact"
    )
  },

  # ========================================================================
  # COMBINED/INTEGRATION TESTS
  # ========================================================================
  
  @{
    Description = "Complex scenario: PlanVerifyApply with custom versions, pool, and artifact name"
    Parameters = @{
      EnvironmentName = "production"
      CheckoutAlias = "self"
      Condition = "eq(variables['Environment'], 'Production')"
      Pool = "Production-Agents"
      TerraformVersion = "1.5.7"
      TerraformArtifactName = "ProdInfraArtifact"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        RunMode = "PlanVerifyApply"
        VerificationMode = "VerifyOnAny"
      }
    }
    ExpectedYAML = @(
      "repository: self"
      "terraformVersion: 1.5.7"
      "artifactName: ProdInfraArtifact"
      "pool:*name: Production-Agents"
      "ManualVerification_ProdInfraArtifact"
      "TerraformDeployPlan_ProdInfraArtifact"
      "TerraformDeployApply_ProdInfraArtifact"
    )
  },

  @{
    Description = "Quick deploy scenario: ApplyOnly with minimal parameters"
    Parameters = @{
      EnvironmentName = "hotfix-env"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        RunMode = "ApplyOnly"
      }
    }
    ExpectedYAML = @(
      "TerraformDeployApply_TerraformArtifact"
    )
  }
)

# Invalid test cases
$invalidTestCases = @(
  @{
    Description = "missing required EnvironmentName parameter"
    Parameters = @{
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        RunMode = "PlanOnly"
      }
    }
  },

  @{
    Description = "missing required TerraformDeploymentConfig parameter"
    Parameters = @{
      EnvironmentName = "dev"
    }
  },

  @{
    Description = "TerraformDeploymentConfig missing AzDOEnvironmentName"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        RunMode = "PlanOnly"
      }
    }
  },

  @{
    Description = "TerraformDeploymentConfig missing RunMode"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
      }
    }
  },

  @{
    Description = "invalid RunMode value (should be PlanOnly, ApplyOnly, or PlanVerifyApply)"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        RunMode = "InvalidMode"
      }
    }
  },

  @{
    Description = "invalid VerificationMode value with PlanVerifyApply"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        RunMode = "PlanVerifyApply"
        VerificationMode = "InvalidVerificationMode"
      }
    }
  },

  @{
    Description = "invalid CheckoutAlias value (must be AzDOPipelineTemplates or self)"
    Parameters = @{
      EnvironmentName = "dev"
      CheckoutAlias = "InvalidAlias"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        RunMode = "PlanOnly"
      }
    }
  }
)

# ============================================================================
# RUN TESTS
# ============================================================================

Run-Tests `
  -YamlPath "jobs/terraform_gated_deployment.yml" `
  -TransformYamlFunction { param($yaml) return $yaml -replace 'AzDOPipelineTemplates', 'self' } `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases
