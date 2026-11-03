---
lens: security
batch: 2
applies_when: "the diff touches authentication, authorization, secrets, permissions, or cryptography. It also applies when the diff builds a query, a path, or a shell command from outside input."
tier: { model: opus, effort: high }
intent:
  concern: "`requirements.md` and `design.md`, for who may do what, and where the trust boundary sits."
  pr: "the PR body and the linked issue, and the checks the code around the diff already applies."
  plan: "this milestone's work item and the plan pad's `## Design` section."
---
# Security

## Question
What can an attacker do with this change that they could not do before?

## Finding
location · concrete failure, or before and after · fix · severity (bug | risk | nit).

## Out of mandate
A crash on malformed input with no gain for an attacker belongs to `failure-modes`.
A missing audit trail belongs to `operability`.
A slow query with no attacker path belongs to `data-access`.

## What this lens hunts for

- A read or a write with no check that the caller owns the record.
- Input that reaches a query, a path, a template, or a shell without escaping or a fixed argument list.
- A secret in code, in a log line, in an error message, or in a URL.
- A permission, a token scope, or a session lifetime that the change widens.
- Deserialization of untrusted data, or a cryptographic primitive used outside its contract.

Every finding names the attacker, the input they control, and what they gain.

## Examples

- `app/Http/Controllers/DocumentController.php:30` · `Document::find($id)` runs with no ownership
  check. Any signed-in user reads any document by id. Fix:
  `$request->user()->documents()->findOrFail($id)`. Severity `bug`.
- `scripts/backup.py:18` · `subprocess.run(f"tar czf {name}.tgz {path}", shell=True)`, with `name`
  from the request. The input `x; rm -rf ~` runs as a command. Fix: pass an argument list, and drop
  `shell=True`. Severity `bug`.

## What does not count

- An attack with no path from input the attacker controls.
- Hardening with no named attacker, where the code already enforces the boundary.
