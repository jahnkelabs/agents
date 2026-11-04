---
name: requirements
description: Grill the user on one concern of a map, and write its outcome and acceptance criteria, each with a proof command that can fail
argument-hint: "<concern> | <map-slug>/<concern>"
---

# Requirements

Write what one concern must achieve, and how a machine proves that it did. This is a concern's
first stage. `/map` charted the concern, and `/design` follows. The user starts each stage.

This skill writes `<concern>/requirements.md` under `docs_dir`. It also moves the concern's
`stage`, and it can append a proposed edit to the map. It writes no design and no code.

`skills/map/SKILL.md` defines the docs directory, the frontmatter, and a concern's address under
`## The docs directory`. It defines the approval under `## Approval of a document`. Follow both as
written there.

## Input

`$ARGUMENTS` names one concern, as `<map-slug>/<concern>` or as `<concern>` alone. Resolve it by
the address rule in `/map`.

With no arguments:

> **Deciding — which concern**
>
> Which concern should I write requirements for? Name it as `<map-slug>/<concern>`.
>
> ⏸ waiting on you: name the concern

**Stop where the map still awaits its first approval**, with `awaiting: approve the map`. Send the
user to `/map <map-slug>`.

## Step 1 — Read

Read each of these fully:

- `map.md`: the destination, the principles, the decisions so far, the fog, and the out-of-scope
  list;
- the concern's `concern.md`, with every note in its body;
- each file under the map's `research/` that bears on this concern;
- the concern's `requirements.md`, where one exists, because this run then revises it;
- each pending edit under `map.md`'s `## Proposed edits` that names this concern.

`/map` has not applied a pending edit yet. Tell the user about each one that names this concern,
before the first question.

Then move the stage. Set `stage: requirements` in `concern.md` where it reads `open`. A later stage
stays as it is, and the revised document goes through approval again. Replace the body's
`Not started` line with `Documents: [[<concern>/requirements]]`.

## Step 2 — Grill

Follow `/grill`. Ask one question per message, in the shape `rules/chat-vocabulary.md` defines,
and wait for each answer.

Grill for four things:

- the outcome, which is what holds once the concern lands;
- the acceptance criteria, which are the end states a machine can check;
- the constraints from outside the concern: a platform, a principle, or another concern;
- what the concern does not do.

**Look a fact up rather than ask for it.** Where a fact needs more than a lookup, run `/research`
on it. Its report goes to `<docs_dir>/maps/<map-slug>/research/<topic>.md`. Ask the user only for
decisions.

**Leave how to build it to `/design`.** A question about files, data shapes, or interfaces belongs
to the next stage. Ask it here only where the outcome depends on the answer.

**A finding that changes the map goes to the map.** A new concern, a split, or new fog becomes a
numbered item under `map.md`'s `## Proposed edits`. `/map` applies or rejects it. Edit no other
section of `map.md`, apart from the decisions in step 4.

When the remaining questions are details the user would rather see than specify, propose
defaults. Flag each one as a proposal in the document, and move on to step 3.

## Step 3 — Write the document

Write `<docs_dir>/maps/<map-slug>/<concern>/requirements.md`:

```markdown
---
type: requirements
map: <map-slug>
concern: <concern>
status: draft
awaiting: null
---
## Outcome

<what holds once the concern lands, stated so that a reader can check it>

## Acceptance criteria

| Criterion | Proof command | Invariant |
|---|---|---|
| <an end state a machine can check> | `<the command that proves it>` | <what must not change while the concern reaches it> |

## Constraints

- <a limit from outside the concern>

## Not doing

- <an explicit non-goal, which keeps the scope fixed>
```

`## Outcome` and `## Acceptance criteria` always appear. Omit `## Constraints` or `## Not doing`
where nothing belongs there.

**Every acceptance criterion names a proof command.** Write a command, never a description.
`the tests pass` proves nothing, because nobody can run it.

**Every proof command must be able to fail.** Run each one against the current tree, where it can
run. It must fail there, because the concern has not landed yet. A command that passes already
proves nothing, so tighten it until it fails. A command that names a new test fails until someone
writes that test, so it needs no run.

**The invariant names what must not change** while the concern reaches its criterion. State it so
that a test can assert it, as in `the row count after the second import equals the first`.

**A check that no command can make is not a criterion.** State it under `## Outcome`, and the PR
review checks it.

**Leave no open question in the document.** Research it, ask it, or propose it to the map as fog.
An open question in approved requirements becomes a deviation inside `/implement`. One corpus
attributed 40 of 109 escalations to that ambiguity.

## Step 4 — Approve

Follow `## Approval of a document` in `/map`, with `awaiting: approve requirements`.

On approval, add one line to `map.md`'s `## Decisions so far` for each decision that shapes the
map or another concern. End each line with `See [[<concern>/requirements]].` Then report the
file's path, and stop:

```
Requirements: <docs_dir>/maps/<map-slug>/<concern>/requirements.md

Next: /design <map-slug>/<concern>
```
