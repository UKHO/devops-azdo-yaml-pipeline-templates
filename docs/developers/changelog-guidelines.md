# Changelog Guidelines

Use this guide when updating `CHANGELOG.md` for releases in this repository.

## Purpose

`CHANGELOG.md` is a user-facing release history.
Write entries for template consumers, not for maintainers.

## Standard Format

Follow Keep a Changelog:

- https://keepachangelog.com

Each release section uses this heading:

```markdown
## [VERSION] - YYYY-MM-DD
```

Then include only the subsections that have entries:

```markdown
### Added
### Changed
### Deprecated
### Fixed
### Removed
### Security
```

Do not include empty subsections.

## Writing Rules

- Describe functional outcomes, not file paths.
- Keep each change to one line where possible.
- Use clear, plain language for end users.
- Be explicit about behavior changes and migration impact.
- For deprecations, say what to use instead.

## What to Include by Section

### Added

Use for new user-visible capabilities.

Examples:

- Added support for multiple configuration sources in deployment definitions.
- Added an upgrade guide for moving from legacy Key Vault settings.

### Changed

Use for user-visible behavior improvements or adjustments.

Examples:

- Improved validation messages so invalid deployment configs are easier to diagnose.
- Clarified task behavior for pre-job secret loading scenarios.

### Deprecated

Use when a feature still works but should no longer be used.

Examples:

- Deprecated `KeyVaultConfig`; use `ConfigSources` for new deployments.

### Fixed

Use for user-impacting bug fixes.

Examples:

- Fixed PR trigger behavior so draft pull requests do not start test runs.

### Removed

Use when functionality is fully removed.
Include migration guidance if needed.

### Security

Use for security-relevant fixes.
Avoid disclosing sensitive exploit details.

## Release Update Workflow

1. Confirm the release version and date.
2. Collect merged changes since the previous release.
3. Group changes into Keep a Changelog categories.
4. Rewrite each item as a functional user-facing statement.
5. Add the new version section below `## [Unreleased]`.
6. Keep `## [Unreleased]` at the top for future changes.
7. Review for concise style and consistent wording.

## Quick Quality Checklist

- [ ] Heading matches `## [VERSION] - YYYY-MM-DD`
- [ ] Only non-empty subsections are present
- [ ] Entries describe user impact, not implementation details
- [ ] Deprecations include replacement guidance
- [ ] No broken markdown formatting
- [ ] Wording is concise and consistent

