# Release Notes - v0.1.0

First public release of `devops-azdo-yaml-pipeline-templates`.

## Highlights

- Introduces a reusable Terraform pipeline template for Azure DevOps:
  - `pipelines/terraform_pipeline.yml`
- Adds reusable Terraform workflow job templates:
  - `jobs/terraform_build.yml`
  - `jobs/terraform_deploy.yml`
  - `jobs/terraform_gated_deployment.yml`
  - `jobs/manual_verification.yml`
- Adds supporting stage templates:
  - `stages/terraform_build.yml`
  - `stages/terraform_deploy.yml`

## Testing and Validation

- Includes a PowerShell-based compile/test framework under `tests/framework/`
- Includes test runners:
  - `tests/jobs/jobs.CompileTests.ps1`
  - `tests/pipelines/pipelines.CompileTests.ps1`
- Includes YAML test templates in:
  - `tests/pipelines/terraform_pipeline/`
  - `tests/jobs/manual_verification/`
  - `tests/jobs/terraform_build/`
  - `tests/jobs/terraform_deploy/`
  - `tests/jobs/terraform_gated_deployment/`

## Notes

- Release is aligned to the updated `CHANGELOG.md` entry for `0.1.0`.
- Template documentation is available under `docs/user-docs/` and
  `docs/definition_docs/`.

