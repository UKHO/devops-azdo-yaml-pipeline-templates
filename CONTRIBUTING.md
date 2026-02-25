# Contributing

Thank you for your interest in contributing to the **Azure DevOps YAML Pipeline Templates** repository. This document gives you everything you need to get started. For the full developer guide (YAML standards, template development, versioning, and more) see the [developer documentation](docs/developers/README.md).

---

## Code Owners & Contacts

This repository is maintained by the teams listed in the [CODEOWNERS](CODEOWNERS) file:

- **@UKHO/devops-chapter**
- **@UKHO/digital-delivery-capability**

If you have questions, need a review, or are unsure whether a change is appropriate, reach out to one of these teams before starting significant work.

---

## Branching Strategy

This repository follows a **feature-branching** workflow. The short version is:

1. **Create a feature main branch** from `main` (e.g. `feature/my-feature`).
2. **Create development branches** off the feature main for individual tasks (e.g. `feature/my-feature/add-validation`).
3. **Merge development branches** back into the feature main via Pull Request.
4. **Merge the feature main** into `main` via Pull Request once the feature is complete.

Key rules:

- Never commit directly to `main`.
- Prefer **rebasing** over merging to keep a linear history.
- **Squash-merge** into `main`; delete branches after merging.
- Keep feature branches short-lived.

For the full guide, including naming conventions and diagrams, see [Branching Strategy](docs/developers/branching-strategy.md).

---

## Workflow

1. **Branch** — Create a feature branch from `main`.
2. **Develop** — Implement your changes following the [YAML standards](docs/developers/02-yaml-standards.md) and [template development](docs/developers/03-template-development.md) guides.
3. **Test** — Run the relevant test pipeline in Azure DevOps and verify correct compilation and execution. See [Testing](#testing) below.
4. **Pull Request** — Open a PR and request review from the [code owners](CODEOWNERS). Use a draft PR early for initial feedback.
5. **Merge** — After approval, squash-merge into `main` and delete your branch.

---

## Testing

> **Note:** The testing approach for this repository is evolving. The long-term goal is to have dedicated Terraform-provisioned Azure DevOps pipelines that automatically validate template changes.

For now:

- Run the relevant test pipeline in Azure DevOps and verify correct compilation and execution.
- For Terraform templates, use mock providers where available.
- There are no local testing tools; all validation is done by running pipelines in Azure DevOps.
- Document any testing limitations or manual verification steps in your Pull Request.

See [Development Workflow & Testing](docs/developers/06-workflow-and-testing.md) for more detail.

---

## Breaking Changes

Before modifying an existing template, review the [Versioning & Breaking Changes](docs/developers/05-versioning-and-breaking-changes.md) guide. In short:

- Renaming, removing, or changing parameters, outputs, or defaults is a **breaking change**.
- Breaking changes require a **major version bump**, a CHANGELOG entry, and a migration guide.
- Adding optional parameters or new templates is non-breaking.

---

## Developer Documentation

The full developer guide is split into focused topics:

| # | Topic                                                                                  | Description                                  |
|---|----------------------------------------------------------------------------------------|----------------------------------------------|
| 1 | [Repository Structure](docs/developers/01-repository-structure.md)                     | Folder layout and placement rules            |
| 2 | [YAML Standards](docs/developers/02-yaml-standards.md)                                 | Formatting, naming, and key patterns         |
| 3 | [Template Development](docs/developers/03-template-development.md)                     | Parameters, scoping, decomposition           |
| 4 | [Scripts & Tooling](docs/developers/04-scripts-and-tooling.md)                         | Language policy, IDE setup, repo tools       |
| 5 | [Versioning & Breaking Changes](docs/developers/05-versioning-and-breaking-changes.md) | SemVer rules and the breaking change process |
| 6 | [Workflow & Testing](docs/developers/06-workflow-and-testing.md)                       | Branching, PR process, testing               |
| 7 | [Advanced Topics](docs/developers/07-advanced-topics.md)                               | Pipeline decorators, ADRs, design philosophy |
| 8 | [AI & Documentation](docs/developers/08-ai-and-documentation.md)                       | AI usage policy and copilot-instructions     |

Additional references:

- [Branching Strategy (full guide)](docs/developers/branching-strategy.md)
- [How to Version Templates](docs/developers/how-to-version.md)
- [Anti-Pattern: Double Wrapping](docs/developers/anti-pattern-double-wrapping.md)
