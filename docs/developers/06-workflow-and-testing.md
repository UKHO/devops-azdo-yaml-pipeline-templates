# Development Workflow & Testing

## Environment Setup

- Use an IDE with YAML support configured to follow `.editorconfig`.
- 2-space indentation and no tabs are critical formatting standards.

## Branching Strategy

This repository uses simple feature branching: create a `feature/<name>` branch from `main`, make your changes, and merge it back into `main` via Pull Request (squash-merge, never commit directly to `main`).

For the full guide — naming conventions, rebase instructions, and what is *not* branched (the `cicd/`-managed pipeline definitions and gate checks) — see [Branching Strategy](branching-strategy.md).

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
