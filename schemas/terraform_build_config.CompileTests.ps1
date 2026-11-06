# ============================================================================
# TEST: Terraform Build Config Schema
# ============================================================================
# Validation tests for the TerraformBuildConfig object accepted by jobs/terraform_build.yml:
# its fields, the Checks list (shape and each entry's 'Check' and 'Name'), and the rule that a field
# can't be set both in the config and through its deprecated top-level job parameter.
# Each check's own settings are tested by its check template (for example
# checks/terraformformat.CompileTests.ps1).

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
  # --- Whole object --------------------------------------------------------
  @{
    Description = "with no parameters (empty config)"
    Parameters = @{ }
  },
  @{
    Description = "with every field"
    Parameters = @{
      TerraformBuildConfig = @"
ArtifactName: MyArtifact
TerraformVersion: 1.13.0
RelativePathToTerraformFiles: infra
AdditionalFilesToPackage:
  - SourceDirectory: config
    FilesPattern: '*.tfvars'
    TargetSubdirectoryName: configs
InjectionSteps:
  - script: echo hello
Checks:
  - Check: TerraformFormat
"@
    }
  },
  @{
    Description = "with an AdditionalFilesToPackage entry without TargetSubdirectoryName"
    Parameters = @{
      TerraformBuildConfig = @"
AdditionalFilesToPackage:
  - SourceDirectory: config
    FilesPattern: '*.tfvars'
"@
    }
  },
  @{
    Description = "with a deprecated parameter and a different config field"
    Parameters = @{
      DeprecatedArtifactName = 'OldStyle'
      TerraformBuildConfig = "RelativePathToTerraformFiles: infra"
    }
  },

  # --- Checks --------------------------------------------------------------
  @{
    Description = "with a single TerraformFormat entry"
    Parameters = @{
      TerraformBuildConfig = @"
Checks:
  - Check: TerraformFormat
"@
    }
  },
  @{
    Description = "with a TerraformFormat entry and its settings"
    Parameters = @{
      TerraformBuildConfig = @"
Checks:
  - Check: TerraformFormat
    Name: Modules
    Recursive: false
    TreatAsWarnings: true
"@
    }
  },
  @{
    Description = "with TerraformFormat listed twice with different Names"
    Parameters = @{
      TerraformBuildConfig = @"
Checks:
  - Check: TerraformFormat
    Name: Root
  - Check: TerraformFormat
    Name: Modules
"@
    }
  },
  @{
    Description = "with TerraformFormat and SnykIac together (different checks need no Name)"
    Parameters = @{
      TerraformBuildConfig = @"
Checks:
  - Check: TerraformFormat
  - Check: SnykIac
    ServiceConnection: Snyk
    Organization: my-team
"@
    }
  }
)

