---
description: PR-first git workflow with conventional titles, draft PRs, and squash-merge descriptions
---

# PR-first contributions

Contribute code through pull requests by default. The PR is the unit of contribution, not the individual branch commits. The PR carries the record of the change into the default branch's history.

## Default policy

- **Default:** Deliver every repository change through a **PR** against the repo's default branch. Resolve that branch from `origin/HEAD`: `main`, `master`, or whatever it points to.
- **Exceptions:** Skip the PR workflow only when the user **clearly** instructs otherwise. Examples: "commit directly to main", "no PR", "push straight to default branch". If the request is ambiguous, ask once. Otherwise follow this rule.
- **Branch:** Cut a feature branch from the latest default branch. Name it for the work and prefix it by type: `feat/…`, `fix/…`, `chore/…`. Never commit on the default branch.
- **Commits:** Only create commits when the user asks or when the PR workflow clearly requires it. No secrets, no `--no-verify`, and no amend unless the user allows it.
- **Pushes:** Never push or open a PR without explicit approval. Approval for one push does not carry to the next.
- **Draft by default:** Open PRs as drafts. Mark ready for review only when the user says so.
- **Destructive git:** No `reset --hard`, force-push, or history rewrite without explicit approval.

## Branch staleness check

Run this check before the first commit on the current branch in this session. Run it again before you push or open a PR.

```bash
git fetch origin

BRANCH="$(git branch --show-current)"
DEFAULT="$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')"
[ -z "$DEFAULT" ] && DEFAULT="$(git remote show origin | awk '/HEAD branch/ {print $NF}')"
[ -z "$DEFAULT" ] && { echo "cannot resolve the default branch — staleness check did not run"; exit 1; }

git diff --quiet "origin/${DEFAULT}"..HEAD && CONTENT_DIFF=empty || CONTENT_DIFF=present
MERGED="$(gh pr list --head "$BRANCH" --state merged --limit 1 --json number,title,mergedAt 2>/dev/null)"
```

You need both signals. Content alone is not enough. A branch with no commits yet reports `empty`, and so does a branch whose commits cancel out. Both are good places to work.

A merged PR alone is not enough either. A squash-merged branch still reports commits ahead, and it carries no unmerged content. `git rev-list --count` is therefore the wrong test.

Resolution must succeed before either signal means anything. A `git diff` against an unresolved ref exits non-zero, which reads as `present`. A silent resolution failure would therefore disable the check. The block above aborts for that reason.

**Stale—do not commit yet:** `CONTENT_DIFF` is `empty` **and** `MERGED` is non-empty. Tell the user that the branch is already merged. Cite the PR number and title from `MERGED`. Then `git switch "${DEFAULT}"`, `git pull origin "${DEFAULT}"`, and cut a fresh branch for the work. Carry forward uncommitted changes or cherry-pick only with user approval.

**Fresh:** `CONTENT_DIFF` is `empty` and `MERGED` is empty—a new branch with nothing on it yet. Proceed.

**Carries work:** `CONTENT_DIFF` is `present`. Keep the branch. If a prior PR on it already merged, this content needs a **new** PR. Do not assume the old PR is still open.

## Before presenting work

- **Run the repo's quality gates**—tests, lint, type checks, whatever the project uses. Report a failure with the shortest decisive output. Do not hide it and do not work around it. If a failure is out of scope, say so plainly. Do not leave it silently broken.
- **Leave a clean tree.** `git status` shows no uncommitted changes and no stray untracked files.
- **Summarize and stop.** State what changed, the quality gate results, and `git log --oneline "origin/${DEFAULT}"..HEAD`. Use the remote ref, because a local default branch may lag. Then wait. Do not push as part of "finishing".

## Push and open the PR

```bash
git push -u origin HEAD && git remote prune origin

gh pr create --draft --title "<conventional-title>" --body "$(cat <<'EOF'
<What changed and why—enough for a future reader of `git log`.>

<Breaking changes, migrations, follow-ups, intentional tradeoffs, links to issues or discussions. Omit if none.>
EOF
)"
```

A PR for this branch may already be open. Push the new commits, then update its title and description. Do not open a duplicate. Return the PR URL to the user.

## Title and description

Every PR lands as a squash merge. The PR title becomes the commit title on the default branch, and the PR body becomes the commit body. Write both so that a reader of `git log` needs nothing from the PR thread. Branch-level commit messages are secondary. Keep the body concise. Skip a boilerplate header such as `## Summary` unless it adds clarity. Do not include a test plan section unless the user explicitly asks for one.

The title is `<type>(<scope>): <short description>`. Use a lowercase type. A scope is optional, but include one where you can. Use one of exactly three types, which the semantic PR checks in repos such as Sage require.

| Type | Use for | Example |
|------|---------|---------|
| `feat` | New behavior or user-facing capability | `feat(cli): add install doctor command` |
| `fix` | Bug fix | `fix(auth): handle expired token refresh` |
| `chore` | Tooling, CI, deps, refactors without behavior change, docs-only | `chore(ci): bump golangci-lint` |

When a change spans multiple types, pick the dominant type or split the work into multiple PRs. Use `@split-to-prs` for large mixed work.
