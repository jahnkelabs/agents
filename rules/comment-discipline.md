---
description: Comments are disallowed by default; propose one only when the code cannot say it and the user approves
---

# Comment discipline

Code states what it does. This rule **disallows a comment by default**, and you never add one on your own judgment. You propose a comment, and the user approves it before it reaches the code. Every unapproved comment goes out of date and then misleads the next reader. `rules/output-discipline.md` puts artifact length out of scope, so this rule governs artifact existence instead.

## Rule of thumb

**Write no comment. Propose one only when it passes both tests below and the user approves it.**

The tests are what the code can express and what a reviewer gets wrong without the comment. A comment that repeats the code creates two copies of one fact, and only one copy stays true. Both tests must pass. One passing test is not enough, and neither is a reader who would merely like an explanation.

## Default policy

- **Default:** Write no comment. The code states the meaning.
- **Approval:** Propose the comment and stop. Wait for the user to approve it.
- **Approval scope:** One approval covers one comment. It never covers the file, the diff, or the next comment.
- **Scope:** Comments and docstrings in code you write or change, and the documentation that describes that code.
- **Admissible:** Both tests below pass. A comment a tool reads — a pragma, a directive, or a license header — is admissible without approval.
- **Exceptions:** Documentation the user asked for, and documentation that is itself the deliverable.

## The admission test

A comment passes only when **both** tests below pass.

**Test one: the code cannot say it.** The comment matches one of exactly three cases.

- **A non-obvious constraint.** The reader cannot see it from this file: `// The API rejects more than 500 ids per call.`
- **A deliberate deviation from the obvious alternative.** Name the alternative and the reason: `// Sequential on purpose: the endpoint limits by connection, not by key.`
- **A value that looks wrong and is correct.** Say why it is correct: `// 4096, not 4095: the header counts the trailing NUL.`

**Test two: a reviewer gets it wrong without the comment.** A competent reviewer reads this code and reaches a false conclusion. Or a future author makes a change that breaks it. State that specific wrong conclusion when you propose the comment. A comment that only makes the code easier to read fails this test.

## Proposing a comment

Name the file and line, and quote the exact comment text. Name which of the three cases it matches, and state the wrong conclusion it prevents. Then stop and wait. Do not write the comment into the file first and ask afterward.

Propose nothing when either test fails. A rejected proposal is a correct outcome, and a proposal you cannot justify is noise the user has to read.

## What a comment must never do

- **Restate the code.** `// increment the counter` above `counter++` gives you a second place to maintain.
- **Carry background.** Design history, the reason for the whole approach, and links to a discussion belong in documentation or the commit message.
- **Narrate the change.** A comment must make sense to a reader who never saw your diff. `// now uses the new client` is commit-message content.

## Removing a comment

Delete a comment only when it sits inside code you are already changing. Delete it when it is wrong, when the code already says it, or when it narrates a change. Do not search for comments to delete, in this file or any other. A comment outside your declared paths is not yours to touch.

## When to change the documentation

Update documentation on two triggers only. The first is a documented claim that your change made false. The second is behavior a reader cannot infer from the code. Without one of these two triggers, leave the documentation as you found it.

Documentation the user asked for is outside this rule, and so is documentation that is itself the deliverable. Neither one needs a trigger.

## Example

One line of code, and the proposal that earns a comment on it:

**Prefer:** `client.py:88 — propose "// Two retries only: the gateway drops the connection on the third attempt." Case: a non-obvious constraint. Without it, a reviewer raises the count and the gateway drops the connection.`

**Avoid:** Writing `// Retry the request. Added retries here because the API was flaky, see the ticket for the background.` into the file.

## Anti-patterns

| Anti-pattern | Why it fails |
|---|---|
| A comment written into the file without approval | The default is no comment, and the user never got the choice |
| A comment that passes test one and fails test two | Nobody misreads the code without it, so it only adds maintenance |
| Treating one approval as approval for the diff | Each comment carries its own cost, so each one needs its own decision |
| Proposing a comment to look thorough | The user reads a proposal you already know fails a test |
| `// increment the counter` above `counter++` | Two copies of one fact, and only the comment can go out of date |
| `// now uses the new client` | A reader who never saw the diff cannot tell what changed |
| A paragraph of design history above a function | The documentation and the commit message already hold it |
| A comment deleted outside the code you changed | An unrelated hunk that every reviewer has to read |
| A docstring that lists the parameter names again | The signature already carries them |
| Documentation updated because the file was already open | No falsified claim and no new behavior, so nothing to record |