$invalidTestCases = @(
  # --- Whole object --------------------------------------------------------
  @{
    Description = "with a list instead of an object"
    Parameters = @{
      TerraformBuildConfig = "- RelativePathToTerraformFiles: infra"
    }
    ErrorMessage = "Invalid TerraformBuildConfig: must be an object"
  },
  @{
    Description = "with an unknown field (misspelled)"
    Parameters = @{
      TerraformBuildConfig = "RelativePathToTerraformFile: infra"
    }
    ErrorMessage = "Invalid TerraformBuildConfig: unknown field 'RelativePathToTerraformFile'."
  },
  @{
    Description = "with the deprecated name TerraformBuildInjectionSteps inside the config"
    Parameters = @{
      TerraformBuildConfig = @"
TerraformBuildInjectionSteps:
  - script: echo hello
"@
    }
    ErrorMessage = "Invalid TerraformBuildConfig: unknown field 'TerraformBuildInjectionSteps'."
  },
  @{
    Description = "with an empty ArtifactName"
    Parameters = @{
      TerraformBuildConfig = "ArtifactName: ''"
    }
    ErrorMessage = "Invalid TerraformBuildConfig: 'ArtifactName' must be a non-empty string when provided."
  },
  @{
    Description = "with RelativePathToTerraformFiles as a list"
    Parameters = @{
      TerraformBuildConfig = @"
RelativePathToTerraformFiles:
  - infra
"@
    }
    ErrorMessage = "Invalid TerraformBuildConfig: 'RelativePathToTerraformFiles' must be a non-empty string when provided."
  },

  # --- AdditionalFilesToPackage -------------------------------------------
  @{
    Description = "with AdditionalFilesToPackage as an object"
    Parameters = @{
      TerraformBuildConfig = @"
AdditionalFilesToPackage:
  SourceDirectory: config
  FilesPattern: '*.tfvars'
"@
    }
    ErrorMessage = "Invalid TerraformBuildConfig: 'AdditionalFilesToPackage' must be a list of objects"
  },
  @{
    Description = "with an AdditionalFilesToPackage entry missing SourceDirectory"
    Parameters = @{
      TerraformBuildConfig = @"
AdditionalFilesToPackage:
  - FilesPattern: '*.tfvars'
"@
    }
    ErrorMessage = "missing required field 'SourceDirectory'"
  },
  @{
    Description = "with an AdditionalFilesToPackage entry missing FilesPattern"
    Parameters = @{
      TerraformBuildConfig = @"
AdditionalFilesToPackage:
  - SourceDirectory: config
"@
    }
    ErrorMessage = "missing required field 'FilesPattern'"
  },
  @{
    Description = "with an unknown AdditionalFilesToPackage field"
    Parameters = @{
      TerraformBuildConfig = @"
AdditionalFilesToPackage:
  - SourceDirectory: config
    FilesPattern: '*.tfvars'
    TargetSubdirectory: configs
"@
    }
    ErrorMessage = "unknown 'AdditionalFilesToPackage' field 'TargetSubdirectory'"
  },

  # --- InjectionSteps ------------------------------------------------------
  @{
    Description = "with InjectionSteps as a single step object"
    Parameters = @{
      TerraformBuildConfig = @"
InjectionSteps:
  script: echo hello
"@
    }
    ErrorMessage = "Invalid TerraformBuildConfig: 'InjectionSteps' must be a list of steps."
  },

  # --- Checks --------------------------------------------------------------
  @{
    Description = "with Checks as a string instead of a list"
    Parameters = @{
      TerraformBuildConfig = "Checks: TerraformFormat"
    }
    ErrorMessage = "Invalid TerraformBuildConfig.Checks: must be a list of check objects"
  },
  @{
    Description = "with a Checks entry that is a string, not an object"
    Parameters = @{
      TerraformBuildConfig = @"
Checks:
  - TerraformFormat
"@
    }
    ErrorMessage = "Invalid TerraformBuildConfig.Checks: each entry must be an object with a 'Check' field"
  },
  @{
    Description = "with a Checks entry missing the Check field"
    Parameters = @{
      TerraformBuildConfig = @"
Checks:
  - Name: Modules
"@
    }
    ErrorMessage = "Invalid TerraformBuildConfig.Checks: entry is missing required string field 'Check'."
  },
  @{
    Description = "with an empty Check field"
    Parameters = @{
      TerraformBuildConfig = @"
Checks:
  - Check: ''
"@
    }
    ErrorMessage = "Invalid TerraformBuildConfig.Checks: entry is missing required string field 'Check'."
  },
  @{
    Description = "with a Check field that is a list"
    Parameters = @{
      TerraformBuildConfig = @"
Checks:
  - Check:
      - TerraformFormat
"@
    }
    ErrorMessage = "Invalid TerraformBuildConfig.Checks: entry is missing required string field 'Check'."
  },
  @{
    Description = "with an unsupported check"
    Parameters = @{
      TerraformBuildConfig = @"
Checks:
  - Check: TFLint
"@
    }
    ErrorMessage = "Invalid TerraformBuildConfig.Checks: 'TFLint' is not a supported check for terraform_build. Supported: TerraformFormat, SnykIac."
  },
  @{
    Description = "with a path-like Check value"
    Parameters = @{
      TerraformBuildConfig = @"
Checks:
  - Check: ../tasks/terraform
"@
    }
    ErrorMessage = "Invalid TerraformBuildConfig.Checks: '../tasks/terraform' is not a supported check for terraform_build."
  },
  @{
    Description = "with an empty check Name"
    Parameters = @{
      TerraformBuildConfig = @"
Checks:
  - Check: TerraformFormat
    Name: ''
"@
    }
    ErrorMessage = "Invalid TerraformBuildConfig.Checks: 'Name' must be a non-empty string when provided."
  },
  @{
    Description = "with TerraformFormat listed twice and one Name missing"
    Parameters = @{
      TerraformBuildConfig = @"
Checks:
  - Check: TerraformFormat
  - Check: TerraformFormat
    Name: Modules
"@
    }
    ErrorMessage = "Invalid TerraformBuildConfig.Checks: 'TerraformFormat' is listed more than once, so every 'TerraformFormat' entry needs a unique 'Name'."
  },
  @{
    Description = "with TerraformFormat listed twice with different settings and no Names"
    Parameters = @{
      TerraformBuildConfig = @"
Checks:
  - Check: TerraformFormat
  - Check: TerraformFormat
    Recursive: false
"@
    }
    ErrorMessage = "Invalid TerraformBuildConfig.Checks: 'TerraformFormat' is listed more than once, so every 'TerraformFormat' entry needs a unique 'Name'."
  },

  # --- Deprecated parameters set as well -----------------------------------
  @{
    Description = "with ArtifactName set both ways"
    Parameters = @{
      DeprecatedArtifactName = 'OldStyle'
      TerraformBuildConfig = "ArtifactName: NewStyle"
    }
    ErrorMessage = "use either 'ArtifactName' (deprecated) or 'TerraformBuildConfig.ArtifactName', not both."
  },
  @{
    Description = "with TerraformVersion set both ways"
    Parameters = @{
      DeprecatedTerraformVersion = '1.13.0'
      TerraformBuildConfig = "TerraformVersion: 1.12.0"
    }
    ErrorMessage = "use either 'TerraformVersion' (deprecated) or 'TerraformBuildConfig.TerraformVersion', not both."
  },
  @{
    Description = "with RelativePathToTerraformFiles set both ways"
    Parameters = @{
      DeprecatedRelativePathToTerraformFiles = 'old'
      TerraformBuildConfig = "RelativePathToTerraformFiles: new"
    }
    ErrorMessage = "use either 'RelativePathToTerraformFiles' (deprecated) or 'TerraformBuildConfig.RelativePathToTerraformFiles', not both."
  },
  @{
    Description = "with AdditionalFilesToPackage set both ways"
    Parameters = @{
      DeprecatedAdditionalFilesToPackage = @"
- SourceDirectory: old
  FilesPattern: '*'
"@
      TerraformBuildConfig = @"
AdditionalFilesToPackage:
  - SourceDirectory: new
    FilesPattern: '*'
"@
    }
    ErrorMessage = "use either 'AdditionalFilesToPackage' (deprecated) or 'TerraformBuildConfig.AdditionalFilesToPackage', not both."
  },
  @{
    Description = "with injection steps set both ways"
    Parameters = @{
      DeprecatedTerraformBuildInjectionSteps = @"
- script: echo old
"@
      TerraformBuildConfig = @"
InjectionSteps:
  - script: echo new
"@
    }
    ErrorMessage = "use either 'TerraformBuildInjectionSteps' (deprecated) or 'TerraformBuildConfig.InjectionSteps', not both."
  }
)

# ============================================================================
# RUN TESTS
# ============================================================================

Run-Tests `
  -YamlPath "schemas/terraform_build_config.yml" `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases
