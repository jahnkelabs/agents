---
name: worktree
description: Set up, convert, and provision a bare-plus-worktrees repository so each milestone gets its own tree
argument-hint: "[set-up | convert | cut] [repo] [milestone]"
disable-model-invocation: true
---

# Worktree

Give every milestone worker its own working tree. Three modes: **set up**, **convert**, and
**cut**.

A milestone loop needs this before it can run. A fresh worktree holds no `.env`, no
`auth.json`, no `vendor/`, and no `node_modules/`. It also cannot start a container stack
without colliding with the stack already running. Every gate in the corpus fails on an
unprovisioned worktree for reasons unrelated to the change.

`rules/solo-agent-orchestration.md` carries the worktree standard. This skill implements that
standard and invents no second convention.

## The layout

The container is the repository's own path, at whatever depth it sits.

```
<container>/                       the repository's own path
  .git/                            bare repository
  main/                            the user's stable worktree, never removed
  <plan-slug>-<milestone-slug>/    a milestone worktree
  <plan-slug>-<milestone-slug>/    a second milestone worktree
```

Repositories on this machine sit at `~/Code/<org>/<repo>`:

```
~/Code/jahnkelabs/agents/
  .git/
  main/
  2026-08-23t2304-agents-skills-revision-m1-auth/
  2026-08-23t2304-agents-skills-revision-m2-installer/
```

Every milestone worktree carries the plan slug as a prefix. The plan slug leads with a sortable
timestamp, so one plan's worktrees sort together and two plans never interleave. The stable
worktree keeps the name `main`, and it carries no prefix.

The branch stays `<type>/<milestone-slug>`. The plan prefix applies to the worktree path rather
than to the branch.

Every slug is lowercase, because a KV key carries it.

## Set up

Use this mode for a repository that this machine does not hold yet.

```bash
git clone --bare <url> <container>/.git
git --git-dir=<container>/.git config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
git --git-dir=<container>/.git fetch origin
git --git-dir=<container>/.git remote set-head origin --auto
DEFAULT="$(git --git-dir=<container>/.git symbolic-ref refs/remotes/origin/HEAD \
  | sed 's@^refs/remotes/origin/@@')"
git --git-dir=<container>/.git worktree add <container>/main "${DEFAULT}"
```

A bare clone sets no fetch refspec. Without one, `origin/HEAD` and every other
remote-tracking ref stays absent, and cut mode reads `origin/HEAD` for its base.

## Convert

Use this mode to turn an existing clone into the layout. It preserves uncommitted work.

**Report first.** Print every absolute path that changes, and the uncommitted state you carry
over. Change nothing until the user approves. `rules/chat-vocabulary.md` gives the shape of
that gate.

```
container   <clone>                stays at this path
worktree    <clone>          ->    <clone>/main
bare repo   <clone>/.git     ->    <clone>/.git, core.bare true
```

Record the state before you move anything:

```bash
git -C <clone> status --porcelain > <staging>/dirt-before.txt
```

Move the clone under a container at its own path:

```bash
PARENT="$(dirname <clone>)"; NAME="$(basename <clone>)"
mkdir "${PARENT}/.${NAME}.wt-convert"
mv <clone> "${PARENT}/.${NAME}.wt-convert/main"
mv "${PARENT}/.${NAME}.wt-convert" <clone>
mv <clone>/main/.git <clone>/.git
git --git-dir=<clone>/.git config core.bare true
```

The working tree now sits at `<clone>/main`, and its content never moved. Register it as a
linked worktree:

```bash
git --git-dir=<clone>/.git worktree add --no-checkout <clone>/main-reg <branch>
mv <clone>/main-reg/.git <clone>/main/.git
rmdir <clone>/main-reg
cp <clone>/.git/index <clone>/.git/worktrees/main-reg/index
mv <clone>/.git/worktrees/main-reg <clone>/.git/worktrees/main
printf 'gitdir: %s\n' <clone>/.git/worktrees/main > <clone>/main/.git
git -C <clone>/main worktree repair
```

The index copy carries the staged half of the uncommitted work. A new linked worktree starts
with an empty index, and without the copy every tracked file reads as deleted.

Verify before you remove the staging directory:

```bash
git -C <clone>/main status --porcelain | diff -u <staging>/dirt-before.txt -
```

An empty diff means the conversion kept the modified, staged, untracked, and ignored files.
Stop and report anything else.

## Cut

Use this mode to create a milestone worktree and provision it.

Refuse on a plain clone, and print the convert command:

