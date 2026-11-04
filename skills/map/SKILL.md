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

This skill writes markdown files and nothing else. It creates no todo, cuts no worktree, and
writes no code.

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
│   └── inbox/<id>.md           type: inbox            an item that waits on the user
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
- **`status`** is `draft` while you write, `awaiting-you` while the user owes a review, and
  `approved` once the user approves.
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

## Chart a map

### Step 1 — Scope and investigation

Do a cheap first pass before you propose anything. Read every file the user named fully. Skim
enough of each repository to form a real proposal.

- **Container:** resolve each repository's container with the one derivation `/worktree` states.
  `skills/worktree/SKILL.md` gives it under `## Derive the container from any worktree`. Use it as
  written there, and write no second copy.
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
repos: [<repo>, <repo>]
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
      - file.name
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

## Proposed edits
````

Each section has one job:

- **`## Destination`** holds the outcomes, and each one is checkable.
- **`## Guiding principles`** holds what every concern holds to.
- **`## Concerns`** embeds the Bases block exactly as shown. Never write a table by hand there. The
  `concern.md` files hold the data, and a table would be a second copy.
- **`## Decisions so far`** holds one line per settled decision, and links the file that holds it.
- **`## Fog`** holds the decisions still to come, which nobody can state yet.
- **`## Out of scope`** holds what this map never does.
- **`## Proposed edits`** starts empty. A concern's stages append numbered edits to it, and this
  skill applies or rejects each one.

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
Repo: `<repo>` at `<absolute container path>`.

Not started. `/requirements <map-slug>/c<n>-<short-topic>` creates its documents.
```

The `Repo:` line carries the container from step 1, so a later stage need not derive it again.

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

`/map <map-slug>` reads `map.md` and every `concern.md` fully. It then settles each edit under
`## Proposed edits`, and each change the user names.

Take the edits in order, one per message. Read the file each edit cites, such as the concern's
`implementation.md`. Put each edit to the user as an `Approve`, with
`awaiting: approve proposed edit <n>`. Give it two sections:

- **A. Apply the edit,** as written or as you would reword it.
- **B. Reject it.**

The recommendation names one of the two, with its ground.

**Apply an edit where it belongs:**

- **A new concern** gets a new `concern.md` at `stage: open`, with the next unused number. Shift
  the `order` of each concern it goes ahead of.
- **A principle, a fog line, or an out-of-scope line** goes into that section of `map.md`.
- **A constraint on one concern** goes into that concern's `concern.md` body. Its next stage reads
  the line. A document that is already approved changes only when the user reruns its skill.

This skill never edits a document that another skill owns.

Remove the settled edit from `## Proposed edits`, and add one line to `## Decisions so far`. A
rejected edit leaves the list the same way. Its line names the edit and the reason, so the same
edit does not return.

**Never rename a concern.** Its slug names its KV keys, its branch, and its worktree. Change its
`order` or its `outcome` instead.

A change the user names takes the same steps, with one `Approve` per change. Once nothing remains
to settle, set `status: approved` and `awaiting: null`, and stop.

## Guidelines

- **Be skeptical.** Question vague requirements, and verify each correction against the code.
- **Read completely.** Read each context file whole, with no `limit` and no `offset`.
- **Be concrete.** Every claim about current behavior carries a `file:line`.
- **An approved map holds no open question outside `## Fog`.** Research it, ask it, or name it as
  fog.
