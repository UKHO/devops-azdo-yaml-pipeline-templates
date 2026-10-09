# Contributing

Thank you for your interest in contributing to the **Azure DevOps YAML Pipeline Templates** repository. This document gives you everything you need to get started. For the codemap see [ARCHITECTURE.md](ARCHITECTURE.md); for the full developer guide (YAML standards, template development, versioning, and more) see the [developer documentation](docs/developers/README.md).

---

## Code Owners & Contacts

This repository is maintained by the teams listed in the [CODEOWNERS](CODEOWNERS) file:

- **@UKHO/devops-chapter**
- **@UKHO/digital-delivery-capability**

If you have questions, need a review, or are unsure whether a change is appropriate, reach out to one of these teams before starting significant work.

---

## Branching Strategy

This repository uses simple feature branching: create a `feature/<name>` branch from `main`, make your changes, and merge back into `main` via Pull Request.

Key rules:

- Never commit directly to `main`.
- Prefer **rebasing** over merging to keep a linear history.
- **Squash-merge** into `main`; delete branches after merging.
- Keep branches short-lived and scoped to one piece of work.

For the full guide, including naming conventions and what is *not* branched, see [Branching Model](docs/developers/reference/branching-model.md).

---

## Workflow

1. **Branch** — Create a feature branch from `main`.
2. **Develop** — Implement your changes following the [YAML standards](docs/developers/reference/yaml-standards.md) and [template conventions](docs/developers/reference/template-conventions.md) guides.
3. **Test** — Run the compile/test framework and verify correct compilation and execution. See [Test a Template](docs/developers/how-to/test-a-template.md).
4. **Pull Request** — Open a PR and request review from the [code owners](CODEOWNERS). Use a draft PR early for initial feedback.
5. **Merge** — After approval, squash-merge into `main` and delete your branch.

---

## Testing

> **Note:** The testing approach for this repository is evolving. The long-term goal is to have dedicated Terraform-provisioned Azure DevOps pipelines that automatically validate template changes.

See [Test a Template](docs/developers/how-to/test-a-template.md) for the compile/test framework commands and the Pull Request process.

---

## Breaking Changes

Before modifying an existing template, review the [Versioning Policy](docs/developers/reference/versioning-policy.md) and [Release a Version](docs/developers/how-to/release-a-version.md) guides. In short:

- Renaming, removing, or changing parameters, outputs, or defaults is a **breaking change**.
- Breaking changes require a **major version bump**, a CHANGELOG entry, and a migration guide.
- Adding optional parameters or new templates is non-breaking.
- Only `pipelines/` and `jobs/` templates carry these guarantees — see [Architecture](ARCHITECTURE.md#invariants).

---

## Developer Documentation

The full developer guide is organised by type in [`docs/developers/README.md`](docs/developers/README.md):

- **How-to**: [Test a Template](docs/developers/how-to/test-a-template.md), [Release a Version](docs/developers/how-to/release-a-version.md), [Update the Changelog](docs/developers/how-to/update-the-changelog.md)
- **Reference**: [YAML Standards](docs/developers/reference/yaml-standards.md), [Template Conventions](docs/developers/reference/template-conventions.md), [Scripts & Tooling](docs/developers/reference/scripts-and-tooling.md), [Versioning Policy](docs/developers/reference/versioning-policy.md), [Branching Model](docs/developers/reference/branching-model.md)
- **Explanation**: [Design Philosophy](docs/developers/explanation/design-philosophy.md), [Double Wrapping](docs/developers/explanation/double-wrapping.md), [Checkout and Path Behaviour](docs/developers/explanation/checkout-and-path-behaviour.md), [AI & Documentation](docs/developers/explanation/ai-and-documentation.md)
- **ADRs**: [docs/developers/adr/](docs/developers/adr/README.md)
