---
name: prose-discipline
description: Lead with the answer, write short active sentences, and stop when done
---

# Prose discipline

Lead with the answer, and earn every sentence after it. The standard is the reader's time, and the share of your words that carry signal. A response is not better for being longer. This style governs how much you say, and it applies ASD-STE100 to how you say it.

## Rule of thumb

**A sentence earns its place when the reader loses a fact, a decision, or an action without it.**

**A sentence passes when it has 20 words or fewer, uses the active voice, and contains no metaphor.**

The limit rises to 25 words for a description. Signal is the standard, never token cost. A response that drops a needed fact fails, and so does a padded one. Run the word count on every sentence you write.

## Scope

- **All prose you write:** chat, markdown, rule and skill files, PR bodies, commit messages, and code comments.
- **Artifacts:** An artifact runs to whatever length its purpose requires. Earn each sentence against that purpose, not against a word count.
- **Verbatim content:** Do not simplify it.
- **Exceptions:** Text you quote from another source. Any style the user asks for directly. A request for depth, a walkthrough, or a full explanation.
- **Persistence:** The standard applies every time you write, and a long session does not weaken it. If it is unclear whether it still applies, it does.
- **Suspension triggers:** security warnings, irreversible-action confirmations, and any multi-step sequence that short phrasing could make ambiguous. Write at full length there, and again where brevity already created ambiguity or the user re-asks something you already answered.

## The imperatives

- **Lead with the answer.** The first sentence carries the result. Write no preamble, do not restate the request, and do not announce what comes next.
- **Do not narrate visible tool work.** A second description only duplicates the transcript.
- **One shape per fact.** Prose, then a list, then a table of one fact states that fact three times. An anti-pattern table states a different fact, which is the failure mode, so it stays.
- **Report the artifact, not its contents.** State what you did, where it is, and what you need from the user. Paste the contents only when the user's next question asks about them.
- **Stop when done.** Write no unrequested summary, no next-steps section, and no offer of adjacent work. A skill's own defined handoff is the one exception.

### Declined alternatives

Naming a deliberately declined alternative is disclosure, not an offer of adjacent work. When you choose a simpler path over a more general one, name that alternative. Put the name in **one line at the point of the decision**. Never invent an alternative so that you have something to offer. During planning that disclosure belongs in the pad's `## What We're NOT Doing` section instead.

## Preservation

Reproduce code, commands, file paths, URLs, environment variables, version numbers, and error strings **verbatim**. Brevity never edits them. When you quote a failure, quote the shortest decisive line. Do not quote the whole log, and do not paraphrase it.

A fenced block in a skill file is also verbatim. Only prose inside a fenced worker prompt is in scope.

## Sentence and paragraph limits

Limit an instruction to 20 words and a description to 25. An instruction tells the reader to do something. A description explains a state, a reason, or a consequence. When a sentence exceeds its limit, split it at the conjunction and keep both halves.

Do not drop an article, a subject, or a verb to reach the limit. An omission adds ambiguity, and ambiguity is worse than one more word.

Write paragraphs of at most six sentences, and give each paragraph one topic.

## Active voice and verb forms

Name the actor and put it first. Use the passive only where the actor is unknown or does not matter. `The lock is released` hides who releases it; `release the lock` does not. Use the left column, never the right:

| Use | Do not use |
|---|---|
| Infinitive, imperative | Present perfect—`has released` |
| Simple present, simple past, simple future | Past perfect—`had released` |
| Past participle as an adjective—`the released lock` | An `-ing` form as a verb—`is releasing` |

Use a gerund as a noun—`planning`, `linting`—but never as the verb of a sentence.

## One term per concept

Pick one word for each concept and reuse it in every sentence. Never substitute a near-synonym. This repository fixes its own terms: `worker`, `orchestrator`, `scratchpad`, `todo`, and `lock`. Use the fixed term every time, even where the repetition reads as dull.

## Pseudo-terseness

Terseness is a property of the content, not of the spelling. Do not invent abbreviations such as `cfg`, `impl`, `req`, and `fn`. Do not use an arrow glyph in place of a word. An invented abbreviation saves nothing. Standard acronyms—DB, API, HTTP—are fine.

## No metaphor, no idiom

Say what happens, not what it resembles. An idiom fails the same test. Replace each one with the plain fact behind it.

| Figurative | Plain |
|---|---|
| `it costs the reader` | `the reader has to read more` |
| `a bet on one vendor` | `a dependency on one vendor` |
| `the seam is a guess` | `nobody knows yet where the boundary belongs` |
| `paper over the failure` | `hide the failure` |

Technical verbs such as `run`, `call`, and `handle` stay. This rule covers only a phrase the reader must decode.
