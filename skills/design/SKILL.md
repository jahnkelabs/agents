---
name: design
description: Design one concern of a map from its approved requirements, and put each design decision to the user with real code and diagrams
argument-hint: "<concern> | <map-slug>/<concern>"
---

# Design

Decide how one concern gets built, before any code exists. This is a concern's second stage.
`/requirements` comes before it, and `/implement` builds from both documents. The user starts
each stage.

This skill writes `<concern>/design.md` under `docs_dir`. It also moves the concern's `stage`, and
it can append a proposed edit to the map. It writes no code.

`skills/map/SKILL.md` defines the docs directory, the frontmatter, and a concern's address under
`## The docs directory`. It defines the approval under `## Approval of a document`. Follow both as
written there.

## Input

`$ARGUMENTS` names one concern, as `<map-slug>/<concern>` or as `<concern>` alone. Resolve it by
the address rule in `/map`.

With no arguments:

> **Deciding — which concern**
>
> Which concern should I design? Name it as `<map-slug>/<concern>`.
>
> ⏸ waiting on you: name the concern

**Stop until the user approves the requirements.** A missing `requirements.md`, or one whose
`status` is not `approved`, sends the user to `/requirements <map-slug>/<concern>`.

## Step 1 — Read

Read each of these fully:

- `map.md`, the concern's `concern.md`, and its approved `requirements.md`;
- the `design.md` of each concern that `after` names, for the interfaces this one consumes;
- each file under the map's `research/` that bears on this concern;
- the concern's `design.md`, where one exists, because this run then revises it;
- the code the concern changes, in each repository the `Repo:` line names.

Run a real `git fetch` before you read the code. Where the tree sits behind its default branch,
read the remote's version with `git show origin/<default>:<path>`. A design built on a stale tree
fails against the real one.

Where a fact needs more than a lookup, run `/research` on it. Its report goes to
`<docs_dir>/maps/<map-slug>/research/<topic>.md`.

Then move the stage. Set `stage: design` in `concern.md` where it reads `open` or `requirements`.
A later stage stays as it is, and the revised document goes through approval again. Append
` · [[<concern>/design]]` to the body's `Documents:` line.

## Step 2 — Walk the checklist

Walk every part below. Write only the parts that apply, and leave out each other part, heading
and all.

| Part | Write it when | It holds |
|---|---|---|
| `## Structure` | the concern creates or changes a file | the files and modules, as a tree |
| `## Data model` | the concern stores data, or changes the shape of data | the schema or the types, as real code |
| `## Interfaces` | another unit calls this one, or it calls another unit | signatures, commands, or endpoints, as real code |
| `## Call patterns` | data moves between units, through a query, or over a network | each flow, as a diagram |
| `## Failure handling` | a step can fail in a way that a caller sees | each failure, and what the caller sees |
| `## Decisions` | always | one line per decision |

**Each part names its declined alternative.** Close the part with
`Declined: <the alternative>. <why it lost>.` Name an alternative you weighed seriously. Where you
weighed none, say so, and never invent one.

**Show the design as code.** A data model is real SQL or real types. An interface is a real
signature. A call pattern is a diagram. Fence code and diagrams, and nothing else.

**Name every file you know the concern touches.** `/implement` derives its slices from
`## Structure`, and its census finds the inbound references you miss.

**Cover every acceptance criterion.** Each criterion in `requirements.md` needs a part that makes it
hold. A criterion the design cannot meet is a change to the requirements. Stop with a `Blocked`
that names the criterion, and the user reruns `/requirements`.

**A finding that changes the map goes to the map.** A new concern, a split, or new fog becomes a
numbered item under `map.md`'s `## Proposed edits`. `/map` applies or rejects it. Edit no other
section of `map.md`, apart from the decisions in step 5.

## Step 3 — Put each decision to the user

A design decision is a choice that the code and the requirements leave open. Put each one to the
user in the shape that `rules/chat-vocabulary.md` defines. Give each option a real code block or a
diagram as its `**Example:**`.

Ask in dependency order, as `/grill` does. The data model usually comes first, because the
interfaces and the call patterns rest on it. Ask one decision per message, and wait for each
answer.

When the remaining decisions are details the user would rather see than specify, propose
defaults. Mark each one in `## Decisions` as awaiting approval with the design. The design's
approval then settles it.

Record each decision as one line under `## Decisions`:

```
- **<topic>:** <the choice> (criticality <high | medium | low>, reversible: <yes | partly | no>). Chosen over <the declined options>.
```

## Step 4 — Write the document

Write `<docs_dir>/maps/<map-slug>/<concern>/design.md`, with only the parts that apply:

````markdown
---
type: design
map: <map-slug>
concern: <concern>
status: draft
awaiting: null
---
## Structure

```
<repo>/
├── <path>          <what it holds>
└── <path>          <what it holds>
```

Declined: <the alternative>. <why it lost>.

## Data model

```<language>
<the schema or the types>
```

Declined: <the alternative>. <why it lost>.

## Interfaces

```<language>
<the signatures, the commands, or the endpoints>
```

Declined: <the alternative>. <why it lost>.

## Call patterns

```
<source> ──► <step> ──► <step> ──► <sink>
```

Declined: <the alternative>. <why it lost>.

## Failure handling

- **<the failure>:** <what happens, and what the caller sees>.

Declined: <the alternative>. <why it lost>.

## Decisions

- **<topic>:** <the choice> (criticality <level>, reversible: <yes | partly | no>). Chosen over <the declined options>.
````

## Step 5 — Approve

Follow `## Approval of a document` in `/map`, with `awaiting: approve design`.

On approval, add one line to `map.md`'s `## Decisions so far` for each decision that shapes the
map or another concern. End each line with `See [[<concern>/design]].` Then report the file's
path, and stop:

```
Design: <docs_dir>/maps/<map-slug>/<concern>/design.md

Next: /implement <map-slug>/<concern>
```
