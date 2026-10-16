---
name: code-review
description: >
  Use when the user asks to review a pull request, diff, branch, or specific
  template/doc/test files in this Azure DevOps YAML pipeline templates repo — or
  asks "does this follow our conventions?" or requests a pre-merge check — to walk
  the change file-by-file against the repo's own standards (`docs/developers/`
  and `.github/instructions/*`), verify the sibling files that must change with it
  (docs, tests, README catalogue, CHANGELOG), and return findings grouped by
  severity with a concrete fix for each. NOT when the user only wants to author
  new template code or get a quick explanation with no review intent — use normal
  chat or an authoring skill instead.
license: MIT
---

# Code Review for Pipeline Templates

This skill reviews changes to this repository the way a careful maintainer would: against the repository's **own** written standards, not generic opinions. It deliberately does not restate every rule, because the rules live in the linked files and change over time. Read the linked file for the current wording before asserting a violation, and cite it in the finding.

## Sources of truth

| Topic                                                                            | Read                                                                                                       |
| -------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| Folder layout, public vs internal, documentation location per folder, invariants | `ARCHITECTURE.md`                                                                                          |
| Why the repo is designed this way (rationale)                                    | `docs/developers/explanation/design-philosophy.md`, `double-wrapping.md`, `checkout-and-path-behaviour.md` |
| Parameters, variables, task documentation, anti-patterns, security               | `docs/developers/reference/template-conventions.md`                                                        |
| Compile-time validation patterns and error messages                              | `docs/developers/reference/schema-validation.md`                                                           |
| YAML limits, formatting, naming                                                  | `docs/developers/reference/yaml-standards.md`                                                              |
| Scripting language and file paths                                                | `docs/developers/reference/scripts-and-tooling.md`                                                         |
| SemVer scope and breaking-change examples                                        | `docs/developers/reference/versioning-policy.md`                                                           |
| CHANGELOG format                                                                 | `docs/developers/how-to/update-the-changelog.md`                                                           |
| Tagging and breaking-change process                                              | `docs/developers/how-to/release-a-version.md`                                                              |
| Writing and running tests                                                        | `docs/developers/how-to/test-a-template.md`                                                                |
| Branches and PR flow                                                             | `docs/developers/reference/branching-model.md`                                                             |
| Exact enforceable wording given to the AI                                        | `.github/copilot-instructions.md` and `.github/instructions/*.instructions.md`                             |

> **Policy precedence** (from `docs/developers/explanation/ai-and-documentation.md`): the human docs under `docs/developers/` are authoritative for _policy_; the `.github/` files are authoritative for the exact _enforceable wording_. If they disagree, flag the disagreement rather than silently picking one.

This repository does **not** use Architecture Decision Records. The rationale for a decision lives in the `explanation/` pages (chiefly Design Philosophy) and the `reference/` pages. Never cite an ADR number; cite the doc and section.

---

## When to use this skill

- Reviewing a PR, branch, or diff before merge.
- Checking whether a new or changed template follows conventions.
- Sanity-checking that documentation, tests, and `CHANGELOG.md` were updated alongside a code change.

If the user has not told you the scope, determine it from the diff (`get_changed_files`) or ask which branch/PR to review.

---

## How to run a review

