# Branching Model

This repository uses simple **feature branching**. All work happens on a short-lived branch created from `main` and merged back into `main` via Pull Request.

---

## Overview

```text
main ────────────────────────────────────────────►
  │                                    ▲
  └── feature/my-feature ──────────────┘
```

| Branch              | Purpose                                | Lifetime                |
|---------------------|-----------------------------------------|--------------------------|
| `main`              | Production-ready code. Always stable.  | Permanent                |
| `feature/<name>`    | A single unit of work.                 | Lives until merged to `main` |

There is no "feature main" or nested development-branch hierarchy. Keep each `feature/<name>` branch scoped to one piece of work and merge it directly into `main`.

## Step-by-Step Workflow

### 1. Create a Branch

Branch from `main` when starting a new piece of work:

```bash
git checkout main
git pull
git checkout -b feature/my-feature
```

### 2. Make Your Changes

```bash
git add .
git commit -m "Add optional foo parameter to terraform_build"
git push -u origin feature/my-feature
```

### 3. Open a Pull Request into `main`

1. Open a Pull Request from `feature/my-feature` → `main`.
2. Request review from the [code owners](../../../CODEOWNERS) (`@UKHO/devops-chapter`, `@UKHO/digital-delivery-capability`).
3. After approval, **squash-merge** into `main` and delete the branch.

---

## Branch Naming Conventions

| Prefix           | Use                                   |
|------------------|----------------------------------------|
| `feature/<name>` | New features or significant changes   |
| `fix/<name>`     | Bug fixes                             |
| `docs/<name>`    | Documentation-only changes            |
| `chore/<name>`   | Maintenance, tooling, or housekeeping |

---

## Rebase vs. Merge

- **Prefer rebasing** a long-running branch onto `main` to keep a linear history.
- **Squash-merge** is the default when merging a branch into `main`.

### Keeping Your Branch Up to Date

```bash
git checkout feature/my-feature
git fetch origin
git rebase origin/main
```

If there are conflicts, resolve them locally, then force-push:

```bash
git push --force-with-lease
```

---

## Rules

1. **Never commit directly to `main`.** All changes go through a Pull Request.
2. **Delete branches after merging.** Keep the repository tidy.
3. **Keep branches short-lived and scoped to one piece of work.** Don't bundle unrelated changes.
4. **Code branches take precedence** in case of conflicts between a code branch and a documentation branch.

### What Is Not Branched

The Azure DevOps pipeline *definitions* that build and gate this repository (the pipelines provisioned by [`cicd/`](../../../cicd)) are not changed via `feature/<name>` branches in this repo. They, and the branch-policy/gate-check configuration for `main`, are managed through the Terraform in `cicd/` and Azure DevOps project settings directly. Changes to what gates `main` are a separate, lower-frequency change from day-to-day template work.

---

## Current Scaling Limits

> This repository is not currently set up for multiple people working on large, parallel features at once. If a change adds new tests, those tests currently need a manual Terraform deployment step before they can run — there is no automated provisioning of test infrastructure per branch. Keep features small and merge frequently rather than running long, parallel feature branches.

For how to actually validate a template change, see [Test a Template](../how-to/test-a-template.md).
