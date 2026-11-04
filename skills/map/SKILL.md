---
name: map
description: Chart a body of work as a map of concerns in markdown files, or apply the edits its concerns propose
when_to_use: >-
  When the user wants to shape a body of work before any of it is built, or to settle the edits
  a concern proposed to its map. Trigger phrases: "map this out", "chart the work", "break this
  into concerns", "update the map".
argument-hint: "[topic | <map-slug> | research or retro file | paths]"
---

# Map

A map charts a body of work as concerns in order. It states where the work ends, and the
principles every concern holds to. It also states what is still unclear, and what stays out. This
skill charts a new map, or it updates a map with the edits its concerns propose.

Each concern then runs its own stages, and the user starts each one:

```
/map                       map.md: destination, principles, concerns in order, fog, out of scope
/requirements <concern>    <concern>/requirements.md: outcome, acceptance criteria, proof commands
/design <concern>          <concern>/design.md: the parts that apply, each with its declined alternative
/implement <concern>       slices, waves, worktree, build, critique, draft PR, CI
review                     the user reviews the PR
```

This skill writes markdown files. It creates no todo, cuts no worktree, and writes no code. Its
one other write is `## Close merged concerns`, which deletes a merged concern's todos and KV keys.

**This skill is the only writer of `map.md`.** A stage that finds work the map missed records a
proposed map edit in its own document, and this skill applies it.

## The docs directory

Everything the user reads is a markdown file under `docs_dir`. `docs_dir` is the plugin's
`docs_dir` setting. Where the session carries no such setting, use `~/Code/agent-docs`. Expand it
to an absolute path before you report a path under it.

```
<docs_dir>/
├── maps/<map-slug>/
│   ├── map.md                  type: map              /map
│   ├── <concern>/
│   │   ├── concern.md          type: concern          /map; each stage moves its stage
│   │   ├── requirements.md     type: requirements     /requirements
│   │   ├── design.md           type: design           /design
│   │   └── implementation.md   type: implementation   /implement
│   ├── research/<topic>.md     type: research         /research, called during a map
│   └── inbox/<id>.md           type: inbox            an item of this map that waits on the user
├── inbox/<id>.md               type: inbox            an item outside any map
├── research/<slug>.md          type: research         standalone /research
└── retro/<slug>.md             type: retro            /retro
```

`src/schema.ts` in `jahnkelabs/agents-obsidian` defines the inbox item format. No skill restates
it.

**Solo never holds a document the user reads.** Solo holds agent-to-agent content only: briefs,
guards, worker reports, todos, KV, and locks. A map, a set of requirements, and a design are
files, and you write them with your file tools.

**Commit nothing under `docs_dir`.** It may be a local git repository with no remote, and the user
owns its history.

The frontmatter follows five rules:

- **Every file carries `type`.** Obsidian Bases filters on it, so a file without one drops out of
  every view.
- **A concern's `stage` lives only in its `concern.md`.** No other file repeats it, so no two
  copies can disagree. Its values are `open`, `requirements`, `design`, `implementing`,
  `in-review`, and `done`.
- **Each document carries only its own review state.** `map.md` and each concern document carry
  `status` and `awaiting`, and `implementation.md` adds `pr`. A concern document also names its
  `map` and its `concern`.
- **`status`** in a concern document is `draft` while you write, `awaiting-you` while the user
  owes a review, and `approved` once the user approves. `map.md`'s `status` adds `done`, and the
  `map.md` schema under `### Step 5` states its lifecycle.
- **`awaiting`** names the one thing the user owes, such as `approve design`, or it is `null`.

Each stage skill sets its concern's `stage` when it starts, so the stage names the work in
progress. An approval changes a document's `status`, never the concern's `stage`. The next stage
starts only when the user starts it.

**A concern's address.** `/requirements` and `/design` take `<map-slug>/<concern>`, or `<concern>`
alone. Resolve a bare `<concern>` against `<docs_dir>/maps/*/<concern>/concern.md`. One match names
the map. Several matches need the user: ask which map, as an open question. No match sends the
user to `/map`.

## Approval of a document

Every stage skill ends with one approval of the document it wrote. `/requirements` and `/design`
follow this section as written.

1. Set the document's `status: awaiting-you`, and set `awaiting` to the one thing the user owes.
2. Detect md-redline. Search the available tools for `mdr_request_review`, deferred tools
   included. Never assume that the tools exist, and never assume that they are absent.
3. **Where md-redline is present,** call `mdr_request_review` on the file. Put a question about one
   passage to the user with `mdr_ask`. Where the call returns before the user finishes, end your
   message with the footer.
