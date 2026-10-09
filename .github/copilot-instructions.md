# GitHub Copilot Custom Instructions

This repository (`devops-azdo-yaml-pipeline-templates`) is a centralised source for reusable Azure DevOps YAML pipeline templates. The goal is to maintain high standards, reliability, and reusability for pipelines used across multiple projects.

This repository follows [Semantic Versioning 2.0.0](https://semver.org/).

## Repository Structure

See [ARCHITECTURE.md](../ARCHITECTURE.md) for the full folder layout, documentation-location
rules, and invariants. In short: this repository follows a "set-menu with salad bar" approach—
`pipelines/` is the set-menu (ready-to-use), `jobs/` is the salad bar (modular, combinable
templates). `tasks/`, `stages/`, and `utils/` are internal building blocks, not for direct
external consumption.

## Key Principles

- **Formatting:** Follow `.editorconfig` (UTF-8, LF line endings, 2-space indent)
- **Reusability:** Design templates to be modular and consumable by other repositories
- **Cross-platform:** Templates must run on both Windows and Linux agents. Use `pwsh` for scripting and avoid OS-specific assumptions (path separators, shell built-ins)
- **Open-source tasks:** Prefer built-in Azure DevOps tasks or open-source equivalents over paid Marketplace extensions, so consumers need not install licensed extensions
- **Self-documenting parameters:** Use `displayName`, `type`, and sensible defaults on all parameters
- **No double-wrapping:** Do not wrap a template inside another template unless absolutely necessary — see `docs/developers/explanation/double-wrapping.md`
- **Security:** Never hardcode secrets — use Azure Key Vault or variable groups. Declare template-internal variables with `readonly: true` so consumers cannot override them — see [Template Conventions](../docs/developers/reference/template-conventions.md#protecting-template-internal-variables).
- **Breaking changes:** Increment the major version and update `CHANGELOG.md`

## Dedicated Instruction Files

Detailed guidance is maintained in dedicated instruction files that are automatically applied based on file type:

| File | Applies To | Covers |
|------|-----------|--------|
| `azure-devops-pipelines.instructions.md` | `**/*.{yml,yaml}` | YAML formatting, template documentation strategy, parameter best practices, anti-patterns, breaking changes, security, naming conventions |
| `update-documentation.instructions.md` | `**/*.{yml,yaml,md}` | When and how to update documentation for each template type, CHANGELOG management, downstream documentation effects |
| `markdown.instructions.md` | `**/*.md` | Markdown formatting, structure, and validation rules |

Refer to these files for detailed rules. This file provides only the high-level context and principles needed to understand the repository.
