# AI & Documentation

## Using AI Tools

- AI is useful for generating boilerplate, structuring YAML, and drafting documentation.
- Azure DevOps YAML has limited training data — always **validate and test** AI output in Azure DevOps.
- Use AI for repetitive tasks (parameter blocks, documentation summaries). Do not rely on AI for complex template logic.

## Review & Maintenance

- All AI-generated content must be reviewed by a human before merging.
- Submit AI-generated changes via pull requests for discussion.
- When repository practices change, update the relevant `.github/` file directly (see below). Do not describe their contents here — that content goes stale the moment the file changes.

## AI Agent Files in This Repository

This repository uses GitHub Copilot via files under `.github/`. This page intentionally does not restate what each file says — read the file itself for current rules. It only answers: which files exist, when they load, and who owns them.

| File | Loads | Owner |
|---|---|---|
| `.github/copilot-instructions.md` | Always (repo-wide) | Whoever changes a repo-wide convention |
| `.github/instructions/*.instructions.md` | Automatically, scoped to files matching each file's `applyTo` glob | Whoever changes the convention it encodes |

There are no `.github/prompts/*.prompt.md` files in this repository; agent behaviour is driven solely by `copilot-instructions.md` and the `instructions/` files above.

If you change a convention documented in this repo, update the matching `.github/` file in the same Pull Request. If a `.github/` file and a human doc disagree, the human doc (this one, or the relevant reference page) is authoritative for policy; the `.github/` file is authoritative only for exact enforceable wording given to the AI.