4. **Where md-redline is absent,** put the approval in chat as an `Approve`, in the shape that
   `rules/chat-vocabulary.md` defines. Name the file by its absolute path.
5. Apply each change the user asks for, and ask again. One approval covers the document as it then
   stands.
6. On approval, set `status: approved` and `awaiting: null`. Then stop, because the user starts
   the next stage.

The chat approval takes this shape:

> **Approve — `<the document's path under maps/>`**
>
> - **Found:** `<absolute path to the file>`, written from <what it rests on>.
> - **Deciding:** whether the next stage builds from this document as it stands.
> - **Criticality:** <high, medium, or low, on the rule's scale>, because <what rests on it>.
> - **Reversible:** partly. A rerun of this skill revises the document, and each later stage then
>   reworks.
>
> **A. Approve the document as written**
>
> - **Pros:** <what the document settles>
> - **Cons:** <what it leaves to a later stage>
> - **Risks:** <what follows if one of its claims is wrong>
> - **Constraints:** <what it commits the next stage to>
>
> **Recommendation:** A, because <the ground>.
>
> Approve it, or name the part to change.
>
> ⏸ waiting on you: approve the <document>, or name the part to change

## Proposed map edits

`requirements.md`, `design.md`, and `implementation.md` each carry a `## Proposed map edits`
section. The stage that owns the document records there each finding that changes the map: a new
concern, a split, a principle, new fog, an out-of-scope line, a constraint on another concern, a
missing `after`, or a decision that shapes the map. `## Update a map` gathers and settles them.

Each entry takes this shape:

```markdown
## Proposed map edits

1. **<the kind>: <the edit>.** <what the stage found, and where>. `pending`
```

- **Number the entries within the document.** An edit's id is its document and its number, as
  in `c1-ingest/implementation.md` edit 2. No skill numbers edits in `map.md`.
- **The marker** is `pending` until this skill settles the entry. It then reads `applied` or
  `declined: <the reason>`.
- **`awaiting` names the pending edit.** The stage that records an edit sets its document's
  `awaiting` to `settle proposed map edits`, once nothing else waits on that document. When this
  skill settles the document's last pending entry, it sets `awaiting: null` only where `awaiting`
  reads `settle proposed map edits`. Each writer clears only its own value.
- **An empty section reads `None.`**

## Input

`$ARGUMENTS` may hold any of these:

- **A topic.** Chart a new map.
- **A map slug** that names a directory under `<docs_dir>/maps/`. Update that map.
- **A research or retro file** under `docs_dir`. Chart a new map from it. A retro file's
  `## Proposed changes` are candidate concerns. Leave the file where it is, and link it from the
  map where a decision rests on it.
- **File paths.** Read each one fully before anything else.

With no arguments:

> **Deciding — what to map**
>
> What should I map? Give me a topic, a research or retro file, or an existing map's slug.
>
> ⏸ waiting on you: name what to map

## Close merged concerns

A concern closes when its PR merges. Run this close-out first, in either mode, before anything
else.

1. Find each `concern.md` under `<docs_dir>/maps/*/` that reads `stage: in-review`.
2. Read the `pr` field of that concern's `implementation.md`. Read the state of each PR it names:
   ```bash
   gh pr view <the PR URL> --json state
   ```
3. Where every PR reads `MERGED`, close the concern:
   ```
   set stage: done in its concern.md
   set status: approved in its implementation.md, and set its awaiting to
     settle proposed map edits where an entry reads pending, or null where none does
   kv_delete every map:<map-slug>:concern:<concern>:* key
   todo_delete every todo tagged concern:<map-slug>-<concern>
   ```
4. Settle the status of each map whose concern this step closed. Where the map has at least one
   `concern.md`, and every concern reads `stage: done`, read `## Proposed map edits` in each
   concern document:
   - no entry reads `pending`: set `map.md`'s `status: done` and `awaiting: null`;
   - an entry reads `pending`: set `status: awaiting-you` and `awaiting: approve proposed map edits`.

A concern that spans repositories holds a list in `pr`, and it closes only once every PR merges.
Leave every other concern as it stands. Name each closed concern in one line, and say nothing
where none closed.

`/sweep` runs the same close-out on demand, without `/map`.

## Chart a map

### Step 1 — Scope and investigation

Do a cheap first pass before you propose anything. Read every file the user named fully. Skim
enough of each repository to form a real proposal.

- **Container:** resolve each repository's container with the one derivation `/worktree` states.
  `skills/worktree/SKILL.md` gives it under `## Derive the container from any worktree`. Use it as
  written there, and write no second copy. Name each repository by its container's basename.
- **Solo project:** call `whoami`, and use the effective project it reports. Match no path, and
  assume no name. The research workers run in that project.
