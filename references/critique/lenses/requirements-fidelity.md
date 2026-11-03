# Requirements fidelity

Batch: 1.
Applies when: always.
Tier: opus · high.
Question: Does the change do what the approved requirements state, no more, with nothing skipped or substituted?
Intent source:
  concern: `requirements.md`, every acceptance criterion and its proof command.
  pr: the PR body and the linked issue, read as the requirements.
  plan: this milestone's work item in the plan pad: Files, Exit criterion, Proof, and Invariants.
Finding: location · concrete failure, or before and after · fix · severity (bug | risk | nit).
Out of mandate: a departure from the approved design belongs to `design-conformance`.
  A wrong result inside an approved behavior belongs to `correctness`.
  A workaround for a symptom belongs to `root-cause`.

## What this lens hunts for

- An acceptance criterion the change does not meet, or meets only where its proof command never looks.
- Work no criterion asked for: a new flag, an extra file, or a behavior the requirements never name.
- A substitution: the change meets a criterion through a mechanism other than the one the requirements name.
- A proof command that passes on the tree before the change, so it proves nothing.
- A declared file the change never touches, or a changed file outside the declared list.

## Examples

- `skills/sweep/SKILL.md:40` · criterion 3 says the sweep never removes a worktree with unpushed
  commits. The step removes every worktree that carries the slug. Fix: run `git log @{u}..` first,
  and skip a tree that prints a commit. Severity `bug`.
- `src/export.py:12` · the change adds `--format yaml`. No criterion names YAML. Fix: remove the
  option, or raise it as a requirements edit. Severity `risk`.
- `scripts/check.sh:5` · the proof greps for `timeout`, and the old tree already contains that word.
  Fix: grep for the new key `connect_timeout`. Severity `risk`.

## What does not count

- A criterion the change meets in a way you would build differently. `design-conformance` and
  `simplicity` own that.
- A requirement you think the list lacks. The user approved the requirements, and this lens checks
  the change against them, not the list against your judgment.
