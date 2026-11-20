$repoRoot = git rev-parse --show-toplevel
. (Join-Path $repoRoot "tests" "framework" "Core.ps1")

# Branch coverage (tasks/publish_pipeline_artifact.yml): no conditional branches.

$validTestCases = @(
  @{
    Description = "with required parameters only"
    Parameters = @{
      TargetPath = "drop"
    }
    ExpectedYaml = @(
      "- task: PublishPipelineArtifact@1"
      "displayName: 'Publish Pipeline Artifact: Drop'"
      "artifact: Drop"
      "targetPath: drop"
      "publishLocation: 'pipeline'"
    )
  },
  @{
    Description = "with custom ArtifactName"
    Parameters = @{
      ArtifactName = "MyArtifact"
      TargetPath = "drop"
    }
    ExpectedYaml = @(
      "displayName: 'Publish Pipeline Artifact: MyArtifact'"
      "artifact: MyArtifact"
    )
  }
)

$invalidTestCases = @(
  @{
    Description = "missing TargetPath"
    Parameters = @{ }
    ErrorMessage = "A value for the 'TargetPath' parameter must be provided."
  }
)

Run-Tests `
  -YamlPath "tasks/publish_pipeline_artifact.yml" `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases
