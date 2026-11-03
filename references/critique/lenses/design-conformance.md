# Design conformance

Batch: 1.
Applies when: always.
Tier: opus · high.
Question: Does the change follow the approved design: its boundaries, data model, interfaces, and file structure?
Intent source:
  concern: `design.md`, every decision and each declined alternative.
  pr: the architecture the code around the diff already follows: its layers, module boundaries, and data flow.
  plan: the plan pad's `## Design` section, and the prose of this milestone's work item.
Finding: location · concrete failure, or before and after · fix · severity (bug | risk | nit).
Out of mandate: missing or extra behavior belongs to `requirements-fidelity`.
  A local rewrite that keeps the design belongs to `simplicity`.
  A local idiom or an existing helper belongs to `idiom-and-reuse`.

## What this lens hunts for

- A call that crosses a boundary the design draws, such as a controller that skips the service layer.
- A table, field, key, or message the design never names, or one it names that the change omits.
- An interface whose signature or contract differs from the one the design states.
- A file outside the design's file structure.
- A declined alternative that the change builds anyway.

## Examples

- `app/Http/Controllers/OrderController.php:58` · the design routes every write through
  `OrderService`. The controller calls `Order::create()` directly, so the audit event never fires.
  Fix: call `OrderService::place()`. Severity `bug`.
- `src/queue/worker.ts:12` · the design declines a second queue and reuses `jobs`. The change creates
  `jobs_priority`. Fix: use `jobs` with the `priority` field the design names. Severity `risk`.

## What does not count

- A design you would prefer. The user approved this one.
- A choice the design leaves open. Report only a departure from something the design states.
- On a PR, a departure from a convention that one file follows and the rest of the code does not.
