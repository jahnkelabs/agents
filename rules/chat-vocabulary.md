---
description: Five reserved headings and one footer mark every message the user must act on; nothing else gets a heading
---

# Chat vocabulary

A run produces a lot of text, and little of it needs the user. This rule reserves five headings
and one footer for the text that does. The user reads the heading and knows what you want. A
message that carries neither a heading nor the footer needs no reply, so the user can read it
later.

Two facts from real runs set this rule. 448 of 1,303 user-role turns were Solo timer bodies,
which the user never typed. No marker anywhere meant "reply needed", so 13 questions vanished
under the next timer turn.

Declined: a `references/chat-vocabulary.md` adapter. A missing convention fails silently, and
`README.md` gives that as the test for a rule rather than a reference.

## Rule of thumb

**A reserved heading marks a message the user must act on. Nothing else carries one.**

Four of the five headings block and wait for a reply. `Landed` asks the user to read a milestone
result, and the run continues.

The heading works only while it stays rare. One heading on a message that asks nothing teaches
the user to read every turn again.

## Default policy

- **Default:** Send no heading, and send no footer.
- **Cadence:** In an `/implement` run, speak on your own initiative on four occasions only.
- **The four occasions:** a gate, a milestone landing, an escalation, and a failure.
- **Every other skill:** speak where the skill's own steps say to speak. A `/research` pad report
  is one such message, and it carries no heading.
- **Global parts:** the five headings and the footer hold in every skill. The cadence above holds
  in `/implement` alone.
- **Fencing:** Fence every block that sits under a reserved heading.
- **Recommendation:** Every question carries one. An `Approve` proposal is its own; every other
  question states one explicitly.
- **Exceptions:** A direct reply to the user's own question needs no heading.

## The reserved vocabulary

```
**Approve — <topic>**     a gate. Nothing proceeds without a reply.
**Deciding — <topic>**    a choice. Context block, then a short question.
**Landed — <milestone>**  a milestone shipped. PR URLs, gates, ledger.
**Blocked — <what>**      work stopped and needs the user.
**Failed — <what>**       something broke that the orchestrator cannot resolve.
⏸ waiting on you: <x>     the last line of every message that waits.
```

Each heading carries exactly one meaning, and no heading carries a second. Nothing else in a run
gets a heading. `Approve`, `Deciding`, `Blocked`, and `Failed` each stop the run and wait for the
user. `Landed` reports a milestone, and the run continues.

## Approve versus Deciding

Both stop the run, and the difference is what the user must do. `Approve` asks the user to
sanction a proposal you already formed. You state the proposal, and the user says yes or changes
it. `Deciding` asks the user to choose among options you cannot rank. You state the options and
your recommendation, and the user picks one.

Pick by that test alone, never by how large the question feels. A roster you assembled is an
`Approve`. A tradeoff only the user can settle is a `Deciding`.

**An `Approve` proposal is its own recommendation.** The message states one course and asks the
user to sanction it. You did the ranking work, and the user can read it. An `Approve` therefore
satisfies the mandatory recommendation without a separate line, and it may still carry one.

A `Deciding` message needs an explicit recommendation, because it presents options you did not
rank. So does a `Blocked` message that lists options. Neither one ranks anything by itself, and
both leave the user the work this rule removes.

## The footer

The footer is the last line of a message that waits for the user:

```
⏸ waiting on you: <the one thing you wait for>
```

Its presence is the signal, and its absence means nothing is outstanding. Name one thing, never
two. Add no bold sentinel beside it, because bold marks emphasis everywhere else in a message.

**Which messages carry the footer.** Every message that waits for the user carries it, whether or
not it carries a heading. `Approve`, `Deciding`, `Blocked`, and `Failed` therefore all carry it. So
does a question that carries no heading of its own.

**A question opens the gate it belongs to.** A skill's first question is that gate's opening
message. The questions after it are follow-ups inside the same open gate. `/plan` invoked with no
arguments asks which plan to run. That question opens a gate rather than standing outside one. So
"inside an open gate" covers a first question too, and no waiting message falls outside this rule.

**Which messages do not.** `Landed` carries no footer, because the run continues. A report, a
narration, and a direct answer to the user's own question carry none. None of the three waits, and
waiting is the whole test. Whether a message carries a heading decides nothing here.

## Fence every blocking block

Fence every block that sits under a reserved heading. Unfenced, the roster gate reached a median
of 286 columns and the finding block 327. At that width the terminal wrapped both, and neither
read as a table any more. Real runs fenced the roster gate 5 times out of 13, and the
per-finding block 13 of 25.

## The taken glyphs stay taken

Each glyph below already carries one meaning. Never give one of them a second.

```
→   a call and what it returns
✓   a task committed
⚠   a task escalated
⊘   a task blocked behind another
☐   an open work item
─   separates a repository from its evidence
·   separates a model from its effort
⏸   the footer, and nothing else
```

A reader who learns two meanings for one glyph trusts neither. Use a word rather than a new
glyph.

## The question shape

Every question takes this shape, and this rule states it once. A skill points here rather than
restating it.

1. The reserved heading, on the gate's opening message only: `Deciding` for a choice, `Approve`
   for a proposal. Each follow-up question inside that open gate carries no heading.
2. A fenced context block, carrying the three things below.
3. One short question, and a recommendation. The recommendation is mandatory. An `Approve`
   proposal is its own, so it needs no separate line.
4. The footer, as the last line. Every question waits, so every question carries it.

The context block carries what you found, why the user must choose, and the cost of each option:

```
found:      <what you found, and where>
decision:   <why this needs the user, rather than a lookup you can run>
<option A>  <what it costs, and what it forecloses>
<option B>  <what it costs, and what it forecloses>
```

Ask one question per message. Never batch two, because the user answers the first and the second
one disappears.

Real runs justify each part. 43 of 273 questions carried no recommendation, and two runs
recommended nothing at all. 78 of 273 arrived with no prose around them, and 12 calls batched
more than one question.

## Anti-patterns

| Anti-pattern | Why it fails |
|---|---|
| A heading on a message the user need not act on | The heading stops marking an action, so the user reads every turn again |
| A heading on each follow-up question inside one open gate | Twelve questions become twelve headings, and the heading stops staying rare |
| A blocking message with no footer | Its absence means nothing is outstanding, so the user reads an all-clear |
| `Approve` on a choice you cannot rank | The user sanctions a proposal nobody made, and the real question stays unasked |
| `Deciding` on a proposal you already formed | The user ranks options you invented to fill the shape |
| An unfenced roster or finding block | Real runs reached 286 and 327 columns, and neither block read as a table |
| A question with no recommendation | The user does the ranking work you were able to do first |
| Two questions in one message | The user answers the first, and the second one disappears |
| A bold sentinel in place of the footer | Bold marks emphasis everywhere else, so it marks nothing here |
| A new glyph for a meaning a taken glyph holds | A reader learns two symbols for one fact and trusts neither |
| Narrating each worker completion | Worker traffic drove 78% of assistant responses in one run, and none needed a reply |
