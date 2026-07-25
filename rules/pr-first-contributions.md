---
description: PR-first git workflow with conventional titles, draft PRs, and squash-merge descriptions
---

# PR-first contributions

Contribute code through pull requests by default. Use conventional PR titles and a concise PR description—both become the squash-merge commit on the default branch. Never commit on a branch whose prior PR is already merged with no new work on top of the default branch.

## Default policy

- **Default:** All repository changes are delivered via a **PR** against the repo’s default branch (`main`, `master`, or whatever `origin/HEAD` points to).
- **Exceptions:** Skip the PR workflow only when the user **clearly** instructs otherwise (e.g. “commit directly to main”, “no PR”, “push straight to default branch”). If ambiguous, ask once; otherwise follow this rule.
- **Commits:** Only create commits when the user asks or when the PR workflow clearly requires it. No secrets, no `--no-verify`, no amend unless allowed.
- **Pushes:** Never push or open a PR without explicit approval. Approval for one push does not carry to the next.
- **Draft by default:** Open PRs as drafts. Mark ready for review only when the user says so.

## Workflow

```
Task progress:
- [ ] Confirm PR workflow applies (not an explicit bypass)
- [ ] Run branch staleness check
- [ ] Ensure on a feature branch (not default, not stale)
- [ ] Implement changes
- [ ] Run quality gates; report any failures
- [ ] Commit everything; leave a clean tree
- [ ] Summarize what changed, then STOP for approval
- [ ] Re-run staleness check before push
- [ ] Push branch
- [ ] Open or update PR with conventional title and description
```

### 1. Confirm PR workflow applies

If the user explicitly bypassed PRs, commit/push per their instructions and stop using this checklist.

### 2. Branch staleness check

Run **before the first commit** on the current branch in the session, and **again before push or PR creation**.

```bash
git fetch origin

BRANCH="$(git branch --show-current)"
DEFAULT="$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')"
[ -z "$DEFAULT" ] && DEFAULT="$(git remote show origin | awk '/HEAD branch/ {print $NF}')"

AHEAD="$(git rev-list --count "origin/${DEFAULT}..HEAD" 2>/dev/null || echo 0)"
MERGED="$(gh pr list --head "$BRANCH" --state merged --limit 1 --json number,title,mergedAt 2>/dev/null)"
```

**Stale branch — do not commit yet** when any of:

- `MERGED` is non-empty (JSON array with at least one PR) **and** `AHEAD` is `0`
- `AHEAD` is `0` **and** `git merge-base --is-ancestor HEAD "origin/${DEFAULT}"` (branch tip fully contained in default)

**Recovery:**

1. Tell the user the branch was already merged; cite the merged PR number and title from `gh`.
2. Update local default: `git switch "${DEFAULT}"` and `git pull origin "${DEFAULT}"` (or `git switch -c <new-branch> "origin/${DEFAULT}"`).
3. Create a fresh branch named for the work, preferably prefixed by type: `feat/…`, `fix/…`, or `chore/…`.
4. Carry forward uncommitted changes or cherry-pick only with user approval. No destructive git (`reset --hard`, force-push) without explicit approval.

**OK to keep the same branch name:**

- `AHEAD > 0` after a prior merged PR — new commits exist; open a **new** PR (do not assume the old PR is still open).

**On default branch before work:**

- Create a feature branch from latest `origin/${DEFAULT}` before committing.

### 3. Implement and commit

Make changes on the feature branch. Branch commits can be informal; **the PR title and description are what matter** because the default merge strategy is **squash**, and those fields become the commit title and body on the default branch.

### 4. Before presenting work

Do all of this before asking for approval to push:

- **Run the repo's quality gates** — tests, lint, type checks, whatever the project uses. Report failures with their output rather than hiding or working around them. If a failure is non-trivial and out of scope, say so plainly instead of leaving it silently broken.
- **Commit everything.** `git status` should show a clean tree — no uncommitted changes, no stray untracked files.
- **Summarize and stop.** State what changed, the quality gate results, and the diff summary (`git log --oneline <default>..HEAD`). Then wait. Do not push as part of "finishing".

### 5. Push and open PR

Only after explicit approval:

1. In parallel: `git status`, `git diff` (staged and unstaged), remote tracking status, `git log`, `git diff <default>...HEAD`.
2. Push: `git push -u origin HEAD`.
3. Draft the PR **title** (conventional; see below) and **description** (concise summary + relevant context; see below).
4. Create or update, **as a draft** unless told otherwise:

```bash
gh pr create --draft --title "<conventional-title>" --body "$(cat <<'EOF'
<Concise summary of what changed—1–3 short paragraphs or bullets.>

<Optional: decisions, tradeoffs, migration notes, or other context worth preserving in git history. Omit if none.>
EOF
)"
```

5. Return the PR URL to the user.

If a PR for this branch is already open, push new commits and update the PR title/description if the squash-merge message should change; do not open a duplicate.

Do **not** include a test plan section in the PR body unless the user explicitly asks for one.

## Squash merge (default)

Assume PRs are **squash-merged** into the default branch. The squash commit uses:

- **Commit title** ← PR title (must be conventional: `feat`, `fix`, or `chore`)
- **Commit body** ← PR description

Write both so they stand alone in `git log` without reading the PR thread. Branch-level commit messages are secondary.

## Conventional PR titles

The **PR title** must use one of these types only: `feat`, `fix`, `chore`.

**Format:**

```
<type>(<optional-scope>): <short description>
```

| Type | Use for |
|------|---------|
| `feat` | New behavior or user-facing capability |
| `fix` | Bug fix |
| `chore` | Tooling, CI, deps, refactors without behavior change, docs-only |

**Examples:**

- `feat(cli): add install doctor command`
- `fix(auth): handle expired token refresh`
- `chore(ci): bump golangci-lint`

**Rules:**

- Title must start with `feat`, `fix`, or `chore` (required for semantic PR checks in repos like Sage).
- Use lowercase type; scope is optional but encouraged.
- If the change spans multiple types, pick the dominant type or split into multiple PRs (use `@split-to-prs` for large mixed work).

## PR description

The PR body becomes the squash-merge **commit description**. Keep it concise.

**Include:**

- What changed and why (enough for a future reader of `git log`)
- Notable considerations: breaking changes, migrations, follow-ups, intentional tradeoffs, links to issues/discussions when helpful

**Do not include:**

- A test plan section (unless the user explicitly requests one)
- Boilerplate headers like `## Summary` unless they add clarity

**Example body:**

```
Add install doctor command that verifies Go, git, and gh are on PATH.

Uses the same check order as CONTRIBUTING.md. Skips network checks when
offline so local dev isn't blocked. Breaking: none.
```
