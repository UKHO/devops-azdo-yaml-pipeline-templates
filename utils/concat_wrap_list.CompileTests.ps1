# ============================================================================
# TEST: Concat Wrap List Utility Template
# ============================================================================
# Tests for utils/concat_wrap_list.yml.
# Includes generic concatenation scenarios and concrete patterns used by
# jobs/terraform_deploy.yml (VariableFilesCommandOption and BackendConfigCommandOption).

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
    Description = "with default parameters"
    Parameters = @{
      Items = @('A', 'B')
    }
    ExpectedYaml = @(
      'name: ConcatVariable'
      "value: AB"
      'readonly: true'
    )
  },
  @{
    Description = "with simple wrapped list"
    Parameters = @{
      Items = @('A', 'B')
      Prefix = '('
      Suffix = ')'
      OutputVariableName = 'MyResult'
    }
    ExpectedYaml = @(
      'name: MyResult'
      'value: (A)(B)'
      'readonly: true'
    )
  },
  @{
    Description = "with terraform variable files pattern from terraform_deploy"
    Parameters = @{
      Items = @('config/common.tfvars', 'config/prod.tfvars')
      Prefix = ' -var-file="$(TerraformWorkingDirectory)/'
      Suffix = '"'
      OutputVariableName = 'VariableFilesCommandOption'
    }
    ExpectedYaml = @(
      'name: VariableFilesCommandOption'
      'value: '' -var-file="$(TerraformWorkingDirectory)/config/common.tfvars" -var-file="$(TerraformWorkingDirectory)/config/prod.tfvars"'''
      'readonly: true'
    )
  },
  @{
    Description = "with terraform backend config pattern from terraform_deploy"
    Parameters = @{
      Items = @('resource_group_name=my-rg', 'storage_account_name=mysa')
      Prefix = ' -backend-config="'
      Suffix = '"'
      OutputVariableName = 'BackendConfigCommandOption'
    }
    ExpectedYaml = @(
      'name: BackendConfigCommandOption'
      'value: '' -backend-config="resource_group_name=my-rg" -backend-config="storage_account_name=mysa"'''
      'readonly: true'
    )
  }
)

$invalidTestCases = @(
  @{
    Description = "with invalid OutputVariableName type"
    Parameters = @{
      Items = @('A', 'B')
      OutputVariableName = @{ Name = 'NotAString' }
    }
    ErrorMessage = "Invalid Parameter: Field 'OutputVariableName' must be a string when provided."
  }
)

# ============================================================================
# RUN TESTS
# ============================================================================

Run-Tests `
  -YamlPath "utils/concat_wrap_list.yml" `
  -TransformYamlFunction { param($yaml) return $yaml + @"
steps:
 - script: echo `"Hello World`"
"@ } `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases

