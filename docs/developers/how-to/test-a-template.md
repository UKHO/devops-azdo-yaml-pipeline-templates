# Test a Template

> **Note:** The testing story for this repository is evolving. The long-term goal is to provision dedicated Azure DevOps pipelines via Terraform so that templates can be validated automatically.

## Environment Setup

- Use an IDE with YAML support configured to follow `.editorconfig`.
- 2-space indentation and no tabs are critical formatting standards.

## Running the Compile/Test Framework

```powershell
# From the repository root, in PowerShell
$repoRoot = git rev-parse --show-toplevel
. (Join-Path $repoRoot "tests" "framework" "Core.ps1")

# Run all job template compile tests
Run-DirectoryCompileTests -DirectoryPath "tests/jobs"

# Run all pipeline template compile tests
Run-DirectoryCompileTests -DirectoryPath "tests/pipelines"
```

- For Terraform templates, use mock providers where available.
- Document any testing limitations or manual verification steps in the Pull Request description.
- There are no other local testing tools; beyond the compile/test framework above, validation is done by running pipelines in Azure DevOps.

## Pull Request Process

1. Create a **draft PR** early for initial feedback.
2. Submit code PRs and documentation PRs separately; link them in the description.
3. Use a PR checklist to verify: display names, parameter descriptions, job/stage naming.
4. The chapter lead is the main reviewer; peer review is encouraged.

See [Branching Model](../reference/branching-model.md) for how to structure the branch this work happens on.
