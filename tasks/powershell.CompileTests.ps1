$repoRoot = git rev-parse --show-toplevel
. (Join-Path $repoRoot "tests" "framework" "Core.ps1")

# Branch coverage (tasks/powershell.yml):
#   if TaskName != ''                               -> "with TaskName" (entered), "inline script" (not entered)
#   if TargetType == filePath and ScriptFilePath    -> "file script" (entered)
#   if TargetType == filePath and ScriptFileArguments -> "file script with arguments" (entered), "file script" (not entered)
#   if TargetType == inline and InlineScript        -> "inline script" (entered)
#   if WorkingDirectory != ''                       -> "with WorkingDirectory" (entered), "inline script" (not entered)

$validTestCases = @(
  @{
    Description = "inline script"
    Parameters = @{
      TargetType = "inline"
      InlineScript = "Write-Host 'Hello'"
    }
    ExpectedYaml = @(
      "- task: PowerShell@2"
      "targetType: inline"
      "script: Write-Host 'Hello'"
      "failOnStderr: false"
      "pwsh: false"
    )
  },
  @{
    Description = "file script"
    Parameters = @{
      TargetType = "filePath"
      ScriptFilePath = "scripts/run.ps1"
    }
    ExpectedYaml = @(
      "targetType: filePath"
      "filePath: scripts/run.ps1"
    )
  },
  @{
    Description = "file script with arguments"
    Parameters = @{
      TargetType = "filePath"
      ScriptFilePath = "scripts/run.ps1"
      ScriptFileArguments = "-Environment dev"
    }
    ExpectedYaml = @(
      "arguments: -Environment dev"
    )
  },
  @{
    Description = "with TaskName"
    Parameters = @{
      TargetType = "inline"
      InlineScript = "Write-Host 'Hello'"
      TaskName = "SetVersion"
    }
    ExpectedYaml = @(
      "name: SetVersion"
      "displayName: PowerShell SetVersion"
    )
  },
  @{
    Description = "with WorkingDirectory"
    Parameters = @{
      TargetType = "inline"
      InlineScript = "Write-Host 'Hello'"
      WorkingDirectory = "src"
    }
    ExpectedYaml = @(
      "workingDirectory: src"
    )
  },
  @{
    Description = "with TaskEnvironmentVariables"
    Parameters = @{
      TargetType = "inline"
      InlineScript = "Write-Host `$env:MY_VAR"
      TaskEnvironmentVariables = @{
        MY_VAR = "my-value"
      }
    }
    ExpectedYaml = @(
      "env:*MY_VAR: my-value"
    )
  },
  @{
    Description = "with FailOnStandardError and UsePowerShellCoreOnWindows enabled"
    Parameters = @{
      TargetType = "inline"
      InlineScript = "Write-Host 'Hello'"
      FailOnStandardError = $true
      UsePowerShellCoreOnWindows = $true
    }
    ExpectedYaml = @(
      "failOnStderr: true"
      "pwsh: true"
    )
  }
)

$invalidTestCases = @(
  @{
    Description = "missing TargetType"
    Parameters = @{
      InlineScript = "Write-Host 'Hello'"
    }
    ErrorMessage = "A value for the 'TargetType' parameter must be provided."
  },
  @{
    Description = "TargetType is not an allowed value"
    Parameters = @{
      TargetType = "command"
    }
    ErrorMessage = "The 'TargetType' parameter value 'command' is not a valid value."
  }
)

Run-Tests `
  -YamlPath "tasks/powershell.yml" `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases
