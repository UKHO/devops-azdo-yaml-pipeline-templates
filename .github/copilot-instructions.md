# GitHub Copilot Custom Instructions

This repository (`devops-azdo-yaml-pipeline-templates`) is a centralised source for reusable
Azure DevOps YAML pipeline templates. The goal is to maintain high standards, reliability, and
reusability for pipelines used across multiple projects.

This repository follows [Semantic Versioning 2.0.0](https://semver.org/).

## Repository Structure

This repository follows a "set-menu with salad bar" approach:

- **Set-Menu** (`pipelines/`): Complete, ready-to-use pipeline templates for common scenarios
- **Salad Bar** (`tasks/`, `jobs/`, `stages/`, `utils/`, `scripts/`): Modular components for
  building custom pipelines

### Key Directories

| Directory    | Purpose                                          | Documentation Location                          |
|--------------|--------------------------------------------------|-------------------------------------------------|
| `tasks/`     | Reusable step wrappers around Azure DevOps tasks | In-file comment block                           |
| `utils/`     | Helper templates (variables, expressions)        | In-file comment block                           |
| `jobs/`      | Job-level templates                              | External (`docs/`)                              |
| `stages/`    | Stage-level templates                            | External (`docs/`)                              |
| `pipelines/` | Complete pipeline templates (set-menu)           | External (`docs/user-docs/`)                    |
| `schemas/`   | Compile-time validation templates                | Brief in-file comment + `docs/definition_docs/` |
| `docs/`      | All external documentation                       | —                                               |

## Key Principles

- **Formatting:** Follow `.editorconfig` (UTF-8 without BOM, LF line endings, 2-space indent)
- **Reusability:** Design templates to be modular and consumable by other repositories
- **Self-documenting parameters:** Use `displayName`, `type`, and sensible defaults on all
  parameters
- **No double-wrapping:** Do not wrap a template inside another template unless absolutely
  necessary — see `docs/anti-pattern-double-wrapping.md`
- **Security:** Never hardcode secrets — use Azure Key Vault or variable groups
- **Breaking changes:** Increment the major version and update `CHANGELOG.md`

## Dedicated Instruction Files

Detailed guidance is maintained in dedicated instruction files that are automatically applied
based on file type:

| File | Applies To | Covers |
|------|-----------|--------|
| `azure-devops-pipelines.instructions.md` | `**/*.yml` | YAML formatting, template documentation strategy, parameter best practices, anti-patterns, breaking changes, security, naming conventions |
| `update-documentation.instructions.md` | `**/*.{yml,md}` | When and how to update documentation for each template type, CHANGELOG management, downstream documentation effects |
| `markdown.instructions.md` | `**/*.md` | Markdown formatting, structure, and validation rules |

Refer to these files for detailed rules. This file provides only the high-level context and
principles needed to understand the repository.
