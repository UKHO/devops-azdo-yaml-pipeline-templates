# ============================================================================
# TEST: .NET BUILD CONFIG SCHEMA
# ============================================================================

# Load framework (only if not already loaded)
if (-not (Get-Command -Name 'Run-Tests' -ErrorAction SilentlyContinue))
{
  $repoRoot = git rev-parse --show-toplevel 2> $null
  . (Join-Path $repoRoot "tests" "framework" "Core.ps1")
}

$validTestCases = @(
  @{
    Description = "required parameters only (Zip)"
    Parameters = @{
      ArtifactName = "DotNetArtifact"
      DotNetBuildConfig = @{
        RelativePathToProject = "src/MyApi/MyApi.csproj"
        BuildOutputType = "Zip"
      }
    }
  },
  @{
    Description = "Zip with all optional parameters provided"
    Parameters = @{
      ArtifactName = "DotNetArtifact"
      DotNetBuildConfig = @{
        RelativePathToProject = "src/MyApi/MyApi.csproj"
        BuildOutputType = "Zip"
        BuildConfiguration = "Debug"
        DotNetVersion = "8.0.x"
        RunTests = $true
        TestProjects = "tests/MyApi.Tests/MyApi.Tests.csproj"
        PublishTestResults = $true
        PublishOutputDirectory = '$(Build.ArtifactStagingDirectory)/publish'
      }
    }
  },
  @{
    Description = "required parameters only (Container)"
    Parameters = @{
      ArtifactName = "DotNetImage"
      DotNetBuildConfig = @{
        RelativePathToProject = "src/MyApi/MyApi.csproj"
        BuildOutputType = "Container"
        ContainerRegistryServiceConnection = "MyAcrServiceConnection"
        ContainerRepository = "myregistry.azurecr.io/my-api"
      }
    }
  },
  @{
    Description = "Container with all optional parameters provided"
    Parameters = @{
      ArtifactName = "DotNetImage"
      DotNetBuildConfig = @{
        RelativePathToProject = "src/MyApi/MyApi.csproj"
        BuildOutputType = "Container"
        ContainerRegistryServiceConnection = "MyAcrServiceConnection"
        ContainerRepository = "myregistry.azurecr.io/my-api"
        Dockerfile = "src/MyApi/Dockerfile"
        BuildContext = "src/MyApi"
        ImageTags = "latest"
        RunTests = $false
      }
    }
  }
)

$invalidTestCases = @(
  @{
    Description = "missing ArtifactName parameter"
    Parameters = @{
      DotNetBuildConfig = @{
        RelativePathToProject = "src/MyApi/MyApi.csproj"
        BuildOutputType = "Zip"
      }
    }
    ErrorMessage = "A value for the 'ArtifactName' parameter must be provided."
  },
  @{
    Description = "missing DotNetBuildConfig parameter"
    Parameters = @{
      ArtifactName = "DotNetArtifact"
    }
    ErrorMessage = "A value for the 'DotNetBuildConfig' parameter must be provided."
  },
  @{
    Description = "missing RelativePathToProject"
    Parameters = @{
      ArtifactName = "DotNetArtifact"
      DotNetBuildConfig = @{
        BuildOutputType = "Zip"
      }
    }
    ErrorMessage = "RelativePathToProject is not properly defined and is a required field."
  },
  @{
    Description = "invalid BuildOutputType value"
    Parameters = @{
      ArtifactName = "DotNetArtifact"
      DotNetBuildConfig = @{
        RelativePathToProject = "src/MyApi/MyApi.csproj"
        BuildOutputType = "InvalidType"
      }
    }
    ErrorMessage = "Must provide a valid BuildOutputType option (Zip, Container)."
  },
  @{
    Description = "Container missing ContainerRegistryServiceConnection"
    Parameters = @{
      ArtifactName = "DotNetImage"
      DotNetBuildConfig = @{
        RelativePathToProject = "src/MyApi/MyApi.csproj"
        BuildOutputType = "Container"
        ContainerRepository = "myregistry.azurecr.io/my-api"
      }
    }
    ErrorMessage = "ContainerRegistryServiceConnection is required when BuildOutputType is 'Container'."
  },
  @{
    Description = "Container missing ContainerRepository"
    Parameters = @{
      ArtifactName = "DotNetImage"
      DotNetBuildConfig = @{
        RelativePathToProject = "src/MyApi/MyApi.csproj"
        BuildOutputType = "Container"
        ContainerRegistryServiceConnection = "MyAcrServiceConnection"
      }
    }
    ErrorMessage = "ContainerRepository is required when BuildOutputType is 'Container'."
  },
  @{
    Description = "RunTests is not a boolean value"
    Parameters = @{
      ArtifactName = "DotNetArtifact"
      DotNetBuildConfig = @{
        RelativePathToProject = "src/MyApi/MyApi.csproj"
        BuildOutputType = "Zip"
        RunTests = "yes"
      }
    }
    ErrorMessage = "RunTests must be a boolean value (true or false)."
  },
  @{
    Description = "PublishTestResults is not a boolean value"
    Parameters = @{
      ArtifactName = "DotNetArtifact"
      DotNetBuildConfig = @{
        RelativePathToProject = "src/MyApi/MyApi.csproj"
        BuildOutputType = "Zip"
        PublishTestResults = "yes"
      }
    }
    ErrorMessage = "PublishTestResults must be a boolean value (true or false)."
  }
)

Run-Tests `
  -YamlPath "schemas/dotnet_build_config.yml" `
  -TransformYamlFunction { param($yaml) return $yaml + @"
  - job:
    steps:
    - script: echo \"Hello World\"
"@ } `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases
