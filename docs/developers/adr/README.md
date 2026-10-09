# Architecture Decision Records

An ADR is a short, permanent record of one significant decision: why we chose it, and what it costs us. It gives "why" a permanent home so guides stop re-explaining it.

## Rules

- Numbered, append-only: `0001-title.md`, `0002-title.md`, etc.
- **Never edit an ADR after it is accepted.** If a decision changes, write a new ADR that supersedes the old one, and mark the old one's status as `Superseded by 00NN`.
- Reference the relevant ADR number in any Pull Request that implements or changes behaviour covered by it.
- Use [`0000-template.md`](0000-template.md) as the starting point for a new ADR.

## When to Write One

Write an ADR when a decision is significant enough that someone will ask "why did we do it this way?" months later — for example, choosing PowerShell over Bash, the set-menu (`pipelines/`) / salad-bar (`jobs/`) model, or dropping the nested feature-branch hierarchy. Day-to-day implementation choices do not need one.

## Index

| # | Title | Status |
|---|---|---|
| — | _No ADRs recorded yet._ | — |
