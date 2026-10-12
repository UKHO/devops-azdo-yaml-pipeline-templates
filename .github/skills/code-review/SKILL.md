---
name: code-review
description: >
  Use when the user asks to review a pull request, diff, branch, or specific
  template/doc/test files in this Azure DevOps YAML pipeline templates repo — or
  asks "does this follow our conventions?" or requests a pre-merge check — to walk
  the change file-by-file against the repo's own standards (`.github/instructions/*`
  and `docs/developers/`), verify the per-template Definition of Done (template,
  schema, compile + e2e tests, docs, CHANGELOG), and return findings grouped by
  severity with a concrete fix for each. NOT when the user only wants to author
  new template code or get a quick explanation with no review intent — use normal
  chat or an authoring skill instead.
license: MIT
---

# Code Review for Pipeline Templates

This skill teaches Copilot to review changes to this repository the way a
careful maintainer would: against the repository's **own** written standards, not
generic opinions. It does not restate every rule — the authoritative source is
the linked instruction and reference files, which change over time. Always read
the linked file for the current wording before asserting a violation.

> **Policy precedence** (from `docs/developers/explanation/ai-and-documentation.md`):
> the human docs under `docs/developers/` are authoritative for *policy*; the
> `.github/` files are authoritative for the exact *enforceable wording*. If they
> disagree, flag the disagreement rather than silently picking one.

---

## When to use this skill

- Reviewing a PR, branch, or diff before merge.
- Checking whether a new or changed template follows conventions.
- Sanity-checking that documentation, tests, and `CHANGELOG.md` were updated
  alongside a code change.

If the user has not told you the scope, determine it from the diff
(`get_changed_files`) or ask which branch/PR to review.

---

## How to run a review

