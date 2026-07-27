---
name: recall
description: Pull stashed work out of a tracker and back into active planning
argument-hint: "[issue-ref]"
disable-model-invocation: true
effort: medium
---

# Recall

The inverse of `/stash`. Pulls a tracker item into Solo and hands it to `/plan`.

Recall **always seeds planning** — it never restores something ready to implement. A stashed
item is input, not a finished plan:

- A plan parked weeks ago rests on research the codebase has since invalidated
- A phase of a large plan was always meant to get its own research and planning cycle
- A loose idea was never planned at all

The grounding is re-derived. When nothing has changed, gate A's investigation step makes that
cheap — say so and it will look at very little.

## Step 1 — Resolve the reference

`$ARGUMENTS` is a tracker reference: an issue key (`ENG-142`, `PROJ-88`), a URL, or a project
name.

With no arguments, list what is parked — open issues you own or that were created by `/stash`
— and ask.

Pick the adapter in `~/.claude/references/` matching the reference's tracker.

## Step 2 — Pull the item and its context

Fetch more than the issue itself. A phase makes little sense alone:

- The issue: title, description, state, labels
- Its parent project or epic, and any attached plan document
- Sibling issues and their dependencies — what must land first, what waits on this
- Whether blocking issues are already done

Do not report the pull on its own — it lands in the gate in step 3, so the user sees what was
pulled and what it implies for scope in one place.

If blockers are still open, say so before going further. Recalling a phase whose prerequisite
has not landed is usually a mistake, and the user may want a different item.

## Step 3 — Hand to /plan

Write the pulled content into a Solo pad as planning input, then invoke `/plan` with it.

`/plan` runs normally from there: gate A proposes scope and investigation, gate B grills, gate
E approves and forks. The tracker content becomes context, not a substitute for any of it.

```
→ starting /plan with this as input

Pulled from <tracker>:
  project   <name>
  issue     <ID> — <title>
  context   parent document, blocked by <ID> (done)
  siblings  <ID> Phase 3 — waits on this

Before I investigate — confirm or adjust:

  Solo project: <name>  (<path>)

  Repos in scope:
    <repo>  ─ named in the issue; N code refs in the parent document

  I plan to investigate (2 parallel Solo agents):
    1. what Phase 1 actually landed vs. what it planned
    2. current state of <the area this phase touches>

Accept, or tell me what to add or cut.
```

That first investigation item matters: when recalling a later phase, what earlier phases
*actually did* may differ from what they said they would.

## Step 4 — Leave the tracker alone

Do not modify the tracker item during recall. Nothing has happened to it yet — planning may
conclude the work should change shape or be dropped.

The tracker is updated later:

- `/implement` moves it to in-progress when work starts
- `/stash` reconciles if the plan is parked again
- Closing it happens when the PR merges, by whatever process you already use

Note the recalled ref in the plan pad's `## References` so the connection survives.

## Notes

- Recall never skips straight to `/implement`
- Pull the parent context, not just the issue
- Warn on unmet blockers rather than proceeding silently
- Recall is read-only against the tracker
