$repoRoot = git rev-parse --show-toplevel
. (Join-Path $repoRoot "tests" "framework" "Core.ps1")

# Branch coverage (tasks/file_transform.yml): no conditional branches.

$validTestCases = @(
  @{
    Description = "with required parameters only"
    Parameters = @{
      FolderPath = "drop/app.zip"
      JsonTargetFiles = "**/appsettings.json"
    }
    ExpectedYaml = @(
      "- task: FileTransform@2"
      "folderPath: drop/app.zip"
      "jsonTargetFiles: '**/appsettings.json'"
      "errorOnInvalidSubstitution: false"
    )
  },
  @{
    Description = "with ErrorOnInvalidSubstitution enabled"
    Parameters = @{
      FolderPath = "drop/app.zip"
      JsonTargetFiles = "**/appsettings.json"
      ErrorOnInvalidSubstitution = $true
    }
    ExpectedYaml = @(
      "errorOnInvalidSubstitution: true"
    )
  }
)

$invalidTestCases = @(
  @{
    Description = "missing FolderPath"
    Parameters = @{
      JsonTargetFiles = "**/appsettings.json"
    }
    ErrorMessage = "A value for the 'FolderPath' parameter must be provided."
  },
  @{
    Description = "missing JsonTargetFiles"
    Parameters = @{
      FolderPath = "drop/app.zip"
    }
    ErrorMessage = "A value for the 'JsonTargetFiles' parameter must be provided."
  }
)

Run-Tests `
  -YamlPath "tasks/file_transform.yml" `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases
