# Development Workflow & Testing

## Environment Setup

- Use an IDE with YAML support configured to follow `.editorconfig`.
- 2-space indentation and no tabs are critical formatting standards.

## Branching Strategy

This repository uses a **feature-branching** workflow:

1. Create a **feature main** branch from `main` (e.g. `feature/my-feature`).
2. Create **development branches** off the feature main for individual tasks.
3. Merge development branches back into the feature main via PR.
4. Merge the feature main into `main` via PR when the feature is complete.

Key rules:

- Never commit directly to `main`.
- `feature/<name>` for features, `fix/<name>` for bug fixes, `docs/<name>` for documentation, `chore/<name>` for housekeeping.
- Delete branches after merging.
- Prefer **rebasing** over merging from `main`.
- **Squash-merge** into `main`.
- In case of conflicts, code branches take precedence over documentation branches.

For the full guide — including diagrams, naming conventions, and rebase instructions — see [Branching Strategy](branching-strategy.md).

## Pull Request Process

1. Create a **draft PR** early for initial feedback.
2. Submit code PRs and documentation PRs separately; link them in the description.
3. Use a PR checklist to verify: display names, parameter descriptions, job/stage naming.
4. The chapter lead is the main reviewer; peer review is encouraged.

## Testing

> **Note:** The testing approach is evolving. The long-term goal is to have dedicated Terraform-provisioned Azure DevOps pipelines that automatically validate template changes.

- Run the relevant test pipeline in Azure DevOps and verify correct compilation and execution.
- For Terraform templates, use mock providers where available.
- Document any testing limitations or manual verification steps in the PR.
- There are no local testing tools; all validation is done by running pipelines in Azure DevOps.

---

[← Back to Developer Documentation](README.md)

