---
lens: operability
batch: 2
applies_when: "the diff changes a request path, a background job, or an external call in a deployed service. It also applies when the diff adds a migration, a configuration value, or a feature flag."
tier:
  claude: { model: sonnet, effort: high }
  codex: { model: gpt-6.1-sol, effort: high }
intent:
  concern: "`design.md`, for the rollout plan and any observability it names."
  pr: "the PR body, and the logging, metrics, and configuration patterns the service already uses."
---
# Operability

## Question
When this change fails in production, can an operator see it, find its cause, and undo it?

## Finding
location · concrete failure, or before and after · fix · severity (bug | risk | nit).

## Out of mandate
What the code does when it fails belongs to `failure-modes`.
A secret in a log line belongs to `security`.
A document the change makes false belongs to `claims`.

## What this lens hunts for

- An error the code catches and drops, with no log line and no metric.
- A log line with no identifier that ties it to a request, a job, or a record.
- A new external call with no metric for its errors or its latency.
- A new configuration value with no default, no check at startup, and no documentation.
- A migration with no way back, or a feature flag with no off state.
- A deploy-order dependency, such as code that needs a column the migration has not yet added.

## Examples

- `jobs/sync_accounts.py:52` · `except Exception: pass` drops every failure. The job reports
  success, and nobody learns that 30 accounts failed. Fix: log the account id, and count the failure
  in a metric. Severity `risk`.
- `config/services.php:20` · the new `PAYMENTS_WEBHOOK_SECRET` has no default and no startup check.
  A deploy without it fails on the first webhook, not at boot. Fix: check it at boot. Severity `risk`.

## What does not count

- A script or a library that no service deploys.
- A metrics or tracing system the service does not already run.
