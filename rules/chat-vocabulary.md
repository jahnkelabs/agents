---
description: Six reserved headings and one footer mark every message the user must act on; nothing else gets a heading
---

# Chat vocabulary

A run produces a lot of text, and little of it needs the user. This rule reserves six headings
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

Four of the six headings block and wait for a reply. `Landed` asks the user to read a concern
result, and `Running` reports where the run is. Neither one stops the run.

The heading works only while it stays rare. One heading on a message that asks nothing teaches
the user to read every turn again.

## Default policy

- **Default:** Send no heading, and send no footer.
- **Cadence:** In an `/implement` run, speak on your own initiative on four occasions only.
- **The four occasions:** `Running` at a wave join, `Landed` at a concern landing, `Blocked` at
  an escalation, and `Failed` at a failure.
- **Every other skill:** speak where the skill's own steps say to speak. A `/research` report
  is one such message, and it carries no heading.
- **Global parts:** the six headings and the footer hold in every skill. The cadence above holds
  in `/implement` alone.
- **Fencing:** Fence code and diagrams only. Never fence a prose field.
- **Recommendation:** Every question that offers options carries one `**Recommendation:**` line
  with its ground, an `Approve` included. A question offering none carries none.
- **Exceptions:** A direct reply to the user's own question needs no heading.

## The reserved vocabulary

```
**Approve — <topic>**     a gate. Nothing proceeds without a reply.
**Deciding — <topic>**    a question the user must answer, with or without options.
**Running — <concern>**   the wave state of a concern that has not landed yet.
**Landed — <concern>**    a concern shipped. PR URLs, gates, ledger.
**Blocked — <what>**      work stopped and needs the user.
**Failed — <what>**       something broke that the orchestrator cannot resolve.
⏸ waiting on you: <x>     the last line of every message that waits.
```

Each heading carries exactly one meaning, and no heading carries a second. Nothing else in a run
gets a heading. `Approve`, `Deciding`, `Blocked`, and `Failed` each stop the run and wait for the
user. `Landed` reports a concern and `Running` reports its waves, and the run continues.

**`Running` covers the whole concern, not the wave that ended.** It names every wave, with the
state of each task. A block that covers one wave leaves the reader asking again ten minutes
later.

**The narration ban does not reach it.** That ban cites 78% of one run's assistant turns, and
that figure counted one message per worker. One milestone here ran five waves and ten workers, so
the block costs half the messages. It also answers a question no narration answered.

## Approve versus Deciding

Both stop the run, and the difference is what the user must do. `Approve` asks the user to
sanction a proposal you already formed. You state the proposal, and the user says yes or changes
it. `Deciding` asks the user to answer a question you cannot answer yourself.

**`Deciding` covers two shapes.** The first offers options. You state them and your recommendation,
and the user picks one. The second offers none, because you hold nothing to offer. A skill's first
question is commonly that shape: `What should I research?` names no options, and inventing some would
be worse than asking.

Pick by that test alone, never by how large the question feels. A roster you assembled is an
`Approve`. A tradeoff only the user can settle is a `Deciding`, and so is an open prompt for
input.

**An `Approve` still states its recommendation.** The message states one course and asks the
user to sanction it. Its `**Recommendation:**` line names that course and the ground that ranks it
first. The user then checks your ranking rather than redoing it.

A `Deciding` message that offers options needs an explicit recommendation, because it presents
options you did not rank. So does a `Blocked` message that lists options. Neither one ranks
anything by itself, and both leave the user the work this rule removes. A `Deciding` that offers no
options carries no recommendation, because it holds nothing to rank.

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
message. The questions after it are follow-ups inside the same open gate. `/implement` invoked with
no arguments asks which concern to run. That question opens a gate rather than standing outside one. So
"inside an open gate" covers a first question too, and no waiting message falls outside this rule.

**Which messages do not.** `Landed` and `Running` carry no footer, because the run continues. A
report, a narration, and a direct answer to the user's own question carry none. None of the three
waits, and waiting is the whole test. Whether a message carries a heading decides nothing here.

