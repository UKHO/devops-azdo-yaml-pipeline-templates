# Azure DevOps Pipeline: Double Checkout Pathing Issues

When using the `checkout` task multiple times within a single job in Azure DevOps YAML pipelines, you may encounter unexpected pathing behaviour. By default, a single `checkout` task places files in the `Pipeline.Workspace`. However, introducing a second `checkout` task, even for the same repository, changes the behaviour: the first checkout now uses a subdirectory named after the repository.

## Common Scenario

For example, in a `TerraformBuild` job, you might:

- Use the first `checkout` to retrieve repository files and validate them.
- Run validation steps that generate unwanted files.
- Use a second `checkout` to clean the workspace and restore a pristine copy of the repository.

This double-checkout pattern causes the first checkout to use a path like `$(Pipeline.Workspace)/$(Build.Repository.Name)`, which can break references to files if your steps expect the default workspace path.

## Solution

To avoid pathing issues:

- Explicitly set the `path` property for all `checkout` tasks to `$(Build.Repository.Name)`.
- Update all job variables and step references to use this path.

---

*This document was moved from `docs/` to `docs/developers/` for troubleshooting and advanced topics reference. See the developer documentation index for more details.*
