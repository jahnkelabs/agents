---
lens: correctness
batch: 2
applies_when: always
tier:
  claude: { model: opus, effort: high }
  codex: { model: gpt-6-astra, effort: high }
intent:
  concern: "`requirements.md`, for what a right result is."
  pr: "the PR body and the linked issue, for what a right result is."
  plan: "this milestone's work item in the plan pad, for what a right result is."
---
# Correctness

## Question
Where does the change produce a wrong result on valid input?

## Finding
location · concrete failure, or before and after · fix · severity (bug | risk | nit).

## Out of mandate
Empty, malformed, oversized, or concurrent input belongs to `failure-modes`.
Behavior the requirements never approved belongs to `requirements-fidelity`.
An exploit belongs to `security`, and a slow query belongs to `data-access`.

## What this lens hunts for

- An off-by-one, a wrong operator, an inverted condition, or a wrong unit.
- A wrong key, field, or default, or a value read before the code updates it.
- A caller, inside the repository or a client of it, that the changed callee now breaks.
- A branch that returns the right type with the wrong value.

Every finding names a concrete input and the wrong output it produces.

## Examples

- `src/pagination.ts:31` · `offset = page * size`, and `page` starts at 1. Input `page=1, size=20`
  skips the first 20 rows. Fix: `offset = (page - 1) * size`. Severity `bug`.
- `api/users.go:77` · the change renames the JSON tag `Email` to `email`. The iOS client at
  `clients/ios/User.swift:12` still decodes `Email`, and every user arrives with no address. Fix:
  keep the old tag, or change both sides together. Severity `bug`.

## What does not count

- A result you believe is wrong, with no input that shows it.
- Style, naming, or structure. `simplicity` and `idiom-and-reuse` own those.