```bash
if ! git --git-dir=<container>/.git rev-parse --is-bare-repository 2>/dev/null \
     | grep -qx true; then
  echo "error: <container> is a plain clone, not a container" >&2
  echo "run: /worktree convert <container>" >&2
  exit 1
fi
```

Then cut the worktree and provision it:

```bash
git -C <container>/main worktree add \
  <container>/<plan-slug>-<milestone-slug> -b <type>/<milestone-slug> <base>
<container>/main/scripts/wt-provision.sh \
  <container>/main <container>/<plan-slug>-<milestone-slug>
```

`<base>` is `origin/HEAD`, or the predecessor milestone's branch when the milestones stack.
Record the path under `plan:<slug>:milestone:<m>:worktree`, as the orchestration rule requires.

## The provisioning contract

Each target repository commits its own script at `scripts/wt-provision.sh`. It takes the source
worktree and the target worktree as arguments:

```bash
scripts/wt-provision.sh <source-worktree> <target-worktree>
```

The script owns three responsibilities.

### Files

**Copy the machine-local files.** `.env`, `auth.json`, and certificates are untracked, so a
fresh worktree holds none of them.

**Clone the derived state, then reconcile it.** The reconcile re-runs the install. It is
mandatory rather than optional. A cloned `.terraform/` or `vendor/` can carry absolute paths
that point back at the source worktree. A cloned `node_modules/` matches whatever lockfile the
source held.

A clone alone is therefore unsafe. The clone gives you the speed, and the reconcile gives you
the correctness.

### Containers

**Publish no host ports.** Generate a worktree compose override that resets every port list:

```yaml
services:
  app:
    ports: !reset []
  db:
    ports: !reset []
```

`ports: !reset []` removes every published port on Compose v5.1.2, verified. Compose discards
the base port list rather than merging it.

**Run the gates inside the compose network.**

```bash
docker compose -f docker-compose.yml -f docker-compose.worktree.yml run --rm app <gate>
```

The compose network sits closer to production than a host-published port, which is what
`rules/testing-philosophy.md` asks for.

**Name the project explicitly.** Export `COMPOSE_PROJECT_NAME=<repo>-<milestone>`. Compose
otherwise derives the project name from the directory basename, verified. Two repositories can
hold a milestone with the same slug, and their stacks then collide on one name.

This contract is what makes worktrees viable at all. Three of the user's repositories bind
ports that no offset can move. `exposure`, `reso-data-extractor`, and `alloy` each bind 80,
443, and one admin port. Shifting 443 breaks every URL the app generates.

### Shared infrastructure stays singleton

LocalStack, Kafka, and OpenSearch run once, as `util-docker-compose` already treats them.
Isolation there comes from naming buckets, topics, and indices per milestone. It never comes
from a second instance.

Postgres and Valkey run per worktree.

## The clone helper

Every provisioning script calls one shared helper, so fifteen repositories do not grow fifteen
dialects:

```bash
~/.claude/bin/wt-clone.sh <source> <destination>
```

It clones copy-on-write where the filesystem supports one, and it copies plainly everywhere
else. It reports the mode it chose, and it exits non-zero when the copy fails.

The helper checks the filesystem before it copies. `cp -c` on macOS falls back to a plain copy
without reporting it, and `cp --reflink=auto` does the same on Linux. A caller that expected a
clone would otherwise consume the full size of the source with no warning.

Measured on APFS: a 500 MB clone took 0.00s and consumed 0 MB. A plain copy of that file took
0.19s and consumed 500 MB. Diverging 100 MB of the clone then consumed 100 MB. A recursive
clone runs at roughly 5,000 files per second. Time therefore scales with file count rather than
with bytes.

## Teardown

Tear the stack down at milestone close. Remove the worktree after the push succeeds.

```bash
COMPOSE_PROJECT_NAME=<repo>-<milestone> docker compose \
  -f docker-compose.yml -f docker-compose.worktree.yml down -v --remove-orphans
git -C <container>/main worktree remove <container>/<plan-slug>-<milestone-slug>
git --git-dir=<container>/.git worktree prune
```

`down -v` removes the named volumes, and `--remove-orphans` removes a container that the
current file no longer declares. The branch lives on the remote once the push succeeds, so the
worktree is disposable.

## The resource ceiling

Docker holds 16.8 GB and 11 CPUs on this machine. That bounds concurrent milestone stacks to
roughly three. `/implement`'s roster gate reads that ceiling when it proposes milestone
parallelism.
