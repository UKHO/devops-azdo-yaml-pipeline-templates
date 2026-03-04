# Branching Strategy — Feature Branching

This repository uses a **feature-branching** workflow. All work flows through short-lived branches that eventually merge back into `main`.

---

## Overview

```text
main ─────────────────────────────────────────────────►
  │                                          ▲
  └── feature/my-feature (feature main) ─────┘
        │           │           ▲
        │           └── dev-1 ──┘
        └── dev-2 ──────────────┘
```

| Branch                                    | Purpose                                                                              | Lifetime                               |
|-------------------------------------------|--------------------------------------------------------------------------------------|----------------------------------------|
| `main`                                    | Production-ready code. Always stable.                                                | Permanent                              |
| `feature/<name>`                          | The **feature main** — groups all development for a single feature or piece of work. | Lives until merged to `main`           |
| Development branches off the feature main | Individual units of work (tasks, spikes, fixes) that feed into the feature main.     | Lives until merged to the feature main |

---

## Step-by-Step Workflow

### 1. Create a Feature Main Branch

Branch from `main` when starting a new piece of work:

```bash
git checkout main
git pull
git checkout -b feature/my-feature
```

### 2. Create Development Branches

For each task or sub-piece of work, branch from the feature main:

```bash
git checkout feature/my-feature
git checkout -b feature/my-feature/add-new-parameter
```

Make your changes, commit, and push:

```bash
git add .
git commit -m "Add optional foo parameter to terraform_build"
git push -u origin feature/my-feature/add-new-parameter
```

### 3. Merge Development Branches into the Feature Main

When a development branch is complete, open a **Pull Request** targeting the feature main (`feature/my-feature`). After review, merge and delete the development branch.

Repeat steps 2–3 for each unit of work until the feature is complete.

### 4. Merge the Feature Main into `main`

When the feature is ready:

1. Ensure the feature main is up to date with `main` (rebase preferred — see below).
2. Open a Pull Request from `feature/my-feature` → `main`.
3. Request review from the [code owners](../../CODEOWNERS) (`@UKHO/devops-chapter`, `@UKHO/digital-delivery-capability`).
4. After approval, **squash-merge** into `main` and delete the feature branch.

---

## Branch Naming Conventions

| Prefix           | Use                                   |
|------------------|---------------------------------------|
| `feature/<name>` | New features or significant changes   |
| `fix/<name>`     | Bug fixes                             |
| `docs/<name>`    | Documentation-only changes            |
| `chore/<name>`   | Maintenance, tooling, or housekeeping |

Development branches nested under a feature main should use a descriptive suffix:

```text
feature/infra-pipeline-v3                  ← feature main
feature/infra-pipeline-v3/add-validation   ← development branch
feature/infra-pipeline-v3/update-defaults  ← development branch
```

---

## Rebase vs. Merge

- **Prefer rebasing** the feature main onto `main` to keep a linear history.
- **Squash-merge** is the default when merging a feature main into `main`.
- **Merge commits** are acceptable when combining development branches into a feature main (to preserve context).

### Keeping Your Feature Main Up to Date

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
3. **Keep feature branches short-lived.** Long-lived branches lead to painful merges.
4. **One feature per feature main.** Do not bundle unrelated work.
5. **Code branches take precedence** in case of conflicts between a code branch and a documentation branch.

---

## Testing

> **Note:** The testing story for this repository is evolving. The long-term goal is to provision dedicated Azure DevOps pipelines via Terraform so that templates can be validated automatically.

For now:

- Run the relevant test pipeline in Azure DevOps and verify correct compilation and execution.
- For Terraform templates, use mock providers where available.
- Document any testing limitations in the Pull Request description.
- There are no local testing tools; validation is done by running pipelines in Azure DevOps.

See [Development Workflow & Testing](06-workflow-and-testing.md) for more detail.

---

[← Back to Developer Documentation](README.md)

