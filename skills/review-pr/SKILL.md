---
name: review-pr
description: Adversarially review someone else's pull request with one critic agent per lens, and post the drafted review only after you approve it
argument-hint: "<PR number>"
disable-model-invocation: true
---

# Review a pull request

Review a pull request adversarially, and draft the review. `references/critique/run.md` runs
every lens, and this skill carries no lens text of its own.

**This skill edits nothing.** It applies no fix, writes no file in the repository, and runs no git
write. It posts the review only after you approve the draft. A post is visible outside the
repository, which is criterion C3 in `run.md`.

Only you start this skill. A model never invokes it on its own.

## Step 1 — Resolve the pull request

`$ARGUMENTS` names one PR number, in the current directory's repository. With no number, ask.
That question offers nothing to rank:

**Deciding — the pull request**

Which pull request should I review?

⏸ waiting on you: the pull request number

Read the PR and its diff:

```bash
gh pr view <N> --json number,title,url,body,state,baseRefOid,headRefOid
gh pr diff <N>
```

Keep `headRefOid`. Every comment attaches to that commit, and step 5 checks it again before it
posts.

Stop and say so where `gh pr view` fails, or where the diff is empty.

The lens agents read the existing conventions in the local clone. Compare `git rev-parse HEAD`
there with `baseRefOid`. Where the two differ, the target note says so. An agent then knows the
clone may differ from the PR's base.

## Step 2 — Resolve the intent

The intent is what the PR says it does. Each lens file's `pr:` line names what that lens reads:

- **The PR body.**
- **Each linked issue.** Take every issue the body names by number, and every issue GitHub links
  as closed by the PR. Read each one with `gh issue view <n> --json title,body`.
- **The codebase's existing conventions.** Someone else's PR has no design you approved. Design
  conformance checks the diff against the patterns the code already follows.

`gh pr view` on gh 2.70.0 has no field for the linked issues, so read them through GraphQL:

```bash
gh api graphql -F owner='{owner}' -F repo='{repo}' -F n=<N> -f query='
  query($owner: String!, $repo: String!, $n: Int!) {
    repository(owner: $owner, name: $repo) {
      pullRequest(number: $n) { closingIssuesReferences(first: 20) { nodes { number } } }
    }
  }'
```

A PR with an empty body and no linked issue states no requirement. `run.md` then drops every lens
that checks the diff against one, and the draft says so.

## Step 3 — Run the engine

Read `references/critique/run.md` in full, then run it with these inputs:

- the target: the diff text, the head commit, and the local clone's absolute path;
- the target note: every location names a line of the PR's head version, on the diff's right
  side. Name the clone's commit too, where it differs from the base;
- the intent: the `pr:` kind, with what step 2 read;
- the lens set: the catalog in `references/critique/lenses/`;
- the output mode: `report`, always;
- the runtimes: Claude;
- the slug `pr-<N>`, the pass `review`, and the tags `transient` and `pr-<N>`.

In `report` mode nothing reworks, and no finding escalates on its own. The ledger is the source of
the draft.

## Step 4 — Draft the review

Turn the ledger into a draft, with one comment per finding:

- **Inline**, where the finding's line falls inside a hunk of the diff. GitHub rejects an inline
  comment on a line outside every hunk.
- **In the summary**, for every other finding, and for every `proposed edit:` line. A systemic
  cause is a suggestion to the author, not a defect in this diff.

Each comment states the concrete failure, or the before and after, and the fix. It names its
severity. It says nothing about lenses, refuters, or this workflow, because the author needs none
of it.

Write no bare `@name` in a comment, because GitHub notifies that login. Put code in backticks.

The summary opens with one sentence on what the PR does. It then counts the findings by severity,
and lists the summary-only findings.

Write the payload to a file in this session's scratch directory, never in the repository:

```json
{
  "commit_id": "<headRefOid>",
  "body": "<the summary>",
  "comments": [
    { "path": "src/token.php", "line": 88, "side": "RIGHT", "body": "<the comment>" }
  ]
}
```

The payload carries no `event`, so GitHub holds the review as pending. Show the draft in chat: the
summary, then each comment under its `path:line`.

## Step 5 — Approve, then post

Post nothing until you approve this draft. One approval covers one draft, and a changed draft
needs a new approval. The gate takes the decision format in `rules/chat-vocabulary.md`:

> **Approve — post the review on PR `#<N>`**
>
> - **Found:** `<n>` inline comments and `<m>` summary items. The refutation pass dropped `<r>`
>   findings.
> - **Deciding:** whether this draft reaches GitHub. A post is visible outside the repository.
> - **Criticality:** medium. The review reaches one PR's author and its reviewers.
> - **Reversible:** partly. A pending review stays private until you submit it. A submitted review
>   notifies the author, and a later delete does not undo that.
>
> **A. Post it as a pending review**
>
> - **Pros:** only you see it on GitHub until you submit it from the PR's Files tab.
> - **Cons:** you take one more step on GitHub.
> - **Risks:** a pending review you forget never reaches the author.
> - **Constraints:** GitHub holds one pending review per reviewer on a PR, so an older one blocks
>   this post.
>
> **B. Submit it now, as a comment review**
>
> - **Pros:** the author sees it at once.
> - **Cons:** you read the comments in place only after the author can.
> - **Risks:** a comment on the wrong line reaches the author before you see it.
> - **Constraints:** the review neither approves nor requests changes.
>
> **C. Post nothing**
>
> - **Pros:** nothing reaches GitHub.
> - **Cons:** the findings stay in this chat.
> - **Risks:** none.
> - **Constraints:** none.
>
> **Recommendation:** A. You read every comment in place on the diff before anyone else sees it.
>
> Post the review on PR `#<N>`?
>
> ⏸ waiting on you: approve the post for PR `#<N>`, or name what to change

Before you post, read `headRefOid` again. Where it moved, stop and say so, because the comments'
lines belong to the old head.

Post with one call. `gh api` fills `{owner}` and `{repo}` from the current directory's repository:

```bash
gh api repos/{owner}/{repo}/pulls/<N>/reviews --method POST --input <the payload file>
```

For option B, add `"event": "COMMENT"` to the payload first. Never send `APPROVE` or
`REQUEST_CHANGES`. That verdict stays yours.

Report the review's `html_url` from the response. On option C, post nothing, and report the
payload file's absolute path.
