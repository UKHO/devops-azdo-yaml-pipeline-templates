# AGENTS.md

Instructions for AI coding agents working in this repository. This file is a thin pointer —
it does not restate policy. If anything here conflicts with a linked page, the linked page wins.

## What This Repository Is

A library of reusable Azure DevOps YAML pipeline templates (`tasks/`, `jobs/`, `stages/`,
`pipelines/`, `schemas/`, `utils/`), plus the PowerShell scripts that support them
(`scripts/`, `tools/`). See [Repository Structure](docs/developers/01-repository-structure.md)
for the full layout.

## Primary Entry Points

- Human contributors: [CONTRIBUTING.md](CONTRIBUTING.md)
- Full developer guide: [docs/developers/README.md](docs/developers/README.md)
- GitHub Copilot-specific instructions: [.github/copilot-instructions.md](.github/copilot-instructions.md)
  and [.github/instructions/](.github/instructions/)

## Build / Test Commands

There is no build step. To compile-test templates:

```powershell
# From the repository root, in PowerShell
$repoRoot = git rev-parse --show-toplevel
. (Join-Path $repoRoot "tests" "framework" "Core.ps1")

# Run all job template compile tests
Run-DirectoryCompileTests -DirectoryPath "tests/jobs"

# Run all pipeline template compile tests
Run-DirectoryCompileTests -DirectoryPath "tests/pipelines"
```

Run the relevant test(s) for any template folder you change before opening a Pull Request.

## Conventions an Agent Must Follow

- Follow `.editorconfig` (UTF-8, LF, 2-space indent) for all files.
- Do not hardcode secrets in any template or script.
- Before changing a template in `pipelines/` or `jobs/`, read
  [Versioning & Breaking Changes](docs/developers/05-versioning-and-breaking-changes.md) —
  these folders are the public API and have SemVer guarantees; `tasks/`, `stages/`, `utils/`,
  `schemas/`, `scripts/` do not.
- Do not wrap a template inside another template unless unavoidable — see
  [Anti-Pattern: Double Wrapping](docs/developers/anti-pattern-double-wrapping.md).
- Markdown edits must not hard-wrap prose — see
  [markdown.instructions.md](.github/instructions/markdown.instructions.md).

## Boundaries

- Do not tag releases. Tagging is a maintainer action after merge to `main`.
- Do not edit existing `CHANGELOG.md` entries. Add a new `## [VERSION] - YYYY-MM-DD` section
  per [Changelog Guidelines](docs/developers/changelog-guidelines.md) when asked to prepare a
  release; otherwise leave `CHANGELOG.md` alone.
- Ask before adding a new top-level folder, a new dependency, or a new `.github/` instruction
  or prompt file.