- **Target repositories:** infer them, and show your evidence for each. Draw on the current
  repository, on the repositories a research file names, and on its `file:line` references. Say
  what you excluded, and why.
- **Tree staleness:** run a real `git fetch` in each repository in scope. Report how many commits
  each tree sits behind its default branch, and report `0` for a current tree. A claim that the
  tree is current is not a number, so it does not count.
- **Investigation:** describe what you intend to look into. Where the user supplied a research
  file, read it first, and scope the investigation to its gaps.
- **Decisions:** name each decision you expect to put to the user. A list tells the user what the
  grilling costs. A count of questions does not, and that count ran 1.43× low across twenty runs.

Then put the scope to the user:

> **Approve — `/map` scope**
>
> - **Found:** <what the first pass read, and where>
> - **Deciding:** which repositories and questions the research covers. Only you know where the
>   work must reach.
> - **Criticality:** medium. The concerns and their order rest on this scope.
> - **Reversible:** yes. A missed repository costs one more research pass.
>
> **A. The proposed scope**
>
> - **Pros:** <what this scope answers>
> - **Cons:** <what it leaves unexamined>
> - **Risks:** <what an omission breaks later>
> - **Constraints:** <the Solo agents and the time it takes>
>
> **Example:**
>
> ```
> Solo project   <name>  (<path>)
> repos          <repo>  ─ <evidence>   <container>   <N> commits behind <default>
> not included   <repo>  ─ <why>
> investigate    1. <specific question>
>                2. <specific question>
> decisions      1. <the decision, in a phrase>
>                2. <the decision, in a phrase>
> ```
>
> **Recommendation:** A, because <the ground>.
>
> Accept this scope, or name the repository or question to add or cut.
>
> ⏸ waiting on you: accept the `/map` scope, or name what to change

### Step 2 — Build the slug

Build the map slug once the user accepts the scope. Take `date +%Y-%m-%dt%H%M`, and add a short
topic, as in `2026-04-05t1423-points-report`. Create `<docs_dir>/maps/<map-slug>/` now, because
the research writes into it.

**The `t` is lowercase, and the workflow depends on it.** The slug builds KV keys, branch names,
worktree paths, and Compose project names. Solo rejects an uppercase KV key outright. A rejected
key reads exactly like a key nobody wrote. `/worktree` then takes its collision branch, and the run
escalates over its own branch.

### Step 3 — Investigate

Run the accepted investigation through `/research`, with its worker protocol. Step 1 already
confirmed the scope, so ask no second scope question. Each report goes to
`<docs_dir>/maps/<map-slug>/research/<topic>.md`.

### Step 4 — Grill the user

Follow `/grill`. Ask one question per message, and wait for each answer. `rules/chat-vocabulary.md`
gives the shape of a question, so point at it rather than restate it.

Grill the map, not its concerns:

- the destination, with each outcome stated so that a reader can check it;
- the guiding principles that every concern holds to;
- the concerns, their boundaries, and their order;
- what stays out of scope.

A question about one concern's criteria or design belongs to that concern's stage. Ask it now only
where the answer changes the shape of the map.

When the remaining questions are details the user would rather see than specify, propose
defaults. Flag each one as a proposal in the map.

### Step 5 — Write the map

**Name each concern `c<n>-<short-topic>`**, in lowercase, as in `c1-ingest`. `<n>` is the next
unused number in this map. A concern keeps its slug for life, because its KV keys, its branch, and
its worktree carry it. Its position lives in `order`, which may change.

**A concern's outcome is one sentence with no `and`.** Add work to a concern while that sentence
stays true. Open a new concern once the sentence needs an `and`. Each concern lands its own PRs,
one per repository it touches.

**`after` names the concern this one waits on**, a list where it waits on several, or `null`. Add
`after` only for a real dependency, because it holds the later concern back.

Write `<docs_dir>/maps/<map-slug>/map.md`:

````markdown
---
type: map
map: <map-slug>
repos:
  <repo>: <absolute container path>
  <repo>: <absolute container path>
status: draft
awaiting: null
---
## Destination

- <an outcome, stated so that a reader can check it>

## Guiding principles

- <a principle every concern holds to>

## Concerns

```base
filters:
  and:
    - 'type == "concern"'
    - 'map == this.map'
views:
  - type: table
    name: Concerns
    order:
      - order
      - concern
      - outcome
      - after
      - stage
```

## Decisions so far

- <one settled decision>. See [[<concern>/<document>]].

## Fog

- <a decision still to come, which nobody can state yet>

## Out of scope

- <what this map never does>
````