## Fence code and diagrams only

A fence holds code or a diagram, and nothing else. No column limit applies to a prose field. The
terminal wraps a markdown field cleanly. Inside a fence, the field's bold label shows as literal
asterisks.

A listing of literal syntax counts as code, because the reader copies it verbatim. The reserved
vocabulary, the footer template, and the glyph table are such listings. A table of prose is a
markdown table, never a fenced one.

## The taken glyphs stay taken

Each glyph below already carries one meaning. Never give one of them a second.

```
→   a call and what it returns
✓   a task committed
▶   a task running
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

1. The reserved heading, on the gate's opening message only: `Deciding` for a question you cannot
   answer yourself, `Approve` for a proposal. A `Blocked` or `Failed` message that asks a question
   keeps its own heading, because the heading says the run stopped. Each follow-up question inside
   an open gate carries no heading.
2. The context block, in markdown: the block fields, one section per option, and the
   recommendation with its ground. The recommendation is mandatory, in an `Approve` and a
   `Blocked` too.
3. One short question.
4. The footer, as the last line of a prose question. A question the tool delivers needs
   none, because the tool blocks on its own.

**A question that offers nothing to rank drops part 2.** It has no option to weigh and nothing to
recommend. The heading, the question, and the footer are the whole message. The first question of
`/research` and `/retro` is that shape. `/implement`'s lists the concerns of the map, so it
offers options and takes the full shape.

Write each field label in bold, with the colon inside the bold. Start each field on its own line,
and a markdown list does that. Fence nothing in the context block except code or a diagram.

### The block fields

The context block opens with four fields:

- `**Found:**` what you found, and where.
- `**Deciding:**` what the user decides, and why no lookup you can run settles it.
- `**Criticality:**` high, medium, or low, on the scale below.
- `**Reversible:**` yes, partly, or no, with what undoing it costs.

The criticality scale has three values:

- **High:** other decisions depend on it, or undoing it is costly.
- **Medium:** it shapes one skill or stage.
- **Low:** it is local and cheap to change.

### One section per option

Head each option's section with a bold label, such as `**A. A join table**`. Then give its five
fields:

- `**Pros:**` what the option gains.
- `**Cons:**` what the option costs.
- `**Risks:**` what can go wrong, and what follows if it does.
- `**Constraints:**` what the option requires, and what it rules out later.
- `**Example:**` a fenced code block or diagram that shows the option.

Place `**Example:**` after the list, because a fence does not nest cleanly in a list item. Give
an example wherever the option has code or a structure to show. It is optional where the option
is already concrete, as `squash the branch` is.

### The recommendation

Close the context block with one `**Recommendation:**` line. Name the option, and give its ground:
the fact that decides between the options. A recommendation with no ground leaves the user to
rank the options again.

### An `Approve` of one proposal

An `Approve` carries the four block fields and one section for the proposal itself, with the five
option fields. Each alternative the message names takes its own section with the same fields,
because the user weighs every option on the same terms. One `**Recommendation:**` line then names
the proposal and the ground that ranks it first.

### Example

A `Deciding` with two options, as it renders above the question tool call:

> **Deciding — where tags live**
>
> - **Found:** the SQLite `notes` table stores no tags. The search page filters by one tag, and no other
>   query reads them.
> - **Deciding:** the storage shape for tags. No file in the repository settles it.
> - **Criticality:** high. The search query and every later migration depend on it.
> - **Reversible:** partly. A later change of shape costs one migration over every row.
>
> **A. A JSON array column**
>
> - **Pros:** one column, and no join on read.
> - **Cons:** nothing enforces one spelling per tag.
> - **Risks:** SQLite cannot index inside a JSON array, so the filter by tag scans every row.
> - **Constraints:** SQLite stores the column as text and reads it with its JSON functions.
>
> **Example:**
>
> ```sql
> ALTER TABLE notes ADD COLUMN tags JSON NOT NULL DEFAULT '[]';
> ```
>
> **B. A join table**
>
> - **Pros:** an index serves the filter by tag directly.
> - **Cons:** every read of a note's tags takes a join.
> - **Risks:** SQLite ignores `ON DELETE CASCADE` unless `PRAGMA foreign_keys = ON` is set, and a
>   deleted note then leaves orphan rows.
> - **Constraints:** one more table, and one more migration now.
>
> **Example:**
>
> ```sql
> CREATE TABLE note_tags (
>   note_id INTEGER NOT NULL REFERENCES notes (id) ON DELETE CASCADE,
>   tag     TEXT    NOT NULL,
>   PRIMARY KEY (tag, note_id)
> );
> ```
>
> **Recommendation:** B. The filter by tag is the one query that reads tags, and only B indexes it.

The tool then carries the question, `Where should tags live?`, and one line per option:

- `B. A join table (Recommended)`: an index serves the tag filter, and reads take a join.
- `A. A JSON array column`: one column and no join, and the tag filter scans every row.

Ask one question per message. Never batch two, because the user answers the first and the second
one disappears.

Real runs justify each part. 43 of 273 questions carried no recommendation, and two runs
recommended nothing at all. 78 of 273 arrived with no prose around them, and 12 calls batched
more than one question.

## Which surface carries a question

A heading names what a message is. It does not say how that message reaches the user, and this
rule now says both.

**A `Deciding` that offers options goes through the interactive question tool.** The tool renders
selectable options and waits. A `Deciding` is a choice you cannot rank, which is the shape the
tool exists for.

**Everything else is prose.** `Approve`, `Running`, `Landed`, `Blocked`, and `Failed` stay in the
message text. An `Approve` proposes one course, and a user often answers with a refinement rather than a
pick. A fixed option set would remove that refinement.

**A `Deciding` that offers nothing to rank is prose too.** The tool needs two options or more, and
that question has none.

Map the shape onto the tool:

| Part of the shape | Where it goes |
|---|---|
| Part 1, the heading | the prose above the call |
| Part 2, the context block | the prose above the call, in markdown, with every field |
| Each option | its section stays above the call; its description is a one-line summary |
| Part 3, the question | the question field |
| The recommendation | the context block, and that option goes first, labelled (Recommended) |
| Part 4, the footer | omitted, because the tool waits on its own |

**Put the context above the call, never inside the options.** One run answered a rejected question
on the second try, once the background arrived first. The user said so: "The context was helpful.
Represent the question." An option's description carries one line, and the fields belong above the
call.

Real runs justify this section. One session sent 23 tool calls, and 8 reached the clarify path.
That is 35 percent, against a 6 percent baseline across 273 questions. Every one of those 8 packed
the situation into the options.

## Anti-patterns

| Anti-pattern | Why it fails |
|---|---|
| A heading on a message the user need not act on | The heading stops marking an action, so the user reads every turn again |
| A heading on each follow-up question inside one open gate | Twelve questions become twelve headings, and the heading stops staying rare |
| A blocking message with no footer | Its absence means nothing is outstanding, so the user reads an all-clear |
| `Approve` on a choice you cannot rank | The user sanctions a proposal nobody made, and the real question stays unasked |
| `Deciding` on a proposal you already formed | The user ranks options you invented to fill the shape |
| A fenced table of prose | Its cells cannot wrap, and its bold text shows as literal asterisks |
| Decision fields inside a fence | The bold labels show as literal asterisks, and the fields read as code |
| A question that offers options and no recommendation | The user does the ranking work you were able to do first |
| Two questions in one message | The user answers the first, and the second one disappears |
| A bold sentinel in place of the footer | Bold marks emphasis everywhere else, so it marks nothing here |
| A new glyph for a meaning a taken glyph holds | A reader learns two symbols for one fact and trusts neither |
| Narrating each worker completion | Worker traffic drove 78% of assistant responses in one run, and none needed a reply |
| A wave block that reports only the wave that ended | The reader asks where the run is again, before the next wave joins |
