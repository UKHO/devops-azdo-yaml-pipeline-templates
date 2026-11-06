# ============================================================================
# TEST: Terraform Build Job Template
# ============================================================================
# This test verifies the terraform_build job template with different parameter combinations.
#
# Tests cover:
# - TerraformBuildConfig: artifact name, Terraform version, path, injection steps, additional files
# - Checks (TerraformFormat, SnykIac): order, settings pass-through, duplicates and rejected input
# - Deprecated top-level parameters: still work, log a warning, and can't be combined with the config
# - Job orchestration: Condition, DependsOn, Pool
#
# Field-level validation of TerraformBuildConfig is covered in schemas/terraform_build_config.CompileTests.ps1.

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
  # --- Defaults ------------------------------------------------------------
  @{
    Description = "with default parameters"
    Parameters = @{ }
    ExpectedYaml = @(
      'job: TerraformBuild_TerraformArtifact',
      "displayName:*Build 'TerraformArtifact' Terraform Artifact",
      'artifact:*TerraformArtifact',
      'inputs:*TerraformVersion:**1.14.0',
      'value: $(RepositoryDirectory)/',
      'terraform init -backend=false',
      'terraform validate'
    )
  },

  # --- TerraformBuildConfig ------------------------------------------------
  @{
    Description = "TerraformBuildConfig.ArtifactName names the job and artifact"
    Parameters = @{
      TerraformBuildConfig = "ArtifactName: CustomTerraformArtifact"
    }
    ExpectedYaml = @(
      'job: TerraformBuild_CustomTerraformArtifact',
      "displayName:*Build 'CustomTerraformArtifact' Terraform Artifact",
      'artifact:*CustomTerraformArtifact'
    )
  },
  @{
    Description = "TerraformBuildConfig.TerraformVersion is passed to the installer"
    Parameters = @{
      TerraformBuildConfig = "TerraformVersion: latest"
    }
    ExpectedYaml = @(
      'inputs:*TerraformVersion:**latest'
    )
  },
  @{
    Description = "TerraformBuildConfig.RelativePathToTerraformFiles sets the working directory"
    Parameters = @{
      TerraformBuildConfig = "RelativePathToTerraformFiles: terraform/production"
    }
    ExpectedYaml = @(
      'value: $(RepositoryDirectory)/terraform/production'
    )
  },
  @{
    Description = "TerraformBuildConfig.InjectionSteps run before init"
    Parameters = @{
      TerraformBuildConfig = @"
InjectionSteps:
  - script: echo "Step 1"
    displayName: Pre-build step 1
  - script: echo "Step 2"
    displayName: Pre-build step 2
"@
    }
    ExpectedYaml = @(
      'Pre-build step 1*Pre-build step 2*terraform init',
      'echo "Step 1"'
    )
  },
  @{
    Description = "TerraformBuildConfig.AdditionalFilesToPackage copies each entry"
    Parameters = @{
      TerraformBuildConfig = @"
AdditionalFilesToPackage:
  - FilesPattern: '**'
    SourceDirectory: resources/keyvault
    TargetSubdirectoryName: newresourcedirectoryone
  - FilesPattern: '**'
    SourceDirectory: resources/storageaccount
"@
    }
    ExpectedYaml = @(
      'CopyFiles@2',
      'resources/keyvault',
      'newresourcedirectoryone',
      'resources/storageaccount'
    )
  },
  @{
    Description = "TerraformBuildConfig with every field logs no deprecation warning"
    Parameters = @{
      TerraformBuildConfig = @"
ArtifactName: Everything
TerraformVersion: 1.13.0
RelativePathToTerraformFiles: infra
AdditionalFilesToPackage:
  - SourceDirectory: scripts
    FilesPattern: '**'
InjectionSteps:
  - script: echo hi
Checks:
  - Check: TerraformFormat
"@
    }
    ExpectedYaml = @(
      'job: TerraformBuild_Everything',
      'inputs:*TerraformVersion:**1.13.0',
      'value: $(RepositoryDirectory)/infra'
    )
    UnexpectedYaml = @(
      'DeprecatedParametersWarning'
    )
  },

  # --- Checks --------------------------------------------------------------
  @{
    Description = "Checks with TerraformFormat run after validate and before packaging"
    Parameters = @{
      TerraformBuildConfig = @"
Checks:
  - Check: TerraformFormat
"@
    }
    ExpectedYaml = @(
      'name: TerraformTask_validate*name: TerraformTask_fmt*RemoveTerraformDirectory',
      'terraform fmt -check -diff -recursive'
    )
  },
  @{
    Description = "Checks settings are passed through to the check"
    Parameters = @{
      TerraformBuildConfig = @"
Checks:
  - Check: TerraformFormat
    Name: Modules
    Recursive: false
    TreatAsWarnings: true
"@
    }
    ExpectedYaml = @(
      'name: TerraformTask_fmt_Modules',
      'continueOnError: true'
    )
  },
  @{
    Description = "Checks with TerraformFormat listed twice with different Names"
    Parameters = @{
      TerraformBuildConfig = @"
Checks:
  - Check: TerraformFormat
    Name: Root
    Recursive: false
  - Check: TerraformFormat
    Name: All
"@
    }
    ExpectedYaml = @(
      'name: TerraformTask_fmt_Root*name: TerraformTask_fmt_All'
    )
  },
  @{
    Description = "Checks with SnykIac scans the Terraform working directory after validate"
    Parameters = @{
      TerraformBuildConfig = @"
Checks:
  - Check: SnykIac
    ServiceConnection: Snyk
    Organization: my-team
"@
    }
    ExpectedYaml = @(
      'name: TerraformTask_validate*task: UkhoSnykScanTask@0*RemoveTerraformDirectory',
      'testType: iac',
      'testDirectory: $(TerraformWorkingDirectory)',
      'reportFileName: snyk-iac'
    )
  },
  @{
    Description = "Checks with SnykIac listed twice with different Names"
    Parameters = @{
      TerraformBuildConfig = @"
Checks:
  - Check: SnykIac
    Name: All
    ServiceConnection: Snyk
    Organization: my-team
  - Check: SnykIac
    Name: HighOnly
    ServiceConnection: Snyk
    Organization: my-team
    SeverityThreshold: high
    TreatAsWarnings: true
"@
    }
    ExpectedYaml = @(
      'name: SnykScanTask_iac_All*name: SnykScanTask_iac_HighOnly',
      'reportFileName: snyk-iac-HighOnly',
      'severityThreshold: high'
    )
  },

  # --- Deprecated top-level parameters (backwards compatibility) ----------
  @{
    Description = "deprecated ArtifactName still works and logs a warning"
    Parameters = @{
      ArtifactName = 'LegacyArtifact'
    }
    ExpectedYaml = @(
      'job: TerraformBuild_LegacyArtifact',
      'artifact:*LegacyArtifact',
      "DeprecatedParametersWarning*'ArtifactName' is deprecated. Use 'TerraformBuildConfig.ArtifactName' instead."
    )
  },
  @{
    Description = "deprecated TerraformVersion still works and logs a warning"
    Parameters = @{
      TerraformVersion = '1.15.0'
    }
    ExpectedYaml = @(
      'inputs:*TerraformVersion:**1.15.0',
      "'TerraformVersion' is deprecated. Use 'TerraformBuildConfig.TerraformVersion' instead."
    )
  },
  @{
    Description = "deprecated RelativePathToTerraformFiles still works and logs a warning"
    Parameters = @{
      RelativePathToTerraformFiles = 'terraform/production'
    }
    ExpectedYaml = @(
      'value: $(RepositoryDirectory)/terraform/production',
      "'RelativePathToTerraformFiles' is deprecated. Use 'TerraformBuildConfig.RelativePathToTerraformFiles' instead."
    )
  },
  @{
    Description = "deprecated TerraformBuildInjectionSteps still work and log a warning"
    Parameters = @{
      TerraformBuildInjectionSteps = @"
- script: echo "Pre-build step"
  displayName: Run pre-build validation
"@
    }
    ExpectedYaml = @(
      'Run pre-build validation*terraform init',
      "'TerraformBuildInjectionSteps' is deprecated. Use 'TerraformBuildConfig.InjectionSteps' instead."
    )
  },
  @{
    Description = "deprecated AdditionalFilesToPackage still work and log a warning"
    Parameters = @{
      AdditionalFilesToPackage = @"
- FilesPattern: '**'
  SourceDirectory: resources/keyvault
  TargetSubdirectoryName: keyvault
"@
    }
    ExpectedYaml = @(
      'CopyFiles@2',
      'resources/keyvault',
      "'AdditionalFilesToPackage' is deprecated. Use 'TerraformBuildConfig.AdditionalFilesToPackage' instead."
    )
  },
  @{
    Description = "deprecated parameter alongside a different TerraformBuildConfig field"
    Parameters = @{
      ArtifactName = 'LegacyArtifact'
      TerraformBuildConfig = @"
Checks:
  - Check: TerraformFormat
"@
    }
    ExpectedYaml = @(
      'job: TerraformBuild_LegacyArtifact',
      'name: TerraformTask_fmt',
      "'ArtifactName' is deprecated."
    )
  },

  # --- Job orchestration ---------------------------------------------------
  @{
    Description = "Condition is applied to the job"
    Parameters = @{
      Condition = "and(succeeded(), eq(variables.IsPullRequest, 'true'))"
    }
    ExpectedYaml = @(
      "condition: and(succeeded(), eq(variables.IsPullRequest, 'true'))"
    )
  },
  @{
    Description = "DependsOn is applied to the job"
    Parameters = @{
      DependsOn = @("PreviousJob")
    }
    ExpectedYaml = @(
      'dependsOn:*- PreviousJob'
    )
  },
  @{
    Description = "Pool is applied to the job"
    Parameters = @{
      Pool = "Custom-Agent-Pool"
    }
    ExpectedYaml = @(
      'pool:*name: Custom-Agent-Pool'
    )
  }
)