**`repos` maps each repository name to its container path**, the one step 1 derived. Each name is
the basename of its container path, as `/worktree` derives `<repo>`, so every KV key agrees.
`/implement` cuts each worktree from that path, so no later stage derives it again.

**`map.md`'s `status` follows the map's lifecycle:**

```
draft          this skill is charting the map
awaiting-you   the user owes an approval: of the map, or of a pending map edit
approved       the user approved the map, and no edit waits
done           every concern reads stage: done
```

- **`draft` to `awaiting-you`:** step 6 puts the map to the user.
- **`approved` or `done` to `awaiting-you`:** `## Update a map` finds a pending map edit, or the
  user names a change. The close-out does the same where it closes the last concern while an edit
  is pending.
- **`awaiting-you` to `approved`:** the user approves the map, or the last edit settles.
- **`awaiting-you` to `done`:** the last edit settles, and every concern still reads `stage: done`.
  An edit that adds a concern therefore reopens a finished map.
- **`approved` to `done`:** the close-out under `## Close merged concerns` closes the last concern,
  and no edit is pending.

Each section has one job:

- **`## Destination`** holds the outcomes, and each one is checkable.
- **`## Guiding principles`** holds what every concern holds to.
- **`## Concerns`** embeds the Bases block exactly as shown. Never write a table by hand there. The
  `concern.md` files hold the data, and a table would be a second copy.
- **`## Decisions so far`** holds one line per settled decision, and links the file that holds it.
- **`## Fog`** holds the decisions still to come, which nobody can state yet.
- **`## Out of scope`** holds what this map never does.

Write one `<docs_dir>/maps/<map-slug>/<concern>/concern.md` per concern:

```markdown
---
type: concern
map: <map-slug>
concern: c<n>-<short-topic>
order: <n>
outcome: <one sentence with no "and">
after: <concern> | null
stage: open
---
Not started. `/requirements <map-slug>/c<n>-<short-topic>` creates its documents.
```

### Step 6 — Approve the map

Follow `## Approval of a document`, with `awaiting: approve the map`. The proposal is the map, and
its concerns in order are the `**Example:**`:

```
1  c1-<topic>   <outcome>
2  c2-<topic>   <outcome>            after c1-<topic>
```

On approval, report the map's path and its first concern, then stop:

```
Map: <docs_dir>/maps/<map-slug>/map.md  (<N> concerns)

Next: /requirements <map-slug>/c1-<topic> starts the first concern.
```

## Update a map

`/map <map-slug>` reads `map.md` and every `concern.md` fully. It then settles each pending map
edit, and each change the user names.

**Gather the pending edits.** Read `## Proposed map edits` in each concern's `requirements.md`,
`design.md`, and `implementation.md`. Every entry marked `pending` is a pending edit. Where any is
pending, set `map.md`'s `status: awaiting-you` and `awaiting: approve proposed map edits`.

Read the file each edit cites. Put every pending edit to the user in one `Approve` message, a
`decision` entry included. No kind of edit skips it. Order the edits by concern `order`, then by
each document's numbering. Name each edit by its id, as in `c1-ingest/implementation.md` edit 2.
Give each one its proposed action, with its ground:

- **apply,** as written or as you would reword it;
- **decline,** with the reason.

The user approves the batch as proposed, or names each edit to change. Apply the answer to every
edit in the batch.

**Apply an edit where it belongs:**

- **A new concern** gets a new `concern.md` at `stage: open`, with the next unused number. Shift
  the `order` of each concern it goes ahead of.
- **A principle, a fog line, or an out-of-scope line** goes into that section of `map.md`.
- **A decision** needs no other place. Its line in `## Decisions so far`, below, applies it.
- **A constraint on one concern** goes into that concern's `concern.md` body. Its next stage reads
  the line. A document that is already approved changes only when the user reruns its skill.

**Mark each settled entry in its source document.** Replace `pending` with `applied`, or with
`declined: <the reason>`, so the same edit does not return. Add one line to `## Decisions so far`
for each settled edit. Apart from that marker and the document's `awaiting`, this skill never
edits a document that another skill owns.

**Never rename a concern.** Its slug names its KV keys, its branch, and its worktree. Change its
`order` or its `outcome` instead.

A change the user names takes the same steps, with one `Approve` per change. Once nothing remains
to settle, set `awaiting: null`, and set `status` per the lifecycle under `### Step 5`. Then stop.

## Guidelines

- **Be skeptical.** Question vague requirements, and verify each correction against the code.
- **Read completely.** Read each context file whole, with no `limit` and no `offset`.
- **Be concrete.** Every claim about current behavior carries a `file:line`.
- **An approved map holds no open question outside `## Fog`.** Research it, ask it, or name it as
  fog.
