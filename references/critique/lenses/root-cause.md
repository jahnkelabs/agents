---
lens: root-cause
batch: 1
applies_when: always
tier:
  claude: { model: opus, effort: high }
  codex: { model: gpt-6-astra, effort: high }
intent:
  concern: "`requirements.md` for the problem the concern solves, and `design.md` for where its fix belongs."
  pr: "the PR body and the linked issue, read as the bug report or the problem statement."
---
# Root cause

## Question
Which part of the change works around a symptom, and is its cause local or shared?

## Finding
location · concrete failure, or before and after · fix · severity (bug | risk | nit).

## Out of mandate
The wrong result a symptom produces belongs to `correctness`.
A missing error path belongs to `failure-modes`.
Whether a fix matches the design belongs to `design-conformance`.

## What this lens hunts for

A workaround takes one of four shapes: a special case, a guard, a retry, or a flag. For each one,
ask what produces the bad state it handles. Trace that cause to a file and a line.

Then decide where the cause lives:

- **Local:** the cause sits in code this concern owns. The fix removes the cause there, and the
  workaround goes with it. The finding carries `scope: local`.
- **Systemic:** the cause sits in code outside this concern, or other callers share it. The finding
  carries `scope: systemic`.

**A systemic cause becomes a proposed map edit, never a local patch.** The fix names a new concern.
That concern states the shared cause, its location, and the callers it affects. The finding
proposes no change to code, inside this concern or outside it, and no better workaround. In
`apply` mode, the critique appends each systemic finding to the map's `map.md`, under
`## Proposed edits`, and the ledger's `proposed edit:` line carries it into `Landed`.

## Examples

- `src/billing/invoice.py:142` · `if total < 0: total = 0` hides a negative total. The cause is
  `apply_discount()` at `:88`, which subtracts the discount twice when a coupon and a promotion
  stack. Scope local. Fix: apply the discount once at `:88`, and delete the guard. Severity `bug`.
- `src/sync/client.py:60` · the change wraps the fetch in three retries. The cause is the shared
  client at `lib/http.py:20`, which sets no connect timeout, so every caller hangs. Scope systemic.
  Fix: propose the concern "set a connect timeout in the shared HTTP client", naming `lib/http.py:20`
  and its four callers. Severity `risk`.
- `config/features.yml:14` · the flag `legacy_csv_parse` routes one customer's files to the old
  parser. The cause is the new parser at `src/csv.py:31`, which rejects a byte-order mark. Scope
  local. Fix: strip the mark at `:31`, and delete the flag. Severity `risk`.

## What does not count

- A guard at a trust boundary that validates outside input. That guard is the design, not a
  workaround.
- A bounded retry against a transient failure that the dependency documents, such as a network call.
- A cause you cannot trace to a line. Name the line, or drop the finding.