1. **Scope the change.** Get the list of changed files (staged + unstaged, or the
   PR's files). Group them by area: `pipelines/`, `jobs/`, `stages/`, `tasks/`,
   `utils/`, `schemas/`, `tests/`, `docs/`, `.github/`, root (`CHANGELOG.md`,
   `ARCHITECTURE.md`, `.editorconfig`).
2. **Read each changed file in full**, plus any file it depends on that you need
   for context (the template a test exercises, the schema a job calls, the doc a
   template mirrors).
3. **Apply the checklists below**, by file type. Each file type has a different
   documentation and testing contract — do not apply job rules to a task, etc.
4. **Verify the cross-file contract.** A single logical change usually touches a
   template *and* its docs *and* its tests *and* `CHANGELOG.md`. Missing siblings
   are the most common and most important finding.
5. **Report** using the output format at the end. Cite the specific rule/doc for
   every finding so the author can verify it.

---

## Repository ground rules (apply to every file)

Source of truth: `.github/copilot-instructions.md` and
`.github/instructions/azure-devops-pipelines.instructions.md`.

- **`.yml`, never `.yaml`.** Reject any new `.yaml` file.
- **`.editorconfig` compliance**: UTF-8, LF line endings, 2-space indent, final
  newline, no trailing whitespace, no tabs.
- **Cross-platform**: scripting uses `pwsh` (not `powershell` or `bash`); no
  hardcoded path separators or OS-specific shell built-ins; no assumed agent
  image (consumers pick the pool).
- **Open-source / built-in tasks only**: no task that forces consumers to install
  a paid/licensed Marketplace extension. Prefer built-in tasks or `script`/`pwsh`.
  See `docs/developers/explanation/design-philosophy.md`.
- **No hardcoded secrets**: use Key Vault / variable groups; mark secret vars
  appropriately.
- **`readonly: true`** on every template-internal variable so consumers can't
  override it. See
  `docs/developers/reference/template-conventions.md#protecting-template-internal-variables`.
- **No double-wrapping**: don't wrap a template in another just to pass
  parameters through. See `docs/developers/explanation/double-wrapping.md` for the
  allowed exceptions (cross-level orchestration, combining unrelated templates,
  enforcing extra validation).
- **Self-documenting parameters**: every parameter has `type` and `displayName`;
  required parameters have **no** `default` (with a `# NO default` comment);
  optional parameters have a sensible documented default.

---

## Checklist by file type

### `tasks/` and `utils/` — in-file documentation is the sole doc

Source: `azure-devops-pipelines.instructions.md` →
*Template Documentation Strategy*, and
`docs/developers/reference/template-conventions.md#task-template-file-documentation`.

- [ ] Has the top-of-file comment block: `Purpose`, `Parameters`, `Example Usage`,
  `Notes` (with a `See:` link to the underlying Microsoft task reference where
  relevant).
- [ ] The `Parameters:` block matches the actual `parameters:` list exactly —
  names, types, required vs optional, enum `Values:`, and `Default:` for
  optionals.
- [ ] If a parameter was added/removed/renamed/retyped or a default changed, the
  comment block **and** any affected `Example Usage` were updated in the same
  change.
- [ ] Prefers a first-party task over a raw `script:` where one exists (ADR-0002);
  raw CLI is acceptable only as a deliberate escape hatch, and documented as such.
- [ ] Validation guards (required-param checks) emit the `"message": "Error"`
  one-key-mapping pattern where used.
- [ ] Has a `*.CompileTests.ps1` (where behaviour/validation warrants it) using
  `Run-Tests` with `ValidTestCases`/`InvalidTestCases`.

### `jobs/`, `pipelines/`, `stages/` — external docs, no big in-file block

Source: `update-documentation.instructions.md` → sections 2 / 2a, and the
*Template Documentation Strategy* section.

- [ ] **No** comprehensive in-file comment block — relies on `displayName` +
  self-documenting names. A short orientation header is fine.
- [ ] Generic parameters follow the established convention verbatim:
  `ArtifactName`, `Condition`, `DependsOn`, `Pool` (carry over from the Terraform
  family).
- [ ] Job-specific settings are grouped into a **config object** validated by a
  `schemas/*.yml` template (the mature pattern), not sprayed as many loose
  top-level parameters.
- [ ] Mirrored external doc exists/updated: `jobs/<name>.yml` →
  `docs/user-docs/jobs/<name>.md` (same for `pipelines/`). New template ⇒ new doc
  **and** an entry in `docs/user-docs/README.md`.
- [ ] The doc follows the concise skeleton: H1 + one-line description →
  **commented-defaults invocation block** (every parameter at its default with an
  aligned inline comment; lists marked `(list)`; required ones noted) → `---`
  rules → Output/Artifact section → `## Examples` with a `**Live example**:` link
  to a real `tests/.../*.yml` → `## See Also`.
- [ ] Injection points follow the proven `*InjectionSteps` pattern
  (`PreBuildInjectionSteps`, `PostTestInjectionSteps`).
- [ ] Optional **steps** use a boolean enable param (ADR-0009); optional **tools**
  are opt-in by **config presence**, not a boolean flag (ADR-0041). No
  commented-out YAML shipped as a toggle.

### `schemas/` — brief in-file block + external definition doc

Source: `update-documentation.instructions.md` → section 3, and
`docs/developers/reference/schema-validation.md`.

- [ ] Brief comment block only: `# Schema Template: Name` / one-line purpose /
  `# See:` link.
- [ ] Validation uses the compile-time one-key-mapping pattern
  (`- "<message>": "Error"` under a `${{ if ... }}` guard) for required-field,
  type, and allowed-value checks.
- [ ] Every error message ends with a `See:` link to the definition doc.
- [ ] Definition doc exists/updated under `docs/definition_docs/<pipeline>/` (or
  `shared/`): property list, required vs optional, accepted types/values, and a
  YAML example of the object shape that matches the schema.

### `tests/` — compile tests and e2e fixtures

Source: `docs/developers/how-to/test-a-template.md` and the
*Testing a New or Changed Template* section.

- [ ] New/changed template has a `*_test.yml` fixture under
  `tests/<area>/<template-name>/` that references the template as a consumer
  would, pinning the repo resource `ref` to `${{ variables['Build.SourceBranch'] }}`.
- [ ] `*.CompileTests.ps1` expectations (`ExpectedYaml`, `ErrorMessage`) match the
  template's **current** compiled output — e.g. after swapping a raw `script` for
  a first-party task, the expected tokens were updated too.
- [ ] e2e fixtures are linked from the user doc's `**Live example**` entries.
- [ ] Note for the author: the compile/e2e framework resolves YAML against the
  **remote** branch ref, so fixtures can only go green once the branch is pushed —
  don't report "tests fail locally" as a template defect when the cause is an
  unpushed ref.

### Documentation (`docs/`, `*.md`)

Source: `markdown.instructions.md` and `update-documentation.instructions.md`.

- [ ] Markdown rules: hierarchical headings (flag H4+, strongly flag H5), fenced
  code blocks with a language id, valid relative links, tables for tabular data,
  no hard-wrapping of prose.
- [ ] YAML examples in docs are accurate (match current parameters/defaults),
  runnable, and 2-space indented.
- [ ] Cross-links between `user-docs` ⇄ `definition_docs` are present and valid.

### `.github/` and conventions

Source: `docs/developers/explanation/ai-and-documentation.md`.

- [ ] If the change alters a documented convention, the matching `.github/`
  instruction file was updated in the **same** PR.
- [ ] The `.github/` file doesn't restate doc content that will go stale — it
  encodes enforceable wording and points to the human doc.

---

## Cross-file contract (the "did they update the siblings?" pass)

From `update-documentation.instructions.md` → *Downstream Documentation Effects*
and the per-template **Definition of Done** (draft → schema validation → compile
tests → e2e tests → definition docs → user docs → review → release):

| If the change touched… | Also expect in the same change |
|---|---|
| A `tasks/`/`utils/` parameter | its in-file comment block |
| A `jobs/`/`pipelines/` parameter | `docs/user-docs/<area>/<name>.md` |
| A `schemas/` rule | schema comment block + `docs/definition_docs/` (+ user doc if it affects usage) |
| A new `jobs/`/`pipelines/` template | user doc **and** `docs/user-docs/README.md` entry |
| A new template (any) | compile test + e2e fixture |
| Any breaking change | `CHANGELOG.md` + major version bump + migration notes + inline comments |
| Any notable change | a `CHANGELOG.md` entry under `## [Unreleased]` (Added/Changed/Fixed/Removed/Deprecated) |

Missing a sibling is a real finding — surface it, don't assume it's out of scope.

---

## Versioning & CHANGELOG

Source: `docs/developers/reference/versioning-policy.md` and
`docs/developers/how-to/update-the-changelog.md`.

- The **breaking-change boundary is the public API** of `pipelines/`/`jobs/`
  templates (and, for this work, the published **artifact surface** — ADR-0035).
  Changing a parameter contract or a publish destination is breaking; changing an
  internal task implementation or a report's output is not.
- Breaking change ⇒ major bump + `CHANGELOG.md` entry prefixed **BREAKING** +
  migration steps + inline comments in the affected template.
- Entries go under `## [Unreleased]` in the correct subsection.

---

## Severity guidance

Classify each finding so the author can triage:

- **Blocker** — breaks the build/compile, ships a secret, forces a paid
  extension, introduces a `.yaml` file, or a breaking change with no version
  bump/CHANGELOG. Must fix before merge.
- **Major** — missing required documentation/test sibling, missing config-object
  schema, overridable internal variable (no `readonly`), double-wrapping, wrong
  documentation format for the template type.
- **Minor** — naming/formatting, `.editorconfig` nits, imprecise `displayName`,
  stale example.
- **Nit / Question** — style preference or a point needing author clarification.

Do not invent rules the repository doesn't hold. If something looks wrong but you
can't tie it to a documented convention, raise it as a **Question**, not a
Blocker.

---

## Output format

Produce the review as:

1. **Summary** — 1–3 sentences: what the change does and the overall verdict
   (approve / approve-with-nits / changes-requested).
2. **Findings** — grouped by severity, highest first. Each finding:
   - `path/to/file.yml:Lstart-Lend` — one-line problem statement.
   - **Why**: the specific rule or doc it violates (name the file/section).
   - **Fix**: the concrete change to make (a short snippet where it helps).
3. **Definition-of-Done checklist** — tick/cross the DoD items for the templates
   touched (draft, schema validation, compile tests, e2e tests, definition docs,
   user docs, CHANGELOG/release), so gaps are visible at a glance.
4. **Questions** — anything needing author input.

Keep it skimmable. Prefer a bulleted finding with a precise citation over prose.
Reference line numbers from the current file so the author can jump straight to
the spot.

---

## What NOT to do

- **Don't restate rules from memory** as if authoritative — cite and, when unsure,
  read the linked file first. These conventions change.
- **Don't apply the wrong doc contract** (e.g. demanding an in-file block on a
  `jobs/` template, or a user doc for a `tasks/` template).
- **Don't flag unpushed-branch test failures** as template defects.
- **Don't rewrite the author's code** unless asked — review and propose; let them
  decide.
- **Don't approve** a change that adds/edits a template without checking its docs,
  tests, and `CHANGELOG.md` siblings.
