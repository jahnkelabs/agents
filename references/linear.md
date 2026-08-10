# Linear adapter

Tracker mapping for `/stash` and `/recall`. The commands own the semantics; this file owns
Linear's object model and field names.

Requires a connected Linear MCP server.

## Object mapping

| Concept | Linear |
|---|---|
| A loose idea | one issue, no project |
| A phased plan | a project, plus one issue per phase |
| The plan document | a document attached to the project |
| Phase ordering | `blockedBy` relations between issues |
| Which repo a phase targets | a label, or a line in the issue description |

## Discovery

Never assume a team, project, or state name — read them first.

| Need | Tool |
|---|---|
| Teams | `list_teams` |
| Existing projects | `list_projects` |
| Valid states for a team | `list_issue_statuses` |
| Existing labels | `list_issue_labels` |
| Parked work for `/recall` | `list_issues` filtered by assignee and open state |

A workspace with one team can use it without asking. With several teams, ask which one. Linear
cannot create the issue without a team.

## Writing a loose idea

```
save_issue(
  title="<short imperative title>",
  team="<team>",
  description="<the idea, plus where it came from>",
  state="<a triage or backlog state from list_issue_statuses>",
  priority=<0 none | 1 urgent | 2 high | 3 medium | 4 low>
)
```

`priority` is numeric, and the scale runs opposite to intuition — `1` is the most urgent, `4`
the least, `0` means unset.

## Writing a phased plan

Order matters: parents before children, dependencies last.

**1. Project** — Linear requires `name` and at least one team on create.

```
save_project(
  name="<plan title>",
  addTeams=["<team>"],
  summary="<one line, max 255 chars>",
  description="<the plan's Overview section>"
)
```

**2. Document** — carries the full plan body. Specify exactly one parent.

```
save_document(
  title="<plan title> — plan",
  project="<project name or id>",
  content="<the full pad content: research, plan, phases>"
)
```

Markdown goes in literally — real newlines, not escape sequences.

**3. One issue per phase.**

```
save_issue(
  title="Phase <N>: <name>",
  team="<team>",
  project="<project name or id>",
  description="<the phase section: Changes Required, Files, Verification>",
  labels=["<repo>"]
)
```

Collect every returned identifier before moving on.

**4. Dependencies**, once all issues exist.

```
save_issue(id="<phase N identifier>", blockedBy=["<phase N-1 identifier>"])
```

`blockedBy` and `blocks` are **append-only** — they never remove existing relations. Use
`removeBlockedBy` / `removeBlocks` to undo. Set the relation in one direction only; Linear
maintains the inverse. Setting both directions between the same pair creates a contradictory
graph.

**5. Verify.** Re-read the issues with `get_issue` and confirm the dependency chain matches the
plan's phase ordering. Directed relations are easy to set backwards, and a reversed chain looks
plausible until someone tries to implement it.

## Reading for `/recall`

```
get_issue(id="<identifier>")            → title, description, state, labels, relations
get_project(...)                        → the parent, if the issue has one
list_documents(project=...)             → the attached plan document
get_document(id=...)                    → its content
list_issues(project=...)                → siblings, to see what blocks what
```

Pull the parent project and its document, not just the issue. A phase on its own is missing the
plan it belongs to.

Check that every blocking issue is already done before you hand off to `/plan`. An unmet blocker
usually means you recalled the wrong item.

## Gotchas

- **`labels` replaces the whole set.** Omitting it leaves labels alone; passing a partial array
  silently drops the rest.
- **`id` on create is wrong.** Passing it turns a create into an update of some other issue.
- **`assignee`, not `assigneeId`.** Accepts a user id, name, email, or `"me"`.
- **`state` is a name or type**, and valid values differ per team.
- **Identifiers vs ids.** `ENG-142` is the identifier; most tools accept either, and the
  identifier is what to show the user.
- **Partial failures are real.** The project write can succeed while the issue writes fail.
  Report exactly what exists rather than retrying blindly.