1. **Scope the change.** Get the list of changed files (staged and unstaged, or the PR's files). Group them by area: `pipelines/`, `jobs/`, `stages/`, `tasks/`, `utils/`, `schemas/`, `scripts/`, `tools/`, `tests/`, `docs/`, `.github/`, `cicd/`, and root files (`README.md`, `CHANGELOG.md`, `ARCHITECTURE.md`, `CONTRIBUTING.md`).
2. **Read each changed file in full**, plus anything it depends on for context (the template a test exercises, the schema a job includes, the doc a template mirrors).
3. **Apply the checklist for each area.** Each folder has a different documentation and testing contract (see `ARCHITECTURE.md` → Documentation Location by Folder). Do not apply job rules to a task, or the reverse.
4. **Verify the sibling files.** A single logical change usually touches a template _and_ its docs _and_ its tests _and_ `CHANGELOG.md`. A missing sibling is the most common and most important finding.
5. **Don't duplicate CI.** The Lint workflow (`.github/workflows/lint.yml`) already runs editorconfig-checker, yamlfmt, yamllint, markdownlint-cli2, PSScriptAnalyzer and gitleaks. Only raise a formatting or secret issue yourself if it is semantic or something those tools would miss.
6. **Report** using the output format at the end, citing the specific doc for every finding.

---

## Ground rules (apply to every file)

- **`.yml`, never `.yaml`.** Reject any new `.yaml` file. (`yaml-standards.md`)
- **Formatting** follows `.editorconfig`: 2-space indent, LF, final newline, no trailing whitespace. (`yaml-standards.md`)
- **Azure DevOps YAML limits**: no anchors/aliases, merge keys, custom tags, or multi-document `---`. (`yaml-standards.md`)
- **Template filenames** are `lowercase_snakecase`, with no type in the name (`template.yml`, not `job_template.yml`); list templates use a suffix such as `_job_list`. (`yaml-standards.md`)
- **Placement**: runtime scripts that ship to consumers go in `scripts/`; scripts for maintaining this repo go in `tools/`; templates go in the folder matching their level; no new top-level folders without team discussion. (`ARCHITECTURE.md` → Placement Rules)
- **Public vs internal**: only `pipelines/` and `jobs/` are public and versioned. Internal folders must not be referenced by consumers or presented as consumer-facing in docs. (`ARCHITECTURE.md`)
- **Cross-platform scripting**: `pwsh`, not `powershell` or `bash`; PowerShell is preferred, Bash is allowed only for rare Linux file operations PowerShell cannot do, Batch is prohibited; no hardcoded path separators or OS-specific built-ins; no assumed agent image. (`scripts-and-tooling.md`, `design-philosophy.md`)
- **Paths** are based on standard Azure DevOps variables such as `$(Pipeline.Workspace)`. (`scripts-and-tooling.md`)
- **Open-source / built-in tasks only**: nothing that forces consumers to install a paid Marketplace extension. (`design-philosophy.md` → Cross-Platform and Open-Source by Default)
- **No hardcoded secrets**: use Key Vault (`tasks/azure_key_vault.yml`) or variable groups, and mark secret variables `isSecret`. (`template-conventions.md` → Security)
- **`readonly: true`** on every template-internal variable so consumers cannot override it. (`template-conventions.md` → Protecting Template-Internal Variables)
- **No double-wrapping**: do not wrap a template just to preset defaults. Allowed exceptions are cross-level orchestration, combining unrelated templates, and enforcing extra validation. (`double-wrapping.md`)
- **Fail fast / defensive rendering**: input is validated at compile time, and a template either produces valid output or a clear compile-time error. (`design-philosophy.md`)
- **Anti-patterns**: build and deploy mixed in one stage, overly broad `trigger`/`pr`, excessive parameterisation, inconsistent naming. (`template-conventions.md` → Anti-Patterns)
- **`displayName`** on every step, job, and stage. (`yaml-standards.md`)

### Parameters

Source: `template-conventions.md` → Parameters.

- [ ] Every parameter has `name`, `type`, `displayName`, and where applicable `default` and `values`.
- [ ] Required parameters have **no** default, carry a `# NO default` style comment, and end the `displayName` with `(required)`.
- [ ] Conditionally required parameters default to `''` and state the condition in the `displayName`.
- [ ] Names are PascalCase, use full words, and booleans are verb-prefixed (`EnableLogging`, `AllowFailure`).
- [ ] For `tasks/` and `utils/`, property order is `name`, `type`, `default` (or the `# NO default` comment), `values`, `displayName`.
- [ ] Related values are grouped into one object parameter validated by a schema, rather than many loose parameters.
- [ ] Generic parameters (`Condition`, `DependsOn`, `Pool`, and the artifact-name parameter) are named consistently with the sibling Terraform templates. Compare against the neighbouring template rather than assuming a fixed list.

---

## Checklist by area

### `tasks/` and `utils/` — in-file documentation is the sole doc

Source: `template-conventions.md` → Task Template File Documentation, and the in-file format in `.github/instructions/azure-devops-pipelines.instructions.md`.

- [ ] Has the top-of-file comment block with Purpose, Parameters, Example Usage, and Notes (with a `See:` link to the Microsoft task reference where relevant).
- [ ] The `Parameters:` block matches the real `parameters:` list: names, types, required vs optional, enum `Values:`, and `Default:` for optionals only.
- [ ] If a parameter was added, removed, renamed, or retyped, or a default changed, the comment block **and** any affected Example Usage were updated in the same change.
- [ ] No paid Marketplace task introduced (see ground rules).
- [ ] Optional: a `*.CompileTests.ps1` using `Run-Tests` with `ValidTestCases` / `InvalidTestCases` where behaviour or validation warrants it.

### `jobs/`, `pipelines/`, `stages/` — external docs, no big in-file block

Source: `ARCHITECTURE.md` → Documentation Location by Folder, and `update-documentation.instructions.md` sections 2 and 2a.

- [ ] **No** comprehensive in-file comment block; relies on `displayName` and self-documenting parameter names. A short orientation header is fine.
- [ ] `jobs/` and `pipelines/`: the mirrored user doc exists and is updated (`jobs/<name>.yml` → `docs/user-docs/jobs/<name>.md`; same for `pipelines/`). `stages/` get external docs where complex enough to need one.
- [ ] The user doc follows the concise skeleton: H1 and a one-line description, a commented-defaults invocation block, `---` rules, an Output/Artifact section where relevant, `## Examples` with `**Live example**:` links to real `tests/.../*.yml` fixtures, and `## See Also`. It must not grow verbose parameter tables.
- [ ] A **new** public template is added to the user docs index (`docs/user-docs/README.md`) **and** to the "What is available" tables in the root `README.md`.
- [ ] Injection points use the established `*InjectionSteps` pattern (for example `TerraformBuildInjectionSteps`).
- [ ] Terraform-family jobs expose consistent `TerraformVersion`, `EnvironmentName`, and config-object parameters; check the sibling job for the established shape.
- [ ] Jobs that check out this repository for their own scripts take a `CheckoutAlias` parameter defaulting to `AzDOPipelineTemplates` (see `jobs/terraform_deploy.yml`), and double-checkout jobs set an explicit `path` as described in `checkout-and-path-behaviour.md`.

### `schemas/` — brief in-file block, external definition doc

Source: `schema-validation.md`, `template-conventions.md` → Schema Template Documentation, `update-documentation.instructions.md` section 3.

- [ ] In-file block is brief only: `# Schema Template: Name`, a one-line purpose, and a `# See:` link.
- [ ] Every `See:` link (in the header and in error messages) points to a definition doc that actually exists. Verify the path.
- [ ] Guards use the one-key-mapping pattern (`- "<message>": "Error"` under a `${{ if ... }}`) emitted under the section the including template expects (`jobs:` or `steps:`).
- [ ] **Type detection uses `startsWith(convertToJson(x), '[')` / `'{'`, not `contains`.** `contains` matches anywhere in the JSON, so a string such as `vars[0].tfvars` is misclassified.
- [ ] Optional fields are validated only when present (the presence-gate pattern); required fields reject both missing and empty values.
- [ ] Error messages start with a label identifying the object, state the field and the rule, end with a `See:` link, and interpolate context such as `EnvironmentName` where it helps.
- [ ] The schema is actually included by its consuming job or stage. A schema that nothing includes validates nothing.
- [ ] The definition doc under `docs/definition_docs/` (in the consuming pipeline's folder, or `shared/`) matches the rules: properties, required vs optional, accepted values, and a YAML example.
- [ ] There are `InvalidTestCases` with an `ErrorMessage` for each new rule and `ValidTestCases` for accepted input.

### `scripts/` and `tools/`

Source: `scripts-and-tooling.md`.

- [ ] PowerShell (`pwsh`), cross-platform, and in the right folder (`scripts/` for runtime, `tools/` for maintainers).
- [ ] The script is justified: the logic is too complex for a built-in task or compile-time expression, is runtime-specific, or has no built-in task equivalent.
- [ ] Passes PSScriptAnalyzer (CI covers this, so only comment on semantics).

### `tests/` — compile tests and fixtures

Source: `test-a-template.md`.

- [ ] A new or changed `jobs/` or `pipelines/` template has a `*_test.yml` fixture under `tests/<area>/<template-name>/` that references the template as a consumer would, with the repo resource `ref` pinned to `${{ variables['Build.SourceBranch'] }}`.
- [ ] Fixtures are named after the scenario they exercise and are linked from the user doc's `**Live example**` entries.
- [ ] `ExpectedYaml` and `ErrorMessage` expectations match the template's **current** compiled output.
- [ ] Compilation goes through the Azure DevOps REST API against a branch ref, so tests generally need the branch pushed. Don't report "fails locally" as a template defect when the cause is an unpushed branch.
- [ ] The compile suite verifies YAML expansion only. If a change depends on runtime behaviour, check the PR describes how it was verified in Azure DevOps.

### Documentation (`docs/`, `*.md`)

Source: `.github/instructions/markdown.instructions.md` and `update-documentation.instructions.md`.

- [ ] Hierarchical headings (flag H4 and below, more strongly H5), fenced code blocks with a language id, valid relative links, tables for tabular data, no hard-wrapped prose.
- [ ] YAML examples match the current parameters and defaults, and use 2-space indentation.
- [ ] `user-docs` and `definition_docs` cross-link where a complex object parameter is involved.
- [ ] Documentation does not restate rationale that belongs in `explanation/`, or fast-changing detail that belongs in `reference/` (`ARCHITECTURE.md` intro).
- [ ] The root `README.md` stays free of named internal templates and reasons that go stale; it lists only the public catalogue.
- [ ] Markdown lint passes. CI runs `npx --yes markdownlint-cli2@0.14.0 "**/*.md" "#node_modules"`; there is no `npm run` lint script in this repo.

### `.github/` and conventions

Source: `ai-and-documentation.md`.

- [ ] If the change alters a documented convention, the matching `.github/` instruction file was updated in the **same** PR.
- [ ] A `.github/` file encodes enforceable wording and points to the human doc rather than restating content that will go stale.

---

## Cross-file contract (the "did they update the siblings?" pass)

Source: `update-documentation.instructions.md` → Downstream Documentation Effects, plus the sections above.

| If the change touched                  | Also expect in the same change                                                                                               |
| -------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| A `tasks/` or `utils/` parameter       | The in-file comment block                                                                                                    |
| A `jobs/` or `pipelines/` parameter    | `docs/user-docs/<area>/<name>.md`                                                                                            |
| A `schemas/` rule                      | Schema comment block, `docs/definition_docs/`, and `InvalidTestCases`/`ValidTestCases`; the user doc too if it affects usage |
| A new `jobs/` or `pipelines/` template | User doc, `docs/user-docs/README.md` entry, root `README.md` catalogue row, and a test fixture                               |
| A new `tasks/` or `utils/` template    | In-file comment block, plus tests where behaviour warrants it                                                                |
| A convention or policy                 | The matching `docs/developers/` page and `.github/` instruction file                                                         |
| Any breaking change                    | `CHANGELOG.md` entry prefixed **BREAKING**, a major bump, a migration guide, and inline comments in the affected template    |
| Any notable change                     | A `CHANGELOG.md` entry under `## [Unreleased]`                                                                               |

A missing sibling is a real finding. Treat it as satisfied only if the PR description links a companion docs PR (the PR process in `test-a-template.md` allows separate code and docs PRs); otherwise surface it.

---

## Versioning and CHANGELOG

Source: `versioning-policy.md`, `release-a-version.md`, `update-the-changelog.md`.

- The breaking-change boundary is the **public API**: the parameters, outputs, and documented behaviour of `pipelines/` and `jobs/` templates. An internal change that is invisible to consumers is not breaking.
- Treat these as breaking even when they look minor: removing or renaming a parameter, changing a default, renaming a stage, job, or step that consumers reference, rearranging jobs or steps, and upgrading a tool version that has its own breaking changes (for example Terraform). Prefer optional parameters with safe defaults, and deprecate before removing.
- A breaking change needs a major bump, a `CHANGELOG.md` entry prefixed `**BREAKING**:`, a migration guide, and inline comments in the affected templates.
- CHANGELOG entries go under `## [Unreleased]` in the right subsection (Added, Changed, Deprecated, Fixed, Removed, Security), in the same PR as the change. They describe user impact in plain language, not file paths or implementation, give replacement guidance for deprecations, and leave out empty subsections.
- Releases are tagged `MAJOR.MINOR.PATCH` from `main` after validation. Tags are immutable: no moving tags such as `v1`, and no re-pointing a pushed tag.

---

## Severity guidance

- **Blocker**: breaks compilation, ships a secret, forces a paid extension, introduces a `.yaml` file, or is a breaking change with no major bump, CHANGELOG entry, or migration guide. Must fix before merge.
- **Major**: a missing required documentation or test sibling, a missing schema for a config object, an overridable internal variable (no `readonly`), double-wrapping, the wrong documentation format for the template type, a broken `See:` link in a schema, or an internal template exposed as public.
- **Minor**: naming or formatting that CI did not catch, imprecise `displayName`, a stale example, `contains` used where `startsWith` is needed in a way that does not currently misfire.
- **Nit / Question**: a style preference, or a point needing author clarification.

Do not invent rules the repository doesn't hold. If something looks wrong but you can't tie it to a documented convention, raise it as a **Question**, not a Blocker.

---

## Output format

Produce the review as:

1. **Summary**: 1–3 sentences on what the change does and the overall verdict (approve, approve-with-nits, or changes-requested).
2. **Findings**, grouped by severity, highest first. Each finding has:
   - `path/to/file.yml:Lstart-Lend`: a one-line problem statement.
   - **Why**: the specific rule or doc it violates (name the file and section).
   - **Fix**: the concrete change to make, with a short snippet where it helps.
3. **Sibling checklist**: tick or cross each sibling from the cross-file contract that applies (in-file block or user doc, definition doc, tests, README catalogue, CHANGELOG, `.github/` file), so gaps are visible at a glance.
4. **Questions**: anything needing author input.

Keep it skimmable. Prefer a bulleted finding with a precise citation over prose, and reference line numbers from the current file so the author can jump straight to the spot.

---

## What NOT to do

- **Don't restate rules from memory** as if authoritative. Cite the doc, and read it first when unsure; these conventions change.
- **Don't cite ADRs.** There are none; point to the `explanation/` or `reference/` page instead.
- **Don't apply the wrong doc contract** (for example demanding an in-file block on a `jobs/` template, or a user doc for a `tasks/` template).
- **Don't flag unpushed-branch test failures** as template defects.
- **Don't repeat what CI already checks** (editorconfig, yamlfmt, yamllint, markdownlint, PSScriptAnalyzer, gitleaks) unless the tools missed it.
- **Don't rewrite the author's code** unless asked. Review and propose; let them decide.
- **Don't approve** a change that adds or edits a template without checking its docs, tests, and `CHANGELOG.md` siblings.
