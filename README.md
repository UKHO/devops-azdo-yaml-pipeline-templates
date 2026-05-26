# Azure DevOps YAML Pipeline Templates

This repository provides reusable Azure DevOps YAML templates for Terraform
infrastructure delivery on Azure.

The goal is to help teams ship faster with consistent, production-ready
pipelines, while reducing duplication across repositories.

## Why use these templates

- **Standardization**: consistent Terraform build/deploy behavior across teams
  and services.
- **Faster delivery**: reuse templates instead of rebuilding pipeline logic.
- **Safer releases**: built-in support for plan/apply workflows, verification,
  and approval gates.
- **Composable architecture**: use full pipelines for quick adoption, or modular
  jobs/templates for custom workflows.

## Versioning scope

This repository follows [Semantic Versioning 2.0.0](https://semver.org/).

SemVer compatibility guarantees apply to templates in:

- [pipelines](pipelines)
- [jobs](jobs)

## Reference this repository

In your consumer `azure-pipelines.yml`, add this repository as a template
resource:

```yaml
resources:
  repositories:
    - repository: AzDOPipelineTemplates
      type: github
      endpoint: UKHO
      name: UKHO/devops-azdo-yaml-pipeline-templates
      ref: refs/tags/v0.1.0
```

Then reference templates using `@AzDOPipelineTemplates`.

## What is available

This repository follows a **set-menu + salad bar** model.

### Set-menu: ready-to-use pipeline templates

- [`pipelines/terraform_pipeline.yml`](pipelines/terraform_pipeline.yml)

Use this when you want an end-to-end Terraform pipeline with minimal setup.

### Salad bar: modular templates for custom pipelines

Reusable job templates:

- [`jobs/terraform_build.yml`](jobs/terraform_build.yml)
- [`jobs/terraform_deploy.yml`](jobs/terraform_deploy.yml)
- [`jobs/terraform_gated_deployment.yml`](jobs/terraform_gated_deployment.yml)
- [`jobs/manual_verification.yml`](jobs/manual_verification.yml)

Supporting components:

- [`stages`](stages)
- [`tasks`](tasks)
- [`utils`](utils)
- [`schemas`](schemas)
- [`scripts`](scripts)

## Quality assurance and CI/CD confidence

These templates are validated with compile/test automation and runnable template
test suites.

- PowerShell compile/test framework in [`tests/framework`](tests/framework)
- Job test runner:
  [`tests/jobs/jobs.CompileTests.ps1`](tests/jobs/jobs.CompileTests.ps1)
- Pipeline test runner:
  [`tests/pipelines/pipelines.CompileTests.ps1`](tests/pipelines/pipelines.CompileTests.ps1)
- Template test suites under [`tests`](tests), including:
  - [`tests/pipelines/terraform_pipeline`](tests/pipelines/terraform_pipeline)
  - [`tests/jobs/manual_verification`](tests/jobs/manual_verification)
  - [`tests/jobs/terraform_build`](tests/jobs/terraform_build)
  - [`tests/jobs/terraform_deploy`](tests/jobs/terraform_deploy)
  - [`tests/jobs/terraform_gated_deployment`](tests/jobs/terraform_gated_deployment)
- Merge policy: every merge to `main` requires all Azure DevOps template tests
  to pass successfully
- CI/CD infrastructure assets and deployment utilities in [`cicd`](cicd)

## Documentation

- User documentation: [`docs/user-docs/README.md`](docs/user-docs/README.md)
- Definition/reference docs:
  [`docs/definition_docs`](docs/definition_docs)
