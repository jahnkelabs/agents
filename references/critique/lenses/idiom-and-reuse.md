---
lens: idiom-and-reuse
batch: 2
applies_when: always
tier:
  claude: { model: sonnet, effort: high }
  codex: { model: gpt-6.1-sol, effort: high }
intent:
  concern: "`design.md`, for the conventions it adopts."
  pr: "the conventions in the files around the diff, and the repository's own rules and lint config."
  plan: "the plan pad's `## Design` section, and the repository's rules."
---
# Idiom and reuse

## Question
Does the change rebuild what the codebase already provides, or break an idiom the codebase uses?

## Finding
location · before and after, always · fix · severity (bug | risk | nit).

**Every finding carries a concrete before and after.** The after names the existing helper, with
its file and line. The engine drops a finding with no rewrite.

## Out of mandate
A smaller rewrite with no existing helper belongs to `simplicity`.
A module boundary or an architectural choice belongs to `design-conformance`.
A document the change makes false belongs to `claims`.

## What this lens hunts for

- A helper, utility, or type that the codebase already defines, rebuilt by hand.
- A library function that a dependency the repository already uses provides.
- A departure from the pattern the codebase uses in every similar place.
  Check the error shape, naming, file layout, and test style.

## Examples

`src/api/handler.ts:40` · builds an error response by hand. The codebase returns errors through
`problem()` at `src/api/errors.ts:12`. Fix: call `problem()`. Severity `nit`.

```ts
// before
res.status(404).json({ error: "not found", code: 404 })

// after
return problem(res, 404, "order not found")
```

`app/Services/Report.php:22` · a hand-written loop over dates. `app/Support/Dates.php:14` already
wraps `CarbonPeriod`. Fix: call `Dates::eachDay()`. Severity `nit`.

```php
// before
for ($d = $from->copy(); $d->lte($to); $d->addDay()) { $days[] = $d->copy(); }

// after
$days = Dates::eachDay($from, $to);
```

## What does not count

- An idiom the codebase uses in one place only.
- A library the repository does not yet depend on. A new dependency is a design question.
- A rewrite you cannot show.
