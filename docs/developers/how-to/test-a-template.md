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

## Writing a Test

Templates are validated by compiling them and asserting on the result. There are two test styles:

### 1. Directory compile fixtures

Drop a `*_test.yml` file under `tests/<area>/<template-name>/` that references the template exactly as a consumer would, then let `Run-DirectoryCompileTests` compile every fixture in the area. A fixture pins the repository resource to the current branch so the template under test is the one compiled:

```yaml
resources:
  repositories:
    - repository: AzDOPipelineTemplates
      type: github
      endpoint: UKHO
      name: UKHO/devops-azdo-yaml-pipeline-templates
      ref: ${{ variables['Build.SourceBranch'] }}

pool:
  name: 'Mare Nectaris'

trigger: none
pr:
  branches:
    include:
      - main

jobs:
  - template: jobs/manual_verification.yml@AzDOPipelineTemplates
    parameters:
      TimeoutInMinutes: 1
      OnTimeoutBehaviour: resume
      Instructions: 'Please verify the deployment.'
```

Name fixtures after the scenario they exercise (e.g. `resume_test.yml`, `double_resume_test.yml`), and link them from the user doc's `**Live example**` entries.

### 2. Parameterised assertions (`Run-Tests`)

For a `tasks/` or `utils/` template, a `*.CompileTests.ps1` file can assert on the compiled YAML or on expected validation errors across parameter combinations:

```powershell
if (-not (Get-Command -Name 'Run-Tests' -ErrorAction SilentlyContinue))
{
  $repoRoot = git rev-parse --show-toplevel 2> $null
  . (Join-Path $repoRoot "tests" "framework" "Core.ps1")
}

$validTestCases = @(
  @{
    Description  = "with default parameters"
    Parameters   = @{ message = "Hello"; verbosityLevel = "info" }
    ExpectedYaml = @('echo "Hello"')
  }
)

$invalidTestCases = @(
  @{
    Description  = "with empty message"
    Parameters   = @{ message = ""; verbosityLevel = "info" }
    ErrorMessage = "The 'message' parameter is not a valid String."
  }
)

Run-Tests `
  -YamlPath "tests/framework/example_echo_task.yml" `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases
```

Use `ValidTestCases` with `ExpectedYaml` to assert the compiled output, and `InvalidTestCases` with `ErrorMessage` to assert that a schema/guard rejects bad input. See `tests/framework/example_echo_task.CompileTests.ps1` for a complete example.

## Pull Request Process

1. Create a **draft PR** early for initial feedback.
2. Submit code PRs and documentation PRs separately; link them in the description.
3. Use a PR checklist to verify: display names, parameter descriptions, job/stage naming.
4. The chapter lead is the main reviewer; peer review is encouraged.

See [Branching Model](../reference/branching-model.md) for how to structure the branch this work happens on.
