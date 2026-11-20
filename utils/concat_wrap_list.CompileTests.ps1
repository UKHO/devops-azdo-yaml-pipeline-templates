$repoRoot = git rev-parse --show-toplevel
. (Join-Path $repoRoot "tests" "framework" "Core.ps1")

# Branch coverage (utils/concat_wrap_list.yml):
#   if Items is non-empty -> "several items" (entered)
#   else                  -> "with no Items" (entered)

$validTestCases = @(
  @{
    Description = "with no Items"
    Parameters = @{ }
    ExpectedYaml = @(
      "name: ConcatVariable*value: ''*readonly: true"
    )
  },
  @{
    Description = "with one item"
    Parameters = @{
      Items = @("alpha")
      Prefix = "<"
      Suffix = ">"
    }
    ExpectedYaml = @(
      "value: <alpha>"
    )
  },
  @{
    Description = "with several items, keeping their order"
    Parameters = @{
      Items = @("alpha", "beta", "gamma")
      Prefix = "-var-file="
      Suffix = " "
    }
    ExpectedYaml = @(
      "value: '-var-file=alpha -var-file=beta -var-file=gamma '"
    )
  },
  @{
    Description = "with custom OutputVariableName"
    Parameters = @{
      Items = @("alpha")
      OutputVariableName = "MyList"
    }
    ExpectedYaml = @(
      "name: MyList*value: alpha"
    )
  }
)

$invalidTestCases = @(
  @{
    Description = "OutputVariableName is empty"
    Parameters = @{
      Items = @("alpha")
      OutputVariableName = ""
    }
    ErrorMessage = "The 'OutputVariableName' parameter is not a valid String."
  }
)

# The template only declares variables, so a step is appended to make it a runnable pipeline.
Run-Tests `
  -YamlPath "utils/concat_wrap_list.yml" `
  -TransformYamlFunction { param($yaml) return $yaml + "`nsteps:`n  - script: echo concatenated`n" } `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases
