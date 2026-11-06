$repoRoot = git rev-parse --show-toplevel
. (Join-Path $repoRoot "tests" "framework" "Core.ps1")

# Branch coverage (tasks/copy_files.yml):
#   if SourceFolder != ''  -> "with SourceFolder" (entered), "with required parameters only" (not entered)

$validTestCases = @(
  @{
    Description = "with required parameters only"
    Parameters = @{
      FilesPattern = "**/*.json"
      TargetFolder = "drop"
    }
    ExpectedYaml = @(
      "- task: CopyFiles@2"
      "displayName: 'Copy files to: drop'"
      "Contents: '**/*.json'"
      "TargetFolder: drop"
      "CleanTargetFolder: false"
      "OverWrite: false"
      "flattenFolders: false"
      "preserveTimestamp: false"
    )
  },
  @{
    Description = "with SourceFolder"
    Parameters = @{
      SourceFolder = "config"
      FilesPattern = "**/*.json"
      TargetFolder = "drop"
    }
    ExpectedYaml = @(
      "SourceFolder: config"
    )
  },
  @{
    Description = "with all boolean options enabled"
    Parameters = @{
      FilesPattern = "**/*.json"
      TargetFolder = "drop"
      CleanTargetFolder = $true
      OverWrite = $true
      FlattenFolders = $true
      PreserveTimestamp = $true
    }
    ExpectedYaml = @(
      "CleanTargetFolder: true"
      "OverWrite: true"
      "flattenFolders: true"
      "preserveTimestamp: true"
    )
  }
)

$invalidTestCases = @(
  @{
    Description = "missing FilesPattern"
    Parameters = @{
      TargetFolder = "drop"
    }
    ErrorMessage = "A value for the 'FilesPattern' parameter must be provided."
  },
  @{
    Description = "missing TargetFolder"
    Parameters = @{
      FilesPattern = "**/*.json"
    }
    ErrorMessage = "A value for the 'TargetFolder' parameter must be provided."
  }
)

Run-Tests `
  -YamlPath "tasks/copy_files.yml" `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases
