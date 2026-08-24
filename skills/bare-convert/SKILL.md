---
name: bare-convert
description: Set up or convert a repository into the bare-plus-worktrees layout that milestone worktrees need
argument-hint: "[set-up | convert] [url or clone path]"
disable-model-invocation: true
---

# Bare convert

Turn a repository into a container, so `/worktree` can cut a milestone tree inside it. Two
modes: **set up** and **convert**.

Set up clones a repository this machine does not hold yet. Convert rewrites a clone you already
work in, and it preserves uncommitted work. Convert is the destructive mode. It moves the tree
you work in, so it reports every path before it acts.

`rules/solo-agent-orchestration.md` carries the worktree standard. This skill implements that
standard and invents no second convention.

`/worktree` owns cut, provision, and teardown. It also owns the provisioning contract. This
skill hands over once the container exists, and it restates none of that contract.

## The layout

The container is the repository's own path, at whatever depth it sits.

```
<container>/                       the repository's own path
  .git/                            bare repository
  main/                            the user's stable worktree, never removed
  <plan-slug>-<milestone-slug>/    a milestone worktree
```

## Set up

Use this mode for a repository that this machine does not hold yet.

```bash
git clone --bare "<url>" "<container>/.git"
git --git-dir="<container>/.git" config remote.origin.fetch \
  '+refs/heads/*:refs/remotes/origin/*'
git --git-dir="<container>/.git" fetch origin
git --git-dir="<container>/.git" remote set-head origin --auto
DEFAULT="$(git --git-dir="<container>/.git" symbolic-ref refs/remotes/origin/HEAD \
  | sed 's@^refs/remotes/origin/@@')"
git --git-dir="<container>/.git" worktree add "<container>/main" "${DEFAULT}"
```

A bare clone sets no fetch refspec. Without one, `origin/HEAD` and every other
remote-tracking ref stays absent, and cut mode reads `origin/HEAD` for its base.

## Convert

Use this mode to turn an existing clone into the layout. It preserves uncommitted work.

### Preflight everything first

Run every check below before the first move. Each one is cheap. A failure after the first move
leaves the tree somewhere the user did not put it.

The block also resolves `<staging>`, the directory holding the record this convert verifies
against. `<staging>` sits beside `<clone>`, never inside it. The convert moves `<clone>`, so a
file inside it does not survive at a stable path.

```bash
test -d "<clone>/.git"                                  # a plain clone, not already converted
test ! -e "<clone>/main"                                # the destination name is free
test ! -e "<clone>/main-reg"                            # the registration name is free
test ! -e "$(dirname "<clone>")/.$(basename "<clone>").wt-convert"
STAGING="$(dirname "<clone>")/.$(basename "<clone>").wt-verify"
test ! -e "${STAGING}"                                  # the <staging> path is free
BRANCH="$(git -C "<clone>" symbolic-ref --short HEAD)"  # fails on a detached HEAD
```

Stop on any failure and report which check failed. A detached HEAD needs a named branch first,
because `worktree add` takes one.

### Report before you move anything

Print every absolute path that changes, and the uncommitted state you carry over. Change
nothing until the user approves. `rules/chat-vocabulary.md` gives the shape of that gate.

**Approve — convert `<clone>` to a container**

```
container   <clone>                stays at this path
worktree    <clone>          ->    <clone>/main
bare repo   <clone>/.git     ->    <clone>/.git, core.bare true
branch      <branch>               carried over, checked out at <clone>/main
carried     <n> modified, <n> staged, <n> untracked, <n> ignored

Convert this clone?
```

⏸ waiting on you: approve this conversion, or name a different clone

### Record the state, then move

```bash
mkdir "${STAGING}"
git -C "<clone>" status --porcelain --ignored > "${STAGING}/dirt-before.txt"
```

`--ignored` is load-bearing. Without it the file lists no ignored path, and the verification
below then proves nothing about `vendor/` or `node_modules/`.

Move the clone under a container at its own path:

```bash
PARENT="$(dirname "<clone>")"; NAME="$(basename "<clone>")"
mkdir "${PARENT}/.${NAME}.wt-convert"
mv "<clone>" "${PARENT}/.${NAME}.wt-convert/main"
mv "${PARENT}/.${NAME}.wt-convert" "<clone>"
mv "<clone>/main/.git" "<clone>/.git"
git --git-dir="<clone>/.git" config core.bare true
```

Every placeholder above carries quotes, and so does every one below. A clone at a path holding
a space otherwise splits. `dirname` then receives two arguments, and `mkdir` asks for a name
holding a newline. The conversion aborts after the move already happened.

The working tree now sits at `<clone>/main`, and its content never moved. Register it as a
linked worktree:

```bash
git --git-dir="<clone>/.git" worktree add --no-checkout "<clone>/main-reg" "${BRANCH}"
rm -f "<clone>/main-reg/.git"
rmdir "<clone>/main-reg"
cp "<clone>/.git/index" "<clone>/.git/worktrees/main-reg/index"
mv "<clone>/.git/worktrees/main-reg" "<clone>/.git/worktrees/main"
printf 'gitdir: %s\n' "<clone>/.git/worktrees/main" > "<clone>/main/.git"
git -C "<clone>/main" worktree repair
```

The index copy carries the staged half of the uncommitted work. A new linked worktree starts
with an empty index, and without the copy every tracked file reads as deleted.

### Roll back a failed step

Each step below undoes the one above it. Run them in reverse order from the step that failed,
and report what you undid.

```
worktree repair          nothing to undo; re-run it
gitdir file              rm -f "<clone>/main/.git"
worktrees rename         mv "<clone>/.git/worktrees/main" "<clone>/.git/worktrees/main-reg"
index copy               rm -f "<clone>/.git/worktrees/main-reg/index"
worktree add             rm -rf "<clone>/main-reg"
                         then git --git-dir="<clone>/.git" worktree prune
core.bare                git --git-dir="<clone>/.git" config core.bare false
.git move                mv "<clone>/.git" "<clone>/main/.git"
container rename         mv "<clone>" "${PARENT}/.${NAME}.wt-convert"
clone move               mv "${PARENT}/.${NAME}.wt-convert/main" "<clone>"
mkdir                    rmdir "${PARENT}/.${NAME}.wt-convert"
staging mkdir            rm -rf "${STAGING}"
```

A full rollback returns the clone to its original path with its uncommitted work intact. Report
the path the user should find their tree at, whether the rollback ran to the end or stopped.

### Verify, then remove `<staging>`

```bash
git -C "<clone>/main" status --porcelain --ignored \
  | diff -u "${STAGING}/dirt-before.txt" -
```

An empty diff means the conversion kept the modified, staged, untracked, and ignored files.
Both status calls pass `--ignored`, so the diff covers all four kinds. Stop and report anything
else, and keep `<staging>` for the report.

Remove `<staging>` once the diff is empty:

```bash
rm -rf "${STAGING}"
```

## Then hand over

The container is ready. `/worktree cut` takes it from here, and it derives the container path
itself from any worktree inside it.
