# Update the Changelog

Use this guide when updating `CHANGELOG.md` for releases in this repository.

## Purpose

`CHANGELOG.md` is a user-facing release history. Write entries for template consumers, not for maintainers.

## Standard Format

Follow Keep a Changelog:

- [Keep a change log](https://keepachangelog.com)

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

> **`## [Unreleased]` is always present at the top of `CHANGELOG.md`.** As you merge changes, add entries under `## [Unreleased]` in the appropriate subsection. When cutting a release, rename `## [Unreleased]` to the new `## [VERSION] - YYYY-MM-DD` heading and add a fresh, empty `## [Unreleased]` above it for the next round of changes.

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

Use for user-visible behavior improvements or adjustments. If a change is breaking, prefix the line with **BREAKING**: so it stands out from non-breaking entries in the same section.

Examples:

- Improved validation messages so invalid deployment configs are easier to diagnose.
- Clarified task behavior for pre-job secret loading scenarios.
- **BREAKING**: Removed the `KeyVaultConfig` parameter; use `ConfigSources` instead.

### Deprecated

Use when a feature still works but should no longer be used.

Examples:

- Deprecated `KeyVaultConfig`; use `ConfigSources` for new deployments.

### Fixed

Use for user-impacting bug fixes.

Examples:

- Fixed PR trigger behavior so draft pull requests do not start test runs.

### Removed

Use when functionality is fully removed. Include migration guidance if needed.

### Security

Use for security-relevant fixes. Avoid disclosing sensitive exploit details.

## Day-to-Day: Adding an Entry

1. Add your entry under `## [Unreleased]`, in the appropriate subsection (`Added`, `Changed`, `Deprecated`, `Fixed`, `Removed`, `Security`).
2. If the subsection doesn't exist yet under `## [Unreleased]`, add it.
3. Do this in the same Pull Request as the change itself.

## Release Update Workflow

1. Confirm the release version and date.
2. Rename `## [Unreleased]` to `## [VERSION] - YYYY-MM-DD`, using the entries already accumulated there.
3. Review each entry for concise style, consistent wording, and functional (not implementation) framing.
4. Add a fresh, empty `## [Unreleased]` heading above the newly renamed section, ready for the next round of changes.

## Quick Quality Checklist

- [ ] Heading matches `## [VERSION] - YYYY-MM-DD`
- [ ] Only non-empty subsections are present
- [ ] Entries describe user impact, not implementation details
- [ ] Deprecations include replacement guidance
- [ ] No broken markdown formatting
- [ ] Wording is concise and consistent
