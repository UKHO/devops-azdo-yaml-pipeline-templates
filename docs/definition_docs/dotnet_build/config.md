# DotNetBuildConfig

| Field | Contract |
|---|---|
| `RelativePathToSolution` | Required repository-relative path to the solution or SDK project. Use an SDK that supports the chosen file type. |
| `BuildConfiguration` | Defaults to `Release`; used for restore, compile, tests and packaging. |
| `DotNetSdk.Version` | Exact SDK version. Omit to resolve via the repository-root `global.json`. |
| `DotNetSdk.Install` | Boolean, default `true`; `false` verifies the agent's resolved SDK instead of installing. |
| `ConfigSources` | Optional [shared config sources](../shared/config_sources.md), loaded before NuGet authentication. |
| `Restore.NuGetConfigPath` | Optional repository-relative file. |
| `Restore.UseLockedMode` | Boolean, default `false`. Requires committed lock files when enabled. |
| `Packages` | Optional list. Each entry requires `Type` (`Publish` or `NuGet`) and `Project` (an SDK project compiled by the mandatory build). `Name` defaults to the project filename without extension. `ZipAfterPublish` is a boolean defaulting to `true`, valid only for `Publish`. |

Package names must be unique ignoring case. Paths must not be absolute or traverse parent directories. The prototype does not accept arbitrary CLI arguments, binary logs, runtime overrides, container packages or external delivery targets. `Destinations` is separate from `DotNetBuildConfig`; it accepts zero or one `{ Type: PipelineArtifact, Name: <optional label> }` entry and publishes all configured packages.