$invalidTestCases = @(
  @{
    Description = "with an invalid TerraformBuildConfig.TerraformVersion"
    Parameters = @{
      TerraformBuildConfig = "TerraformVersion: 1.0.x"
    }
    ErrorMessage = "terraform_installer' task error: TerraformVersion is not properly defined."
  },
  @{
    Description = "with an unknown TerraformBuildConfig field"
    Parameters = @{
      TerraformBuildConfig = "Checkz: []"
    }
    ErrorMessage = "Invalid TerraformBuildConfig: unknown field 'Checkz'."
  },
  @{
    Description = "with the top-level Checks parameter (only supported inside TerraformBuildConfig)"
    Parameters = @{
      Checks = @"
- Check: TerraformFormat
"@
    }
    ErrorMessage = "Checks"
  },
  @{
    Description = "with a field set both in TerraformBuildConfig and as a deprecated parameter"
    Parameters = @{
      RelativePathToTerraformFiles = 'old'
      TerraformBuildConfig = "RelativePathToTerraformFiles: new"
    }
    ErrorMessage = "use either 'RelativePathToTerraformFiles' (deprecated) or 'TerraformBuildConfig.RelativePathToTerraformFiles', not both."
  },
  @{
    Description = "with an invalid deprecated TerraformBuildInjectionSteps parameter"
    Parameters = @{
      TerraformBuildInjectionSteps = "junk"
    }
    ErrorMessage = "The 'TerraformBuildInjectionSteps' parameter is not a valid StepList."
  },
  @{
    Description = "Checks with an unsupported check"
    Parameters = @{
      TerraformBuildConfig = @"
Checks:
  - Check: TFLint
"@
    }
    ErrorMessage = "Invalid TerraformBuildConfig.Checks: 'TFLint' is not a supported check for terraform_build. Supported: TerraformFormat, SnykIac."
  },
  @{
    # Without a guard in the job, this builds the path /checks/../tasks/terraform.yml; the schema error must still fail the compile.
    Description = "Checks with a path-like check name"
    Parameters = @{
      TerraformBuildConfig = @"
Checks:
  - Check: ../tasks/terraform
"@
    }
    ErrorMessage = "Invalid TerraformBuildConfig.Checks: '../tasks/terraform' is not a supported check for terraform_build."
  },
  @{
    Description = "Checks with a misspelled TerraformFormat setting"
    Parameters = @{
      TerraformBuildConfig = @"
Checks:
  - Check: TerraformFormat
    Recursiv: false
"@
    }
    ErrorMessage = "Recursiv"
  },
  @{
    Description = "Checks that try to override the job-supplied WorkingDirectory"
    Parameters = @{
      TerraformBuildConfig = @"
Checks:
  - Check: TerraformFormat
    WorkingDirectory: somewhere/else
"@
    }
    ErrorMessage = "WorkingDirectory"
  },
  @{
    Description = "Checks with SnykIac missing its required Organization"
    Parameters = @{
      TerraformBuildConfig = @"
Checks:
  - Check: SnykIac
    ServiceConnection: Snyk
"@
    }
    ErrorMessage = "A value for the 'Organization' parameter must be provided."
  }
)

# ============================================================================
# RUN TESTS
# ============================================================================

# PreviousJob is appended so that cases can set DependsOn to an existing job
Run-Tests `
  -YamlPath "jobs/terraform_build.yml" `
  -TransformYamlFunction { param($yaml) return $yaml + "`n  - job: PreviousJob`n    steps:`n      - script: echo PreviousJob`n" } `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases
