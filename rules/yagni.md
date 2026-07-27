---
description: Build for the present need; defer what is cheap to add later
---

# YAGNI

Build what the present need requires and no more. A more general solution may well be worth building—but it is a **proposal**, not a starting point, and complexity added today needs a grounded justification rather than an imagined future caller.

This governs code, process, and artifacts: abstractions, config surfaces, and extension points in code; extra phases, enforcement tooling, and scripts in process; template sections that exist for a hypothetical future reader. It does not govern requirements—it is never an argument that the user asked for more than they need.

## Rule of thumb

**Defer what is cheap to add later; do not defer what is expensive to retrofit.**

A security model, a data model, and a published contract are all expensive to retrofit, so those are decided now. A second config knob, a strategy seam, or a plugin hook is cheap to add the day a second caller exists. The cost of being wrong runs in both directions and is asymmetric in each—which is why this is an argument about cost rather than an argument for doing less.

## Default policy

- **Default:** Build for the need at hand—the caller that exists, the case in front of the work, the reader who is actually there.
- **Generality:** A more general design is named as an option and left unbuilt until a second real case arrives.
- **Exceptions:** Structures that are expensive to retrofit—security boundaries, data models, published contracts, storage formats—are designed up front.

## What this does not license

Correctness, error handling, security, and tests for the code being written now are part of the need at hand. Declining to build them is a **defect, not restraint**—the present need includes the code working, failing safely, and being verified.

## Disclosure, not offer

Naming a deliberately declined alternative is disclosure of a decision rather than an offer of adjacent work. When a simpler path is chosen over a more general one that was genuinely considered, name the alternative in **one line at the point of the decision**—and never generate alternatives in order to have something to offer.

During planning that same disclosure belongs in the pad's `## What We're NOT Doing` section rather than in chat.

## Example

One caller needs one path resolved:

**Prefer:** A function taking the single path its caller has, with a second parameter added the day a second caller needs one.

**Avoid:** A `PathResolver` interface with one `LocalPathResolver` implementation, selected through config, because a remote resolver might be wanted later.

## Anti-patterns

| Anti-pattern | Why it fails |
|---|---|
| A config option with a single caller | The call site is the configuration—the knob adds a surface with no second value |
| A strategy interface with one implementation | The seam is a guess, and the second implementation rarely fits where it was cut |
| Enforcement tooling for a policy that has not been written | The script encodes a rule nobody agreed to, then quietly becomes the rule |
| A template section serving a hypothetical reader | Every real reader skips it, and it still has to be maintained |
