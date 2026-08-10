---
description: Write short active sentences, one term per concept, and no metaphor
---

# Simplified English

This rule applies the ASD-STE100 writing rules to every sentence an agent writes: **short, active, and literal**. ASD-STE100 serves readers who must act on a procedure the first time they read it. A reader of your output has the same need. `rules/output-discipline.md` governs how much you say, and this rule governs how you say it.

## Rule of thumb

**A sentence passes when it has 20 words or fewer, uses the active voice, and contains no metaphor.**

A long sentence, a passive, and a metaphor make prose hardest to read. All three are visible in one sentence. A word count is mechanical, so run it on every sentence you write. The limit rises to 25 words for a description, and `## Sentence and paragraph limits` defines the difference. Voice and metaphor need your judgment, so the sections below define each one and give the plain replacement.

## Default policy

- **Default:** Every sentence follows the rules below.
- **Scope:** All prose you write—chat, markdown, rule and skill files, PR bodies, commit messages, and code comments.
- **Verbatim content:** Do not simplify it. The Preservation bullet in `rules/output-discipline.md` names what qualifies, and that list governs here too. A fenced block in a skill file is also verbatim, because it is a string the agent emits or sends to a worker. Only prose inside a fenced worker prompt is in scope.
- **Exceptions:** Text you quote from another source, and any style the user asks for directly.

## Sentence and paragraph limits

Limit an instruction to 20 words and a description to 25. An instruction tells the reader to do something; a description explains a state, a reason, or a consequence. When a sentence exceeds its limit, split it at the conjunction and keep both halves.

Do not drop an article, a subject, or a verb to reach the limit. The standard treats an omission as new ambiguity rather than new brevity, and ambiguity is worse than one more word.

Write paragraphs of at most six sentences, and give each paragraph one topic.

## Active voice and verb forms

Name the actor and put it first: you, the worker, the orchestrator, the reader. Use the passive only where the actor is unknown or does not matter. `The lock is released` hides who releases it; `release the lock` does not.

Use the forms in the left column, and never the forms in the right:

| Use | Do not use |
|---|---|
| Infinitive, imperative | Present perfect—`has released` |
| Simple present, simple past, simple future | Past perfect—`had released` |
| Past participle as an adjective—`the released lock` | An `-ing` form as a verb—`is releasing` |

Use a gerund as a noun—`planning`, `linting`—but never as the verb of a sentence.

## One term per concept

Pick one word for each concept and reuse it in every sentence. A near-synonym makes the reader ask whether you mean something new. This repository already fixes its own terms: `worker`, `orchestrator`, `scratchpad`, `todo`, and `lock`. Use the fixed term every time, even where the repetition reads as dull.

## No metaphor, no idiom

Say what happens, not what it resembles. A metaphor asks the reader to translate, and a wrong translation produces wrong work. An idiom fails the same test, because a reader who learned English elsewhere may not know it. Replace each one with the plain fact behind it.

| Figurative | Plain |
|---|---|
| `it costs the reader` | `the reader has to read more` |
| `a bet on one vendor` | `a dependency on one vendor` |
| `the seam is a guess` | `nobody knows yet where the boundary belongs` |
| `paper over the failure` | `hide the failure` |

Technical verbs such as `run`, `call`, and `handle` are literal in this domain and stay. This rule covers a phrase the reader must decode, not a word with one settled technical meaning.

## Example

One instruction, written twice:

**Prefer:** `Lock every file before you edit it. If a lock is unavailable, stop and escalate.`

**Avoid:** `Locks should be acquired for any file that is going to be touched, and escalation is the right move if one cannot be obtained.`

## Anti-patterns

| Anti-pattern | Why it fails |
|---|---|
| A 40-word sentence joined by semicolons and dashes | The reader holds four clauses before reaching the instruction |
| `is handled by`, `should be avoided` | The actor disappears and nobody owns the action |
| Three words for one concept in one file | The reader looks for a distinction that is not there |
| A metaphor from economics, gambling, or plumbing | The reader decodes the phrase instead of acting on it |
| `has been updated`, `had already run` | A perfect tense adds a timeline the reader does not need |
| An article dropped to reach 20 words | The count improves and the ambiguity is new |
| A ten-sentence paragraph covering three topics | Nothing marks where one topic ends and the next starts |
