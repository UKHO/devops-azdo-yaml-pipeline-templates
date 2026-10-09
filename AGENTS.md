# AGENTS.md

Instructions for AI coding agents working in this repository. This file is a thin pointer —
it does not restate policy. If anything here conflicts with a linked page, the linked page wins.

## What This Repository Is

A library whose **public API is the reusable templates in `pipelines/` and `jobs/` only**. These are the sole directories external consumers are meant to reference, and they carry SemVer guarantees (see [Versioning Policy](docs/developers/reference/versioning-policy.md)).

Everything else is **internal** — `tasks/`, `stages/`, `schemas/`, `utils/`, and the supporting PowerShell (`scripts/`, `tools/`) are private building blocks consumed only by the templates in this repo. They are **not** part of the reuse surface, must not be referenced directly by external pipelines, and carry **no** versioning guarantees — they may change at any time.

See [ARCHITECTURE.md](ARCHITECTURE.md) for the full layout and the internal/external boundary.

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
  [Versioning Policy](docs/developers/reference/versioning-policy.md) —
  these folders are the public API and have SemVer guarantees; `tasks/`, `stages/`, `utils/`,
  `schemas/`, `scripts/` do not.
- Do not wrap a template inside another template unless unavoidable — see
  [Double Wrapping](docs/developers/explanation/double-wrapping.md).
- Markdown edits must not hard-wrap prose — see
  [markdown.instructions.md](.github/instructions/markdown.instructions.md).

## Boundaries

- Do not tag releases. Tagging is a maintainer action after merge to `main`.
- Add an entry under `## [Unreleased]` in `CHANGELOG.md` for any user-visible change, in the
  same Pull Request as the change itself — see
  [Update the Changelog](docs/developers/how-to/update-the-changelog.md). Do not edit entries
  under already-released version headings, and do not rename `## [Unreleased]` yourself; that
  is a maintainer action when cutting a release.
- Ask before adding a new top-level folder, a new dependency, or a new `.github/` instruction
  or prompt file.
