$repoRoot = git rev-parse --show-toplevel
. (Join-Path $repoRoot "tests" "framework" "Core.ps1")

# Branch coverage (tasks/manual_validation.yml):
#   if Approvers != ''     -> "with Approvers" (entered), "with default parameters" (not entered)
#   if Instructions != ''  -> "with Instructions" (entered), "with default parameters" (not entered)
# Note: the template declares a Condition parameter but does not apply it to the task.

$validTestCases = @(
  @{
    Description = "with default parameters"
    Parameters = @{ }
    ExpectedYaml = @(
      "- task: ManualValidation@1"
      "timeoutInMinutes: 60"
      "notifyUsers: ''"
      "allowApproversToApproveTheirOwnRuns: true"
      "onTimeout: reject"
    )
  },
  @{
    Description = "with Approvers"
    Parameters = @{
      Approvers = "lead@example.com"
    }
    ExpectedYaml = @(
      "approvers: lead@example.com"
    )
  },
  @{
    Description = "with Instructions"
    Parameters = @{
      Instructions = "Check the plan output."
    }
    ExpectedYaml = @(
      "instructions: *Check the plan output.*=== Pipeline Information ==="
    )
  },
  @{
    Description = "with all other parameters set"
    Parameters = @{
      NotifyUsers = "team@example.com"
      AllowApproversToApproveTheirOwnRuns = $false
      OnTimeoutBehaviour = "resume"
      TimeoutInMinutes = 1440
    }
    ExpectedYaml = @(
      "timeoutInMinutes: 1440"
      "notifyUsers: team@example.com"
      "allowApproversToApproveTheirOwnRuns: false"
      "onTimeout: resume"
    )
  }
)

$invalidTestCases = @(
  @{
    Description = "OnTimeoutBehaviour is not an allowed value"
    Parameters = @{
      OnTimeoutBehaviour = "wait"
    }
    ErrorMessage = "The 'OnTimeoutBehaviour' parameter value 'wait' is not a valid value."
  },
  @{
    Description = "TimeoutInMinutes is not a number"
    Parameters = @{
      TimeoutInMinutes = "an hour"
    }
    ErrorMessage = "The 'TimeoutInMinutes' parameter value 'an hour' is not a valid Number."
  }
)

# ManualValidation@1 only runs in an agentless job, so the steps are moved into a 'pool: server' job.
Run-Tests `
  -YamlPath "tasks/manual_validation.yml" `
  -TransformYamlFunction {
    param($yaml)
    $parts = $yaml -split '(?m)^steps:\s*$', 2
    $steps = ($parts[1] -split "`n" | ForEach-Object { "    $_" }) -join "`n"
    return $parts[0] + "jobs:`n  - job: ServerJob`n    pool: server`n    steps:" + $steps
  } `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases
