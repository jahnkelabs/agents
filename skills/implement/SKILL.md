---
name: implement
description: Implement one approved concern of a map, from its requirements and design to a draft PR with CI green
argument-hint: "[<map-slug>/<concern> | <concern>] [--critique <models>]"
disable-model-invocation: true
---

# Implement

Build one concern of a map, from its approved requirements and design, up to a draft PR with CI
green. You own git, todo lifecycle, and worker coordination. Workers write code and nothing else.

```
  concern   one outcome of a map. It lands as one branch and one draft PR per
            repository it touches.
  slice     one worker's unit of work. Narrow, vertical, one repository.
  wave      the concurrency schedule inside the concern, from file overlap.
```

A **task** is one worker, one todo, one report scratchpad, one model tier. A task carries one
slice, or several that must not drift apart. Workers escalate on **deviation**, not on
completion — see [Escalation](#escalation).

## Input

- **`<map-slug>/<concern>` or `<concern>`** — the concern's directory under `<docs_dir>/maps/`.
  Resolve it by the address rule in `/map`.
- **`--critique <models>`** — the critique roster. Pass it to `/critique` unchanged. Without it,
  `/critique` takes its own default.

`docs_dir` is the plugin's `userConfig` directory, and it defaults to `~/Code/agent-docs`.

With no concern named, list each concern whose `design.md` carries `status: approved` and whose
`stage` is `design`, `implementing`, or `in-review`. Ask which one. That opens a `Deciding` gate,
per `rules/chat-vocabulary.md`, and a caller never reaches it.

Use whichever Solo project is currently selected.

### The documents

Read every document below fully before you cut anything:

```
<docs_dir>/maps/<map-slug>/
├── map.md                    repos, guiding principles, out of scope
└── <concern>/
    ├── concern.md            type: concern; the concern's stage and its after
    ├── requirements.md       acceptance criteria: criterion, proof command, invariant
    ├── design.md             structure, data model, interfaces, failure handling, decisions
    └── implementation.md     this skill writes it; see ## The record
```

**Both stage documents must carry `status: approved`.** Starting this skill on an approved design
authorizes the concern's branch pushes and its draft PR, per `rules/pr-first-contributions.md`.
Stop where either document is not approved. Send the user to `/requirements` or `/design`,
whichever one is not.

**The inbox item format has one definition.** An item that belongs to this map lives at
`<docs_dir>/maps/<map-slug>/inbox/<id>.md`. `src/schema.ts` in `jahnkelabs/agents-obsidian`
defines its format. Read it there, and never restate it.

The skills commit nothing under `docs_dir`. It may be a local git repository with no remote.

**Keep each document's frontmatter current.** A concern's stage lives only in its `concern.md`.
Set `stage: implementing` once the record exists, and `stage: in-review` at the landing. `/map`
sets `stage: done` once the PR merges, and this skill never sets it.

### Where the run stands

The concern's `stage` and its `implementation.md` say where the run stands. Read both before you
cut anything:

- **`stage: done`:** stop. The concern closed when its PR merged. Send the user to `/map`, which
  charts a new concern.
- **`stage: in-review`:** a review rerun, per `### A review rerun`.
- **An `implementation.md` at any other stage:** a resume. Read its `step` alone, and go to the
  step after it:
  ```
  null        ## Slice the concern, step 6: each task ## Slices lists and no todo carries
  sliced      ## Build the concern, step 1: the first wave with open tasks
  built       step 2: the critique
  critiqued   step 3: the commit
  committed   step 4: the push and the PR
  pr-open     step 5: the CI wait
  landed      step 7: the announcement
  ```
- **No `implementation.md`:** a fresh run.

A resume and a review rerun still take `## Cut the worktree`. It reuses a standing tree, or it
cuts again onto the recorded branch.

**Close the dead run's workers before you resume.** A Solo worker outlives the session that
spawned it, so a worker of the dead run may still write. Run `list_processes`. Close each live
process whose name ends `-<map-slug>-<concern>`, and read its report pad,
`<map-slug>/<concern>/<task>`. Then settle each todo that reads `in_progress`, in its worktree:

- its commit appears in `git log <base>..HEAD --grep="^Task: <letter>$"`: `todo_complete` it, and
  spawn nothing;
- its report pad begins `ESCALATION:`: put it to the user, per [Escalation](#escalation);
- its report pad records a finish: commit it as the join does, then `todo_complete` it;
- it has no report pad: restore its declared paths, per [Escalation](#escalation), and respawn it.

### A review rerun

The review asked for changes, and the user reran `/requirements` or `/design` to make them.

1. **Check each PR in `pr` first:**
   ```bash
   gh pr view <the PR URL> --json state
   ```
   A `MERGED` or `CLOSED` PR stops the run. Send the user to `/map`, which closes a merged concern.
2. **Find what the kept tasks do not cover.** First create each todo that `## Slices` lists and no
   todo carries, as `## Slice the concern` step 6 creates one, and leave `step` as it stands. A
   rerun that stopped partway leaves such a task. The kept tasks are then every todo of the concern.
   A criterion or a `## Structure` path is new where no kept task's spec names it as the documents
   now state it.
3. **Slice only what is new,** per `## Slice the concern`. Where nothing is new and every todo reads
   `completed`, the review changed nothing the build covers. Say so, tear down per
   `## Build the concern` step 8, and stop.

## Speaking

`rules/chat-vocabulary.md` reserves the headings and the footer. Speak on four occasions and no
others: a wave join, the landing, an escalation, and a failure. The question that opens a run with
no concern named is the one gate.

Narrate no worker completion. That ban cites 78% of one run's assistant turns, which counted one
message per worker. A wave join instead emits one `Running` block covering every wave of the
concern, and `references/implement-waves.md` defines it.

## The exit criterion

The requirements declare the end state. Each acceptance criterion carries a proof command and its
invariants. Run the concern to every criterion. Never ask the user whether to continue, and never
re-ask a question the requirements or the design already answered.

Stop on these, and on nothing else:

```
  no concern, a concern at stage: done, or a stage document that is not approved
  a review rerun whose PR reads MERGED or CLOSED, or that finds nothing new
  a container path that map.md lacks, or that holds no git repository
  a predecessor that has not landed, that closed unmerged, or that forms no stack with another
  a /worktree refusal
  a census hit that needs a behavior the design does not describe
  a worker deviation
  a critique escalation: C1 to C6, a batch 1 deviation, or batch 1 failing after two reworks
  a check that still fails after two CI fixes, or that is still pending at the CI ceiling
```

## Cut the worktree

Cut one worktree and branch for each repository the concern touches. `map.md`'s `repos`
frontmatter names the map's repositories. The design's `## Structure` says which of them this
concern touches.

1. **Read each repository's container from `map.md`.** Its `repos` frontmatter maps each
   repository name to its container path, and `/map` writes it. Where the map names no path for
   a repository, or the path holds no git repository, read the path the user gave before:
   ```
   kv_get(key="map:<map-slug>:concern:<concern>:container:<repo>")
   ```
   Where that key is empty, or its path holds no git repository, stop. Ask the user for the path,
   as an open question. Guess no path.

   **Keep the path the user gives.** Write it to that key with `kv_set`, so a resume reads it
   rather than asking again. `<repo>` there is the name `map.md` gives. Record a pending proposed
   map edit, `repos: <repo>: <path>`, in `implementation.md`, so `/map` corrects the map. Where the
   record is not open yet, record the edit when it opens.

   `/map` derived each path with the one derivation `/worktree` states, under
   `## Derive the container from any worktree`. A path the user supplies takes that derivation
   too. Use it verbatim, and write no second copy. `git rev-parse --show-toplevel` is the wrong
   command here. It returns `<container>/main` in a converted repository, and `/worktree cut`
   then refuses the container as a plain clone.
2. **Choose the base, per repository.** The base is `origin/HEAD`, unless this concern stacks on
   an unmerged one in this repository. Read each concern that `concern.md`'s `after` names, one or
   a list. Its `implementation.md` carries its PRs in `pr`. Read each one:
   ```bash
   gh pr view <the predecessor's PR URL> --json headRefName,baseRefName,state
   ```
   Then settle each predecessor for this repository:
   - no `implementation.md`, or `pr: null`: it has not landed. Stop, and name it;
   - no PR in this repository: it changes nothing here, so it sets no base here;
   - `MERGED`: its code is on `origin/HEAD`;
   - `CLOSED`: stop, and name it, because its branch may no longer exist;
   - `OPEN`: its `headRefName` is a candidate base.

   One candidate is the base. Two or more candidates form one stack where each PR but one bases on
   another candidate's branch. The base is then the top branch, which no other candidate bases on.
   Otherwise stop, and name the branches. The user then asks `/map <map-slug>` for an `after` that
   chains them.
3. **Write the branch key, then cut:**
   ```
   kv_set(key="map:<map-slug>:concern:<concern>:branch:<repo>", value="<branch>")
   /worktree cut <container> <concern> <branch> <base>
   ```
   **The key goes first, and that order is load-bearing.** `/worktree` reads the key to tell a
   resume from a collision. Write it after the cut, and a run that dies between the two takes the
   collision branch. It then escalates over its own branch.

   **Pass the container path, never the repository name.** `/worktree` substitutes it into
   `--git-dir`. Pass `agents` instead, and cut mode resolves against the session's working
   directory and refuses an already-converted repository. `<repo>` in every KV key here is the
   basename of the container, as `/worktree` derives it.

   That skill owns the layout, the provisioning, the naming, and every refusal it states. Add
   nothing to its procedure, and do not paraphrase it.

   **A `Blocked` from `/worktree` stops the run.** It refuses a plain clone, and it refuses a
   repository that carries no provisioning script. Pass that report to the user as it stands, and
   cut no second worktree. The tree it kept is the one the retry reuses.

   The branch is `<type>/<map-slug>-<concern>`, per `solo-agent-orchestration`. **Pass the branch
   and the base to `/worktree`, which builds neither.** `<type>` is `feat`, `fix`, or `chore`, and
   this skill holds that choice. Let `/worktree` construct the name a second time, and the two can
   differ from the key you just wrote.

   **A resumed run may find the worktree still standing.** A run that stopped before teardown
   leaves one behind, and `solo-agent-orchestration` carries both tests. Reuse a recorded path
   that holds this concern's branch, and stop where it holds anything else.

   `/worktree` records the tree path under `map:<map-slug>:concern:<concern>:worktree:<repo>`.
   Both keys carry the concern and the repository, and `solo-agent-orchestration` says why.

## Slice the concern

A resume skips this section, except at `step: null`, which takes step 6 alone. A review rerun takes
every step below for what `### A review rerun` found new. It keeps the kept todos, and it letters
each new task after the last task `## Slices` lists.

1. **Derive the slices from the requirements and the design.** A slice is narrow and vertical:
   one coherent change, in exactly one repository, that stands on its own. Each slice carries:
   ```
   files        every path it touches; the census below completes this list
   criteria     the acceptance criteria it satisfies, with their proof commands and invariants
   constraint   optional: same-worker as <slice>, or after <slice>
   ```
   The design's `## Structure` gives the files, and the requirements give the criteria. Every
   criterion lands in at least one slice.

   **`constraint` has exactly two forms.** `same-worker as <slice>` ties two slices that must not
   drift apart. A shared clause that must stay byte-identical is one case. A rename and its call
   sites is another. `after <slice>` marks a genuine dependency, such as documenting a result.
   Anything else is scheduling, and file overlap already decides it.

   **Split any slice that spans two repositories.** A slice that straddles two repositories fits
   neither worktree.
2. **Run the inbound-reference census in the worktree.** It is a required step, not a
   thoroughness reminder. Every slice must declare every path it touches. The census finds the
   paths you did not think of.

   Take each file a slice changes, and each symbol it renames or removes. Search for three kinds
   of inbound reference:
   ```
   caller     every site that imports, calls, includes, or spawns the thing you change
   test       every test that exercises it, by name or through its public entry point
   standard   every rule, ADR, README, or skill whose text your change makes false
   ```
   Add every path the search returns to that slice's files. A hit in another repository belongs to
   another slice, because a slice covers exactly one repository.

   The third kind is the one that gets missed. A change to a rule falsifies the README table that
   describes it. No import points from one to the other, so grep the prose as well as the code.

   Nineteen of thirty sessions shipped an incomplete file list, and one run reported ten affected
   waves of fourteen. The census decides which tasks run in parallel, because file overlap orders
   the waves.

   **A census hit can be a deviation.** A path outside the design's `## Structure` stays in scope
   when its change only follows the design. A falsified README sentence is one such path. A path
   that needs a behavior the design does not describe is a deviation. Stop and put it to the user. Do not
   widen the design yourself.

   **A census hit can reveal a missing `after`.** An open PR of another concern may change a file
   this concern changes, with no `after` between the two. Record a proposed map edit in
   `implementation.md` that orders them. The later branch would otherwise carry a conflict the
   user never approved.
3. **Schedule the waves.** `references/implement-waves.md` carries the rules that turn file
   overlap into a wave order.
4. **Assign each task a model and effort tier.** A task does not inherit these from the session.
   Judge by what the task demands. A mechanical edit against precise line references is not a
   contract-preserving rewrite, and the two should not cost the same. `list_agent_tools` resolves
   the runtime, and model and effort vary within it.

   **Write each task's summary so its tier follows from it.** One task reads "three localized
   edits against precise line references". Another reads "a rewrite of two skills onto one
   vocabulary". Each argues for a different tier by itself, and needs no separate rationale.

   **Disclose a runtime that cannot deny a worker's git writes.** `rules/solo-agent-orchestration.md`
   carries the posture, and the adapter names what each runtime can enforce. Read both before you
   pick a runtime. Where one cannot deny those writes, the first `Running` block carries a
   `Sandbox:` line. It names the exposure: two workers in one tree cross-commit each other's work.
   Never promise a denial the runtime cannot give.
5. **Open the record.** Write `implementation.md` in the shape `## The record` gives, with
   `status: draft`, `awaiting: null`, `step: null`, and `pr: null`. Fill its `## Slices` section
   now, with every task letter, before any todo exists. Set `## Critique ledger` to `Not run.`
   Record each proposed map edit the run already holds, such as a container path the user gave.
   Then set `stage: implementing` in the concern's `concern.md`.

   A review rerun edits the record instead, per `## The record`, and leaves `stage` for step 6.
6. **Create the todos** — one per task that `## Slices` lists and no todo tagged `task:<letter>`
   carries. The body carries the **task spec**: the slices it covers, their files, their criteria,
   and their proof commands. The requirements hold the criteria. The todo holds the grouping, and
   the worker reads its own todo, so the spec belongs there.
   ```
   todo_create(title="<task>: <name>", body=<task spec>,
               tags=["map:<map-slug>", "concern:<map-slug>-<concern>", "project:<repo>",
                     "task:<letter>"])
   todo_add_blocker(todo_id=<dependent>, blocker_id=<prerequisite>)
   ```
   Keys and tags are lowercase. Lowercase any slug that carries an uppercase timestamp.

   **Every automated check must be able to fail.** Run each check against the pre-change tree
   before you write it into the spec, and record the output there. A check that already passes
   needs a mutation proof. Copy the file to a scratch path, break what the check tests, and record
   the failure on the copy. Never mutate the repository for a proof. Mark a check `unverifiable`
   where neither route works, and say why.

   Two checks in the corpus could never fire. `grep -rn 'App\\Models'` searched for two literal
   backslashes, and `grep -ci Test` matched an unrelated domain string. Both read as passing
   evidence.

   **Set `step: sliced` once every task has its todo.** Then set `stage: implementing` where
   `concern.md` reads another stage. A review rerun reaches that stage here.

## Build the concern

1. **Run the waves.** `references/implement-waves.md` carries the spawn, the brief pad, the
   pointer, the guard, and the join. Each wave commits its own tasks at its join, so no task
   commit follows the last wave. Set `step: built` once the last wave's join commits.
2. **Critique the concern's diff, once per repository it touches.** Name the base explicitly, and
   pass the concern:
   ```
   /critique --base <that repository's base> --concern <map-slug>/<concern>
   ```
   The base is the ref `## Cut the worktree` chose for that repository. Without `--base`,
   `/critique` falls back to the default branch. A stacked concern then reviews its predecessor's
   diff as its own, and re-raises findings the user already settled.

   **One `--base` cannot express two repositories.** One repository may stack on a predecessor
   branch while another starts from `origin/HEAD`. One ref is then wrong for one of them.

   `/critique` runs in `apply` mode here. Its runner performs the batch 1 rework itself, and it
   applies each accepted fix. Both land uncommitted in this concern's worktrees. It also records
   each systemic finding under `implementation.md`'s `## Proposed map edits`.

   `/critique` owns the filter, the ledger, the escalations, and the presentation of a finding.
   Point at it and add nothing. Fix no finding unilaterally.

   **Write each repository's ledger to the record as its call returns,** under
   `implementation.md`'s `## Critique ledger`. Its proposed map edits are already there, because
   `/critique` recorded them. A resume critiques only the repositories whose ledger the record
   lacks. Set `step: critiqued` once every repository's ledger is there.

   **Record each escalation the user settles as the answer arrives,** in its own
   `## Decided: <topic>` section. A resumed critique passes those sections to `/critique` as
   settled, so it raises none of them again. `/critique` records each deviation the user accepts
   under `## Deviations`.
3. **Commit the critique's changes, once per repository:**
   ```bash
   git add <the paths the rework and the ledger's fixes touched>
   git commit -m "fix(<scope>): apply the critique remedies for <concern>"
   ```
   This commit and the CI fixes are the only commits outside a wave join. Skip this one, and the
   PR omits every remedy. A repository whose worktree holds no change skips its commit, because a
   resume may find that commit already made. Set `step: committed` once every repository is done.
4. **Push, and open one draft PR per repository.** Re-run the staleness check and the quality
   gates from `pr-first-contributions` first. Then push and open the PR, per its
   `## Push and open the PR`. No push gate exists, because the approved design authorized these
   pushes and this draft PR.

   The title states the concern's outcome, in the title spec the rule gives. Update an open PR
   rather than opening a second one.

   **Write each PR URL to `implementation.md`'s `pr` as the PR opens.** A resume reads it there.
   Set `step: pr-open` once every repository's PR is open.

   **A stacked concern opens its PR on its predecessor's branch, then registers the chain:**
   ```bash
   gh pr create --draft --base "<the predecessor concern's branch>" --title "<title>" --body "…"
   gh stack link --base <the default branch> <the first branch> … <this concern's branch>
   ```
   The rule's `## Stacked PRs` says what the body names. `gh stack link` registers the chain as a
   native GitHub stack. Never use `gh stack submit`, because it cannot take a PR title or body.
   Where `gh stack` is not installed, skip the link, and say so in `Landed`.
5. **Wait for CI,** per `## Wait for CI` in `pr-first-contributions`, which bounds the wait at one
   hour. On a failed check, read its log with `gh run view <run id> --log-failed`. Fix the cause in
   the worktree, within the design. Commit only the paths the fix touched, push, and wait again.

   **Two CI fixes is the limit.** A check that still fails after the second fix stops the run under
   `Blocked`. A fix that departs from the design is a deviation, and it stops the run at once.

   **A check still pending at the ceiling stops the run under `Blocked`.** Name each pending check
   from `gh pr checks <the PR URL> --json name,bucket`. Such a check may wait on a manual approval,
   or on a runner that never starts.

   **A repository with no CI takes the proof commands as its gate.** `## Wait for CI` in
   `pr-first-contributions` defines no CI, and it bounds the wait. Run every proof command in the
   worktree instead, and `Landed` says that the proof commands were the gate.
6. **Write the record.** Complete `implementation.md`, per `## The record`. Its ledger and its
   `pr` are already there. Set `status: awaiting-you`, `awaiting: review the PR`, and
   `step: landed`. Then set `stage: in-review` in the concern's `concern.md`, and append
   ` · [[<concern>/implementation]]` to its body's `Documents:` line where the line lacks it.

   **Record each proposed map edit under `implementation.md`'s `## Proposed map edits`,** in the
   shape `skills/map/SKILL.md` gives under `## Proposed map edits`. Number each one after the last
   entry there. `/critique` already recorded its systemic findings, so add only the rest:
   - a settled deviation that reaches beyond this concern;
   - new fog that the build uncovered;
   - a missing `after` that the census found.

   `/map` applies or declines each edit. This skill never writes `map.md`.
7. **Announce the landing.** This message ends the run.

   **Landed — `<map-slug>/<concern>`**

   <the concern's outcome, and what the build did, in two sentences or fewer>

   - **PR:** <the PR URL>, draft, base `<base>`, <N> commits. One line per repository.
   - **CI:** every check passed, after <n> fixes. With no CI: the proof commands were the gate,
     and all <n> pass.
   - **Deviations:** one sentence each, or none.
   - **Proposed map edits:** one sentence each, from `implementation.md`, or none.
   - **Record:** `<the absolute path of implementation.md>`.

   Then the ledger, in the shape `/critique` defines. The record holds the same ledger.

   `Landed` carries no footer. The run ends here, and the user reviews the PR. CI passed before
   this message, as `pr-first-contributions` requires before the review prompt.
8. **Tear down and close.** Do all of these, in this order:
   ```
   timer_cancel(timer_id=<each guard this run armed>)
   close_process(process_id=<each worker of this run>)
   lock_release for any lock a dead worker left held
   stop the stack and remove the worktree, per /worktree's teardown block
   git worktree prune in each container, per solo-agent-orchestration
   ```
   The branch lives on the remote once the push succeeds, so the worktree is disposable. A guard
   left armed fires later, about workers that finished long ago.

   **Keep the concern's todos and KV keys.** The concern closes when its PR merges, not at the
   landing. A review that asks for changes reruns this skill on the amended documents, as a review
   rerun under `## Input`. The branch key then tells that rerun from a collision. `/map` closes a
   merged concern when it runs.

   **Close is silent.** `Landed` already carried the PR URLs, the CI result, and the record's path.
   Repeat none of it.

## The record

`<docs_dir>/maps/<map-slug>/<concern>/implementation.md` is the user's record of the build:

```markdown
---
type: implementation
map: <map-slug>
concern: <concern>
status: awaiting-you          # draft while the run builds
awaiting: review the PR       # null while the run builds
step: landed                  # null until the slicing creates every todo
pr: <the PR URL>              # null until it opens; a list where the concern spans repositories
---
## Where the code is
<each repository: its branch, its PR and base, its commits, and the CI result or the proof gate>

## Slices
<each task: its letter, its slices with their files and criteria, its tier, and its wave>

## Decided: <topic>
<one section per decision the user settled during the run, in the decision format>

## Critique ledger
<the ledger, in the shape /critique defines, one per repository; Not run. until the critique returns>

## Deviations
<each departure the user approved, naming the document it departs from, or none>

## Proposed map edits
<each edit this run recorded, in the shape /map gives, or None.>
```

Omit `## Decided` where the user settled nothing during the run.

**`step` names the last step that completed.** Write each value as its step completes, never
before. A resume reads it alone, per `### Where the run stands`.

```
null        the record is open, and some task in ## Slices has no todo yet
sliced      every task in ## Slices has its todo
built       the last wave's join committed
critiqued   every repository's ledger is in the record
committed   every repository's critique remedies are committed
pr-open     every repository's PR is open, and pr holds its URL
landed      CI passed, and the record is complete
```

**The record is written once, then edited in place.** `## Slice the concern` writes it. Every later
step edits a field or a section, and never writes the whole file again.

**A review rerun edits the record the same way.** It keeps `## Deviations`, every
`## Decided: <topic>` section, and `## Proposed map edits` verbatim. It numbers each new edit
after the last entry there. It resets `## Critique ledger` to `Not run.`, keeps `pr` as it
stands, and sets `status: draft` and `awaiting: null`. It appends its new tasks to `## Slices`,
and it sets `step: sliced` once their todos exist.

**A stop keeps the record current too.** A `Blocked` or `Failed` after the record opens sets
`status: awaiting-you`, and `awaiting` to the footer's one thing. The answer sets them back to
`draft` and `null`.

## Escalation

A worker escalates when it cannot self-resolve. It also escalates when finishing would mean
deviating meaningfully from the approved requirements or design. A worker that writes an
undeclared path deviates from the task.

**A deviation stops the run.** In-flight workers in the same wave finish. They hold disjoint file
scopes, so no other work depends on the problem. Do not start the next wave until the user
resolves the deviation.

The worker's report scratchpad is the durable record, and its completion signal says whether it
escalated. The wave join is the only place a worker's escalation appears.

**Blocked — `<concern>` wave `<N>`**

```
  A  ✓ committed
  B  ⚠ escalated
  C  ⊘ blocked behind B
```

- **Found:** the design assumed <X>; the code actually does <Y>. Task B's report is scratchpad
  <id>.
- **Deciding:** how task B proceeds, because each way forward departs from the approved design.
- **Criticality:** <high, medium, or low>, and why.
- **Reversible:** <yes, partly, or no>, and what undoing it costs.

**A. <amend the design>**, **B. <a different approach>**, and **C. <drop the slice>** each take
their own section, with the five option fields.

**Recommendation:** <the option>, because <the ground it rests on>.

⏸ waiting on you: pick one option for task `B`

`rules/chat-vocabulary.md` gives the full question shape. **The recommendation is mandatory.** A
`Blocked` options list ranks nothing by itself, so name the option you would take and its ground.

**Record the answer as it arrives,** in its own `## Decided: <topic>` section, so a resume asks
nothing twice.

**Restore the task's declared paths before you act on the answer.** The worker stopped mid-edit,
and the join committed none of its paths. Restore each declared path that `HEAD` holds, and delete
each one that `HEAD` lacks:
```bash
git restore --source=HEAD --staged --worktree -- <the task's declared paths that HEAD holds>
```
Then act on the answer:
- **C, drop the slice:** `todo_complete` the task, with a comment that names the drop.
- **A or B:** edit the task's brief pad in place, and respawn the task at its tier.

**A settled deviation lives only in `implementation.md`.** Record it under `## Deviations`, and
name the document it departs from: `requirements.md` or `design.md`. Never edit either one: an
approved document changes only when the user reruns its skill. `/critique --concern` reads that
section as part of the intent, so it checks the code against the departure the user approved. A
deviation that reaches beyond this concern also becomes a proposed map edit.

Automated verification failing is not automatically an escalation — a worker that can fix it
within the design should. It escalates when the fix would require departing from the design.

## Notes

- Never commit to the default branch. Push and open a PR only as `pr-first-contributions`
  authorizes: this concern's branch, and its draft PR. Marking the PR ready waits for the user
- If the design turns out to be wrong, stop and put it to the user. Never let the build quietly
  diverge from the approved documents
