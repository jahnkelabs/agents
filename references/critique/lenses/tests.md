# Tests

Batch: 2.
Applies when: always.
Tier: sonnet · high.
Question: Does each new or changed behavior have a test that fails without the change, through the production entry point?
Intent source:
  concern: `requirements.md`, each acceptance criterion a test must cover.
  pr: the behavior the PR body describes, and the test conventions the repository already uses.
  plan: this milestone's work item in the plan pad, its Exit criterion and Verification lists.
Finding: location · concrete failure, or before and after · fix · severity (bug | risk | nit).
Out of mandate: the defect a missing test would catch belongs to `correctness` or `failure-modes`.
  A proof command that cannot fail belongs to `requirements-fidelity`.
  Duplicated test setup that an existing helper covers belongs to `idiom-and-reuse`.

`rules/testing-philosophy.md` sets the standard: a test calls the code the way production calls it.

## What this lens hunts for

- A new or changed behavior with no test. Name the untested path.
- A test that passes on the tree before the change, so it guards nothing.
- A test that calls an internal method with hand-built dependencies, where production resolves them
  through a container or a framework.
- An assertion on private state, or on the call order of internal collaborators.
- A test that depends on wall time or a sleep, so it fails at random.

## Examples

- `tests/Unit/SendInvoiceTest.php:15` · `(new SendInvoice($mailer))->handle($event)` builds the
  listener by hand. A missing container binding still passes. Fix: dispatch `InvoicePaid`, and
  assert `Mail::assertSent(InvoiceMail::class)`. Severity `risk`.
- `cli/main.go:55` · the change adds `--dry-run`, and no test runs the binary with it. Fix: run the
  built binary with `--dry-run`, and assert that the target file stays unchanged. Severity `risk`.

## What does not count

- "Add tests" with no untested path named.
- A coverage percentage.
- A direct call to a pure function with no integration surface. The rule allows it.
