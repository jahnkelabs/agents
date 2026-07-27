---
description: PR-first git workflow with conventional titles, draft PRs, and squash-merge descriptions
---

# PR-first contributions

Contribute code through pull requests by default. The PR—not the individual branch commits—is the unit of contribution, and it carries the record of the change into the default branch's history.

## Default policy

- **Default:** All repository changes are delivered via a **PR** against the repo's default branch, resolved from `origin/HEAD` (`main`, `master`, or whatever it points to).
- **Exceptions:** Skip the PR workflow only when the user **clearly** instructs otherwise (e.g. "commit directly to main", "no PR", "push straight to default branch"). If ambiguous, ask once; otherwise follow this rule.
- **Branch:** Work on a feature branch cut from the latest default branch, named for the work and prefixed by type—`feat/…`, `fix/…`, `chore/…`. Never commit on the default branch.
- **Commits:** Only create commits when the user asks or when the PR workflow clearly requires it. No secrets, no `--no-verify`, no amend unless allowed.
- **Pushes:** Never push or open a PR without explicit approval. Approval for one push does not carry to the next.
- **Draft by default:** Open PRs as drafts. Mark ready for review only when the user says so.
- **Destructive git:** No `reset --hard`, force-push, or history rewrite without explicit approval.

## Branch staleness check

Run before the first commit on the current branch in the session, and again before push or PR creation.

```bash
git fetch origin

BRANCH="$(git branch --show-current)"
DEFAULT="$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')"
[ -z "$DEFAULT" ] && DEFAULT="$(git remote show origin | awk '/HEAD branch/ {print $NF}')"
[ -z "$DEFAULT" ] && { echo "cannot resolve the default branch — staleness check did not run"; exit 1; }

git diff --quiet "origin/${DEFAULT}"..HEAD && CONTENT_DIFF=empty || CONTENT_DIFF=present
MERGED="$(gh pr list --head "$BRANCH" --state merged --limit 1 --json number,title,mergedAt 2>/dev/null)"
```

Both signals are needed. Content alone is not enough—a branch with no commits yet, and a branch whose commits cancel out, both report `empty` while being perfectly good places to work. A merged PR alone is not enough either, because a squash-merged branch still reports commits ahead while carrying no unmerged content, which is why `git rev-list --count` is the wrong test.

Resolution must succeed before either signal means anything: a `git diff` against an unresolved ref exits non-zero and reads as `present`, so a silent resolution failure would silently disable the check. Hence the abort above.

**Stale—do not commit yet:** `CONTENT_DIFF` is `empty` **and** `MERGED` is non-empty. Tell the user the branch is already merged, citing the PR number and title from `MERGED`. Then `git switch "${DEFAULT}"`, `git pull origin "${DEFAULT}"`, and cut a fresh branch for the work. Carry forward uncommitted changes or cherry-pick only with user approval.

**Fresh:** `CONTENT_DIFF` is `empty` and `MERGED` is empty—a new branch with nothing on it yet. Proceed.

**Carries work:** `CONTENT_DIFF` is `present`. Keep the branch. If a prior PR on it already merged, this content needs a **new** PR; do not assume the old one is still open.

## Before presenting work

- **Run the repo's quality gates**—tests, lint, type checks, whatever the project uses. Report failures with the shortest decisive output rather than hiding or working around them. If a failure is out of scope, say so plainly instead of leaving it silently broken.
- **Leave a clean tree.** `git status` shows no uncommitted changes and no stray untracked files.
- **Summarize and stop.** State what changed, the quality gate results, and `git log --oneline "origin/${DEFAULT}"..HEAD`—against the remote ref, since a local default branch may lag. Then wait. Do not push as part of "finishing".

## Push and open the PR

```bash
git push -u origin HEAD && git remote prune origin

gh pr create --draft --title "<conventional-title>" --body "$(cat <<'EOF'
<What changed and why—enough for a future reader of `git log`.>

<Breaking changes, migrations, follow-ups, intentional tradeoffs, links to issues or discussions. Omit if none.>
EOF
)"
```

If a PR for this branch is already open, push the new commits and update its title and description instead—do not open a duplicate. Return the PR URL to the user.

## Title and description

PRs are squash-merged: the PR title becomes the commit title on the default branch and the PR body becomes the commit body. Write both to stand alone in `git log` without the PR thread—branch-level commit messages are secondary. Keep the body concise, skip boilerplate headers like `## Summary` unless they add clarity, and do not include a test plan section unless the user explicitly asks for one.

The title is `<type>(<scope>): <short description>`—lowercase type, optional but encouraged scope, and one of exactly three types, which semantic PR checks in repos like Sage require.

| Type | Use for | Example |
|------|---------|---------|
| `feat` | New behavior or user-facing capability | `feat(cli): add install doctor command` |
| `fix` | Bug fix | `fix(auth): handle expired token refresh` |
| `chore` | Tooling, CI, deps, refactors without behavior change, docs-only | `chore(ci): bump golangci-lint` |

If the change spans multiple types, pick the dominant one or split into multiple PRs (use `@split-to-prs` for large mixed work).
