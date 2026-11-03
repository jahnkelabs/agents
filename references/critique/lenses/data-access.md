---
lens: data-access
batch: 2
applies_when: "the diff touches a database query, an ORM relation, a migration, a schema, or a cache. It also applies when the diff adds a loop that calls a remote service."
tier: { model: sonnet, effort: high }
intent:
  concern: "`design.md` for the data model and its expected volumes, and `requirements.md` for any stated limit."
  pr: "the PR body, and the schema, indexes, and query patterns the repository already holds."
  plan: "this milestone's work item and the plan pad's `## Design` section."
---
# Data access and performance

## Question
Which query, migration, or loop costs more than the change needs as the data grows?

## Finding
location · concrete failure, or before and after · fix · severity (bug | risk | nit).

## Out of mandate
A query that returns the wrong rows belongs to `correctness`.
A data model that departs from the design belongs to `design-conformance`.
A query built from outside input belongs to `security`.

## What this lens hunts for

- One query per row, where one query with a join or an eager load serves every row.
- A new filter or join on a column with no index.
- A fetch with no limit, on a table that grows.
- A migration that locks or rewrites a large table while the service writes to it.
- A cache with no bound, or a loop of remote calls that a batch call replaces.

Every finding names the input size at which the cost matters.

## Examples

- `app/Http/Controllers/OrderController.php:40` · reads `$order->customer->name` inside a loop. A
  page of 500 orders runs 501 queries. Fix: `Order::with('customer')->paginate()`. Severity `risk`.
- `migrations/20261103_index_events.sql:3` · `CREATE INDEX ON events (user_id)` blocks writes to
  `events`, which holds 40 million rows. Fix: `CREATE INDEX CONCURRENTLY`. Severity `risk`.

## What does not count

- A cost with no input size that makes it matter.
- A small saving on a path that runs once per deploy or once per day.
