$repoRoot = git rev-parse --show-toplevel
. (Join-Path $repoRoot "tests" "framework" "Core.ps1")

# Branch coverage (tasks/delay.yml): no conditional branches.

$validTestCases = @(
  @{
    Description = "with default delay"
    Parameters = @{ }
    ExpectedYaml = @(
      "- task: Delay@1"
      "displayName: Delay for 0 minutes"
      "delayForMinutes: '0'"
    )
  },
  @{
    Description = "with custom delayForMinutes"
    Parameters = @{
      delayForMinutes = 5
    }
    ExpectedYaml = @(
      "displayName: Delay for 5 minutes"
      "delayForMinutes: 5"
    )
  }
)

$invalidTestCases = @(
  @{
    Description = "delayForMinutes is not a number"
    Parameters = @{
      delayForMinutes = "five"
    }
    ErrorMessage = "The 'delayForMinutes' parameter value 'five' is not a valid Number."
  }
)

# Delay@1 only runs in an agentless job, so the steps are moved into a 'pool: server' job.
Run-Tests `
  -YamlPath "tasks/delay.yml" `
  -TransformYamlFunction {
    param($yaml)
    $parts = $yaml -split '(?m)^steps:\s*$', 2
    $steps = ($parts[1] -split "`n" | ForEach-Object { "    $_" }) -join "`n"
    return $parts[0] + "jobs:`n  - job: ServerJob`n    pool: server`n    steps:" + $steps
  } `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases
