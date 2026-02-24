# Repository Structure & Organisation

The repository groups templates and scripts by function and level:

| Folder       | Purpose                                                                                                              |
|--------------|----------------------------------------------------------------------------------------------------------------------|
| `tasks/`     | Templates wrapping individual Azure DevOps tasks. Provides stable interfaces, defaults, and clear parameter names.   |
| `jobs/`      | Self-contained, reusable job-level templates. Includes parameter validation and may use schemas for complex objects. |
| `stages/`    | Stage templates that group jobs for specific pipeline goals (e.g., environments or milestones).                      |
| `pipelines/` | Entry-point templates that assemble stages into complete pipelines.                                                  |
| `scripts/`   | PowerShell scripts for operations not supported by built-in tasks or YAML expressions.                               |
| `utils/`     | Shared YAML snippets that support other templates.                                                                   |
| `tools/`     | Scripts and utilities for repository maintenance and automation.                                                     |
| `schemas/`   | Validation templates for complex object parameters passed through pipelines.                                         |

## Placement Rules

- **Scripts** go in `scripts/`.
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

---

[← Back to Developer Documentation](README.md)

