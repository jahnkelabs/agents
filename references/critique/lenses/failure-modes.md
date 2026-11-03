---
lens: failure-modes
batch: 2
applies_when: always
tier:
  claude: { model: opus, effort: high }
  codex: { model: gpt-6-astra, effort: high }
intent:
  concern: "`requirements.md` for stated limits and error behavior, and `design.md` for the failure handling it chose."
  pr: "the PR body and the linked issue, and the error handling the code around the diff already uses."
  plan: "this milestone's work item in the plan pad, its Exit criterion and Invariants."
---
# Failure modes

## Question
What does the change do on empty, null, malformed, oversized, or concurrent input, or when a dependency fails?

## Finding
location · concrete failure, or before and after · fix · severity (bug | risk | nit).

## Out of mandate
A wrong result on valid input belongs to `correctness`.
An error path with no test belongs to `tests`.
A failure an attacker can use belongs to `security`.
A failure nobody can observe belongs to `operability`.

## What this lens hunts for

- An empty collection, a null, a missing file, or a malformed record, read with no check.
- Input larger than the code expects: a list with no bound, or a file read whole into memory.
- Two writers that race, such as a read, then a write, with no lock or version check.
- A dependency that fails, hangs, or returns a partial result, with no timeout and no defined outcome.
- An error that the code catches and then leaves the system in a half-written state.

## Examples

- `worker/import.py:45` · `rows[0]` on a CSV with a header only raises `IndexError`. The job dies,
  and the import stays `running` forever. Fix: return early, and mark the import `empty`. Severity
  `bug`.
- `cache/store.go:30` · two requests miss the cache at once, and both write. The slower one
  overwrites a newer value with an older one. Fix: compare and set on the version. Severity `risk`.
- `clients/geo.rb:19` · the HTTP call sets no timeout. A stalled upstream holds the worker until the
  process restarts. Fix: set `open_timeout` and `read_timeout`. Severity `risk`.

## What does not count

- Input that the type system or an earlier check already excludes. Name the check you read.
- A failure with no reachable path from any caller.
