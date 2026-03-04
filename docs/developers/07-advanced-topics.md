# Advanced Topics & Architecture

## Architectural Decision Records (ADRs)

- Document important decisions in numbered files (e.g., `001-title.md`) in an `adr/` folder.
- Include: date, status, context, decision, and consequences.
- ADRs are never edited after creation; new ADRs supersede old ones.
- Reference relevant ADRs in PR descriptions.

## Design Philosophy

The repository was designed to be both **flexible** and **reusable**:

- Out-of-the-box pipelines for quick adoption (set menu).
- Modular jobs and tasks for custom scenarios (salad bar).
- PowerShell was adopted for scenarios that YAML expressions alone could not handle.
- Extensibility and clear documentation of platform limitations are priorities.

## Documenting Advanced Features

- **Tasks/jobs**: Document in YAML comments at the top of each file.
- **Complex objects/schemas**: Document in Markdown files within `docs/` or `schemas/`.
- Add usage examples and troubleshooting tips as patterns emerge.

See also: [Double Checkout Pathing Problems](quark-double-checkouts-pathing-problems.md).

---

[← Back to Developer Documentation](README.md)

