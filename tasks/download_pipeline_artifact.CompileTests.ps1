$repoRoot = git rev-parse --show-toplevel
. (Join-Path $repoRoot "tests" "framework" "Core.ps1")

# Branch coverage (tasks/download_pipeline_artifact.yml): no conditional branches.

$validTestCases = @(
  @{
    Description = "with required parameters only"
    Parameters = @{
      ArtifactName = "WebApp"
    }
    ExpectedYaml = @(
      "- task: DownloadPipelineArtifact@2"
      "displayName: 'Download artifact: WebApp'"
      "buildType: 'current'"
      "artifactName: WebApp"
      "itemPattern: '**'"
      "targetPath: `$(Pipeline.Workspace)"
    )
  },
  @{
    Description = "with ItemPattern and TargetPath"
    Parameters = @{
      ArtifactName = "WebApp"
      ItemPattern = "**/*.zip"
      TargetPath = "downloads/webapp"
    }
    ExpectedYaml = @(
      "itemPattern: '**/*.zip'"
      "targetPath: downloads/webapp"
    )
  }
)

$invalidTestCases = @(
  @{
    Description = "missing ArtifactName"
    Parameters = @{ }
    ErrorMessage = "A value for the 'ArtifactName' parameter must be provided."
  }
)

Run-Tests `
  -YamlPath "tasks/download_pipeline_artifact.yml" `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases
