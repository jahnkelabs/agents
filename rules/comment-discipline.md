---
description: Admit a comment only when it says something the code cannot
---

# Comment discipline

Code states what it does. A comment is for **what the code cannot say**. Three things qualify: an outside constraint, a deliberate deviation, and a value that looks wrong. Every other comment goes out of date and then misleads the next reader. `rules/output-discipline.md` puts artifact length out of scope, so this rule governs artifact existence instead.

## Rule of thumb

**A comment earns its place when it says something the code cannot say.**

The test is what the code can express, not what a new reader wants explained. A comment that repeats the code creates two copies of one fact, and only one copy stays true. Ask what a reader still does not know after reading the code, then write only that.

## Default policy

- **Default:** Write no comment. The code states the meaning.
- **Scope:** Comments and docstrings in code you write or change, and the documentation that describes that code.
- **Admissible:** The three cases below, and nothing else.
- **Exceptions:** Documentation the user asked for, and documentation that is itself the deliverable.

## The three admissible comments

- **A non-obvious constraint.** The reader cannot see it from this file: `// The API rejects more than 500 ids per call.`
- **A deliberate deviation from the obvious alternative.** Name the alternative and the reason: `// Sequential on purpose: the endpoint limits by connection, not by key.`
- **A value that looks wrong and is correct.** Say why it is correct: `// 4096, not 4095: the header counts the trailing NUL.`

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

One line of code, commented twice:

**Prefer:** `// Two retries only: the gateway drops the connection on the third attempt.`

**Avoid:** `// Retry the request. Added retries here because the API was flaky, see the ticket for the background.`

## Anti-patterns

| Anti-pattern | Why it fails |
|---|---|
| `// increment the counter` above `counter++` | Two copies of one fact, and only the comment can go out of date |
| `// now uses the new client` | A reader who never saw the diff cannot tell what changed |
| A paragraph of design history above a function | The documentation and the commit message already hold it |
| A comment deleted outside the code you changed | An unrelated hunk that every reviewer has to read |
| A docstring that lists the parameter names again | The signature already carries them |
| Documentation updated because the file was already open | No falsified claim and no new behavior, so nothing to record |
