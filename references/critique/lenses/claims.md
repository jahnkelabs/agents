---
lens: claims
batch: 2
applies_when: always
tier:
  claude: { model: sonnet, effort: high }
  codex: { model: gpt-6.1-sol, effort: high }
intent:
  concern: "`requirements.md` and `design.md`, for the behavior the text must now describe."
  pr: "the PR body, for the behavior the text must now describe."
---
# Claims

## Question
Which doc, README, rule, comment, docstring, or type does the change make false?

## Finding
location · concrete failure, or before and after · fix · severity (bug | risk | nit).

## Out of mandate
Code that is wrong while the text is right belongs to `correctness`.
A true comment that restates the code belongs to `simplicity`.
New configuration with no documentation belongs to `operability`.

## What this lens hunts for

Search the repository for every name, flag, path, default, count, and error string the change
alters. Read each hit outside the diff, and ask whether it is still true. Check these places:

- The README, other docs, help text, and a changelog.
- Rules, skills, and references that state how the code behaves.
- Comments and docstrings next to the changed code.
- Type annotations and signatures that no longer match what the code returns.
- Text written for one plan or session: a milestone label, a decision id, a session slug, or
  "until the next milestone". It reads as false to anyone outside that session.

## Examples

- `skills/foo/SKILL.md:41` · says "until the next milestone". It names a milestone of the plan that
  wrote the file, and no reader of the shipped file has that plan. Fix: state the behavior by its
  condition, such as "where the caller supplies a concern". Severity `nit`.

- `README.md:164` · says two skills carry `disable-model-invocation`. The change deletes one, so one
  remains. Fix: "One skill carries it." Severity `risk`.
- `src/config.ts:8` · the docstring says "timeout in seconds". The change now passes milliseconds.
  Fix: correct the docstring, or rename the field `timeoutMs`. Severity `risk`.
- `loader.py:20` · `def load(path: str) -> dict` now returns `None` for a missing file. Fix:
  `-> dict | None`, and update the two callers that index the result. Severity `bug`.

## What does not count

- Text that was false before the change. Report only what this change made false.
- Wording you would improve, where the text stays true.
