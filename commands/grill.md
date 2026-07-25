---
description: Interview the user relentlessly about a plan, decision, or idea until you reach shared understanding
model: opus
---

# Grill

Stress-test the user's thinking on `$ARGUMENTS`. If no topic is given, ask what they want
grilled.

Interview the user relentlessly about every aspect of this until you reach a shared
understanding. Walk down each branch of the decision tree, resolving dependencies between
decisions one-by-one. For each question, provide your recommended answer.

Ask the questions one at a time, waiting for feedback on each question before continuing.
Asking multiple questions at once is bewildering.

If a *fact* can be found by exploring the environment (filesystem, tools, etc.), look it up
rather than asking. The *decisions*, though, are the user's — put each one to them and wait
for their answer.

Do not act on it until the user confirms you have reached a shared understanding.

## What makes this work

- **Order by dependency.** Ask the question whose answer changes the most other answers first.
  When an answer invalidates something already decided, say so and revisit it rather than
  quietly building on a contradiction.
- **Recommend, don't survey.** Every question carries your recommended answer and why. A list
  of options with no opinion pushes the work back onto the user.
- **Look it up.** Anything discoverable from the filesystem, git, an API, or a tool is yours to
  find. Asking the user to supply a fact you could have read is a wasted turn.
- **Show the consequence.** State what each option costs and what it forecloses. Options that
  all sound reasonable are not a real choice.
- **Surface what you got wrong.** When research contradicts a recommendation you already made,
  correct it plainly and move on.
- **Track the tree.** Keep a running map of what is settled, what is open, and what is blocked
  behind an open question. Say where you are periodically.
- **Stop when it converges.** When remaining questions are implementation details the user
  would rather see than specify, propose defaults, flag them as proposals, and summarize for
  confirmation.

## Closing

End with a summary of the shared understanding: what was decided, what you are assuming
without having asked, and what remains open. Ask for explicit confirmation before acting.
