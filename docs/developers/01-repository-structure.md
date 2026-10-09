# Repository Structure & Organisation

This is the single canonical description of the repository's top-level folder
layout. If any other document disagrees with this one, this one wins.

The repository groups templates and scripts by function and level:

| Folder       | Purpose                                                                                                              |
|--------------|----------------------------------------------------------------------------------------------------------------------|
| `tasks/`     | Templates wrapping individual Azure DevOps tasks. Provides stable interfaces, defaults, and clear parameter names.   |
| `jobs/`      | Self-contained, reusable job-level templates. Includes parameter validation and may use schemas for complex objects. |
| `stages/`    | Stage templates that group jobs for specific pipeline goals (e.g., environments or milestones).                      |
| `pipelines/` | Entry-point templates that assemble stages into complete pipelines.                                                  |
| `utils/`     | Shared YAML snippets that support other templates.                                                                   |
| `schemas/`   | Validation templates for complex object parameters passed through pipelines.                                         |
| `scripts/`   | PowerShell scripts invoked **by templates at pipeline runtime**, for operations not supported by built-in tasks or YAML expressions (e.g. `scripts/terraform/`). These ship to consumers as part of the templates. |
| `tools/`     | PowerShell scripts invoked **by developers of this repository**, for repository maintenance and automation (e.g. bulk-updating a tool version across templates). These never run inside a consumer's pipeline. |
| `tests/`     | The PowerShell compile/test framework and test fixtures used to validate templates before merge. |
| `examples/`  | Standalone illustrative pipelines/snippets (e.g. variable scoping behaviour) that are not part of the template library itself. |
| `cicd/`      | Terraform that provisions this repository's own Azure DevOps/GitHub CI/CD resources. Not consumed by template users. |
| `docs/`      | All contributor and consumer documentation. |

## Placement Rules

- **Scripts consumed by templates at runtime** go in `scripts/`.
- **Scripts for maintaining this repository** go in `tools/`.
- **Templates** go in the folder matching their level: `tasks/`, `jobs/`, `stages/`, or `pipelines/`.
- **Schemas** go in `schemas/`.
- For templates that produce a list (e.g. a sequence of jobs), use a descriptive suffix such as `_job_list` in the filename.
- Do not create new folders without team discussion. The existing structure covers most needs.

## Set Menu vs. Salad Bar

- **Set menu**: Ready-to-use pipelines (e.g. deploy infrastructure, web app, function app). Minimal customisation, fast adoption.
- **Salad bar**: Modular jobs and tasks that teams combine for custom scenarios. Maximum flexibility.

## What Does Not Need to Be a Template

- Root pipeline elements (`trigger`, `pr`) cannot be templated.
- Only template logic that benefits from abstraction, reuse, or validation.
