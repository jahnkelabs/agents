# Simplicity

Batch: 2.
Applies when: always.
Tier: sonnet · high.
Question: Which part of the change could be smaller or plainer, with the same behavior?
Intent source:
  concern: `design.md`, for the structure a rewrite must keep.
  pr: the PR body, for the behavior a rewrite must keep.
  plan: this milestone's work item in the plan pad, for the behavior a rewrite must keep.
Finding: location · before and after, always · fix · severity (bug | risk | nit).
Out of mandate: code that rebuilds an existing helper belongs to `idiom-and-reuse`.
  Scope the requirements never asked for belongs to `requirements-fidelity`.
  A structural departure from the design belongs to `design-conformance`.

**Every finding carries a concrete before and after.** The engine drops a finding with no rewrite.

## What this lens hunts for

- An interface with one implementation, or a config option with one caller. `rules/yagni.md` names both.
- Dead code, and a branch no input reaches.
- Nested conditions that a guard clause flattens.
- A variable or a function used once, where the inline form reads more plainly.
- A comment that restates the code. `rules/comment-discipline.md` disallows it.

Most findings here are `nit`. Use `risk` where the complexity hides a defect.

## Examples

`src/paths.py:10` · an interface with one implementation, selected through config. Fix: delete
`PathResolver` and the `path_resolver` key. Severity `nit`.

```python
# before
resolver = RESOLVERS[config["path_resolver"]]()
path = resolver.resolve(name)

# after
path = resolve_local(name)
```

`src/orders.ts:52` · three nested conditions around one return. Fix: return early. Severity `nit`.

```ts
// before
if (order) { if (order.paid) { if (!order.shipped) { return ship(order) } } }
return null

// after
if (!order?.paid || order.shipped) return null
return ship(order)
```

## What does not count

- A rewrite that changes behavior, on any input.
- A preference with no shorter or plainer result.
- A rewrite you cannot show.
